import { expect } from "chai";
import { ethers, network, artifacts } from "hardhat";
import fs from "fs";
import { impersonateAccount, setBalance, takeSnapshot, SnapshotRestorer } from "@nomicfoundation/hardhat-network-helpers";

/**
 * ushMON issue 6 study (2026-11-16): how much the cluster's WMON vault may lend against ushMON. On a fork of live Monad
 * a desk-like operator parks shMON in a fresh ushMON v2, borrows WMON to the borrow LTV, holds for 30 hours at a chosen
 * utilization, and a liquidator checks whether the position crossed the liquidation line. A second loop moves the
 * Chainlink "SHMON / MON Exchange Rate" feed under shMonad's rate by d bps and liquidates, matures the unstake by
 * writing shMonad's epoch, redeems the seized ushMON for WMON and reports the liquidator's profit or loss and any
 * socialised debt. Every case prints one JSON line starting with "LTV|" for the study's evidence file.
 *   FORK_MONAD=true MONAD_RPC_URL=<rpc> npx hardhat test test/NeverlandMarketAdapter/ShMonadExitUshLtv.fork.test.ts
 */
const FORK_MONAD = process.env.FORK_MONAD === "true";
const USH_ART = process.env.USH_ART ?? "/Users/root1/ag-euler/contracts/eulerswap-mm-monad/out/UnstakingShMonVault.sol/UnstakingShMonVault.json";
const OUT = process.env.LTV_OUT ?? "/Users/root1/shmon-exit-desk-spec/evidence/ltv-study/ltv-simulation.jsonl";

const EVC = "0x7a9324E8f270413fa2E458f5831226d99C7477CD";
const SHMON = "0x1B68626dCa36c7fE922fD2d55E4f631d962dE19c";
const WMON = "0x3bd359C1119dA7Da1D913D1C4D2B7c461115433A";
const USD = "0x0000000000000000000000000000000000000348";
const ROUTER = "0x99f7105CAC565Ac830cf2d66527FBb06dD322C32";
const WMON_VAULT = "0xE4522663752AC47516e39aD11d3780a116850eaf";
const IRM = "0xa359026aae6c26Ba90B3D3AB78Fc483Da09DBa8a";
const GOVERNOR = "0x501107fe590c8F9b81c00b81867fD19e0d9c0253";
const FEED_PROXY = "0x2dC0b316e3d4e673C7F9A809e80a3e60b26d7774"; // SHMON / MON exchange rate, 25 h staleness
const MON_USD_FEED = "0xFB504aD06Ab5E6c63FE0A46FEa245214838E8015"; // MON / USD, 2 h staleness
const SHMONAD_EPOCH_SLOT = 18;
const E18 = 10n ** 18n;
const HOLD_H = 30;

const EVC_ABI = [
  "function enableCollateral(address account, address vault)",
  "function enableController(address account, address vault)",
  "function batch((address targetContract,address onBehalfOfAccount,uint256 value,bytes data)[] items)",
  "function getCollaterals(address) view returns (address[])",
];
const VAULT_ABI = [
  "function borrow(uint256 amount, address receiver) returns (uint256)",
  "function repay(uint256 amount, address receiver) returns (uint256)",
  "function deposit(uint256, address) returns (uint256)",
  "function touch()",
  "function debtOf(address) view returns (uint256)",
  "function cash() view returns (uint256)",
  "function totalBorrows() view returns (uint256)",
  "function interestRate() view returns (uint256)",
  "function accountLiquidity(address account, bool liquidation) view returns (uint256 collateralValue, uint256 liabilityValue)",
  "function checkLiquidation(address liquidator, address violator, address collateral) view returns (uint256 maxRepay, uint256 maxYield)",
  "function liquidate(address violator, address collateral, uint256 repayAssets, uint256 minYieldBalance)",
  "function setLTV(address,uint16,uint16,uint32)",
  "function LTVBorrow(address) view returns (uint16)",
  "function LTVLiquidation(address) view returns (uint16)",
  "function disableController()",
  "event DebtSocialized(address indexed account, uint256 assets)",
];
const ROUTER_ABI = ["function govSetResolvedVault(address,bool)", "function getQuote(uint256,address,address) view returns (uint256)"];
const IRM_ABI = ["function computeInterestRateView(address,uint256,uint256) view returns (uint256)"];
const SHMONAD_ABI = [
  "function deposit(uint256 assets, address receiver) payable returns (uint256)",
  "function convertToAssets(uint256) view returns (uint256)",
  "function getUnstakeRequests(address) view returns ((uint128 amountMon, uint64 completionEpoch)[])",
  "function balanceOf(address) view returns (uint256)",
  "function approve(address,uint256) returns (bool)",
];
const WMON_ABI = ["function deposit() payable", "function balanceOf(address) view returns (uint256)", "function approve(address,uint256) returns (bool)"];

const apyOf = (ray: bigint) => Math.exp((Number(ray) / 1e27) * 31_536_000) - 1;
const bps = (x: number) => Math.round(x * 1e6) / 100;

(FORK_MONAD ? describe : describe.skip)("ushMON LTV study: interest drift and feed moves against the liquidation line, Monad fork", function () {
  this.timeout(3_600_000);
  let base: SnapshotRestorer;
  let ush: string, ushC: any, op: any, liq: any, lender: any;
  let evc: any, wv: any, router: any, irm: any, shmonad: any, wmon: any;
  let opShares: bigint;
  const lines: string[] = [];
  const emit = (o: Record<string, unknown>) => { const s = JSON.stringify(o); lines.push(s); console.log("LTV|" + s); };

  async function signerFor(addr: string) { await impersonateAccount(addr); await setBalance(addr, ethers.parseEther("1000")); return ethers.getSigner(addr); }

  before(async () => {
    [op, liq, lender] = await ethers.getSigners();
    for (const s of [op, liq, lender]) await setBalance(s.address, ethers.parseEther("100000000"));
    evc = new ethers.Contract(EVC, EVC_ABI, ethers.provider);
    wv = new ethers.Contract(WMON_VAULT, VAULT_ABI, ethers.provider);
    router = new ethers.Contract(ROUTER, ROUTER_ABI, ethers.provider);
    irm = new ethers.Contract(IRM, IRM_ABI, ethers.provider);
    shmonad = new ethers.Contract(SHMON, SHMONAD_ABI, ethers.provider);
    wmon = new ethers.Contract(WMON, WMON_ABI, ethers.provider);
    const art = JSON.parse(fs.readFileSync(USH_ART, "utf8"));
    const v = await new ethers.ContractFactory(art.abi, art.bytecode.object ?? art.bytecode, op).deploy(EVC, SHMON, SHMON, WMON, op.address);
    await v.waitForDeployment();
    ush = await v.getAddress();
    ushC = new ethers.Contract(ush, art.abi, ethers.provider);
    const gov = await signerFor(GOVERNOR);
    await (await router.connect(gov).govSetResolvedVault(ush, true)).wait();
    await (await wv.connect(gov).setLTV(ush, 9700, 9800, 0)).wait();
    // the operator parks 300 MON of shMON
    await (await shmonad.connect(op).deposit(ethers.parseEther("300"), op.address, { value: ethers.parseEther("300") })).wait();
    const have: bigint = await shmonad.balanceOf(op.address);
    await (await shmonad.connect(op).approve(ush, ethers.MaxUint256)).wait();
    await (await ushC.connect(op).deposit(have, op.address)).wait();
    opShares = await ushC.balanceOf(op.address);
    await (await evc.connect(op).enableCollateral(op.address, ush)).wait();
    await (await evc.connect(op).enableController(op.address, WMON_VAULT)).wait();
    // the liquidator holds WMON and is ready to take debt and collateral
    await (await wmon.connect(liq).deposit({ value: ethers.parseEther("1000") })).wait();
    await (await wmon.connect(liq).approve(WMON_VAULT, ethers.MaxUint256)).wait();
    await (await wmon.connect(lender).approve(WMON_VAULT, ethers.MaxUint256)).wait();
    base = await takeSnapshot();
  });
  after(async () => { fs.writeFileSync(OUT, lines.join("\n") + "\n"); await base.restore(); });

  /** lender seeds so that after the borrow D the utilization is u */
  async function seed(D: bigint, u: number) {
    const total = (D * 10_000n) / BigInt(Math.round(u * 10_000));
    await (await wmon.connect(lender).deposit({ value: total })).wait();
    await (await wv.connect(lender).deposit(total, lender.address)).wait();
  }
  /** borrow to the borrow LTV: the adjusted collateral value in USD over the WMON price, less a hair */
  async function borrowToLtv(): Promise<bigint> {
    const [adj] = await wv.accountLiquidity(op.address, false);
    const wmonUsd: bigint = await router.getQuote(E18, WMON, USD);
    const D = (adj * E18) / wmonUsd - 10n ** 12n;
    await (await wv.connect(op).borrow(D, op.address)).wait();
    await expect(wv.connect(op).borrow(ethers.parseEther("0.001"), op.address)).to.be.reverted; // a hair more fails the LTV check
    return D;
  }
  async function health(liquidation: boolean) { const [c, l] = await wv.accountLiquidity(op.address, liquidation); return l === 0n ? Infinity : Number(c) / Number(l); }
  /** pins a Chainlink proxy to an answer that never goes stale (MockChainlinkFeed: slot 0 answer, slot 1 decimals) */
  async function pinFeed(proxy: string, answer: bigint) {
    const mock = (await artifacts.readArtifact("MockChainlinkFeed")).deployedBytecode;
    await network.provider.send("hardhat_setCode", [proxy, mock]);
    await network.provider.send("hardhat_setStorageAt", [proxy, ethers.toBeHex(0n, 32), ethers.toBeHex(answer, 32)]);
    await network.provider.send("hardhat_setStorageAt", [proxy, ethers.toBeHex(1n, 32), ethers.toBeHex(18n, 32)]);
  }
  async function liveAnswer(proxy: string): Promise<bigint> {
    return (await new ethers.Contract(proxy, ["function latestRoundData() view returns (uint80,int256,uint256,uint256,uint80)"], ethers.provider).latestRoundData())[1] as bigint;
  }
  async function matureAndWrap() {
    const reqs = await shmonad.getUnstakeRequests(ush);
    const target = reqs.reduce((m: bigint, r: any) => (BigInt(r.completionEpoch) > m ? BigInt(r.completionEpoch) : m), 0n);
    const slot = ethers.toBeHex(SHMONAD_EPOCH_SLOT, 32);
    const cur = BigInt(await ethers.provider.getStorage(SHMON, slot));
    await network.provider.send("hardhat_setStorageAt", [SHMON, slot, ethers.toBeHex((cur & ~((1n << 64n) - 1n)) | target, 32)]);
    await (await ushC.connect(liq).completeUnstake()).wait();
  }

  const PAIRS: [number, number][] = [[9800, 9700], [9700, 9600], [9600, 9500], [9500, 9300], [9300, 9000], [9000, 8700]];
  const UTILS = [0.9, 0.985];

  describe("interest drift over 30 hours", () => {
    for (const [lltv, lb] of PAIRS) for (const u of UTILS) {
      it(`LTV ${lb / 100}/${lltv / 100} at ${u * 100}% use: the loan drifts by the curve's interest and stays under the line`, async () => {
        await base.restore();
        const gov = await signerFor(GOVERNOR);
        await (await wv.connect(gov).setLTV(ush, lb, lltv, 0)).wait();
        // seed first against the projected debt, then borrow
        const [adj] = await wv.accountLiquidity(op.address, false);
        const wmonUsd: bigint = await router.getQuote(E18, WMON, USD);
        const projected = (adj * E18) / wmonUsd;
        await seed(projected, u);
        const D = await borrowToLtv();
        await (await ushC.connect(op).startUnstake(await shmonad.balanceOf(ush))).wait();
        const h0 = await health(true);
        const cash: bigint = await wv.cash(), borrows: bigint = await wv.totalBorrows();
        const curveRay: bigint = await irm.computeInterestRateView(WMON_VAULT, cash, borrows);
        // both feeds would go stale over a 30 h jump (25 h and 2 h heartbeats); pin them at their live answers, as the
        // daily and minutely updates would on the real chain
        await pinFeed(FEED_PROXY, await liveAnswer(FEED_PROXY));
        await pinFeed(MON_USD_FEED, await liveAnswer(MON_USD_FEED));
        await network.provider.send("evm_increaseTime", [HOLD_H * 3600]);
        await network.provider.send("evm_mine", []);
        await (await wv.connect(op).touch()).wait();
        const debt: bigint = await wv.debtOf(op.address);
        const drift = Number(debt) / Number(D) - 1;
        const expected = Math.pow(1 + apyOf(curveRay), HOLD_H / 8760) - 1;
        const h1 = await health(true);
        const [maxRepay] = await wv.checkLiquidation(liq.address, op.address, ush);
        const crossed = maxRepay > 0n;
        emit({ kind: "drift", lltv, lb, utilization: u, holdHours: HOLD_H, curveApy: bps(apyOf(curveRay)) / 100, driftBps: bps(drift), expectedDriftBps: bps(expected), healthBefore: h0, healthAfter: h1, crossed, debt: debt.toString() });
        expect(Math.abs(drift - expected)).to.be.lessThan(0.0001); // within 1 bp of the curve
        expect(Number(borrows) / Number(cash + borrows)).to.be.closeTo(u, 0.01);
        expect(crossed).to.equal(false);
        await expect(wv.connect(liq).liquidate(op.address, ush, ethers.MaxUint256, 0)).to.be.reverted;
      });
    }
  });

  describe("the feed moves under shMonad's rate", () => {
    const DS = [10, 50, 100, 200, 300, 500];
    for (const [lltv, lb] of [[9800, 9700], [9500, 9300]] as [number, number][]) for (const d of DS) {
      it(`LTV ${lb / 100}/${lltv / 100}, feed ${d} bps under: liquidation and the liquidator's result`, async () => {
        await base.restore();
        const gov = await signerFor(GOVERNOR);
        await (await wv.connect(gov).setLTV(ush, lb, lltv, 0)).wait();
        const [adj] = await wv.accountLiquidity(op.address, false);
        const wmonUsd: bigint = await router.getQuote(E18, WMON, USD);
        await seed((adj * E18) / wmonUsd, 0.9);
        const D = await borrowToLtv();
        await (await ushC.connect(op).startUnstake(await shmonad.balanceOf(ush))).wait();
        // the feed prints d bps under its live answer (MockChainlinkFeed: slot 0 answer, slot 1 decimals, always fresh)
        const answer = await liveAnswer(FEED_PROXY);
        await pinFeed(FEED_PROXY, (answer * BigInt(10_000 - d)) / 10_000n);
        const h = await health(true);
        const [maxRepay, maxYield] = await wv.checkLiquidation(liq.address, op.address, ush);
        const crossed = maxRepay > 0n;
        const threshold = 1 - (lb / lltv); // the d that puts health at 1, ignoring the hair
        const out: Record<string, unknown> = { kind: "feed", lltv, lb, feedUnderBps: d, health: h, crossed, thresholdBps: bps(threshold), maxRepay: maxRepay.toString(), maxYield: maxYield.toString() };
        if (!crossed) {
          expect(d / 1e4).to.be.lessThan(threshold + 0.0005);
          emit(out);
          return;
        }
        expect(d / 1e4).to.be.greaterThan(threshold - 0.0005);
        // the liquidator takes the debt and the collateral, putting in its own WMON to pass its own LTV check
        const wvI = new ethers.Interface(VAULT_ABI), evcI = new ethers.Interface(EVC_ABI);
        const own = (maxRepay * BigInt(10_000 - lb)) / 10_000n + ethers.parseEther("1");
        const wmonBefore: bigint = await wmon.balanceOf(liq.address);
        const tx = await evc.connect(liq).batch([
          { targetContract: EVC, onBehalfOfAccount: ethers.ZeroAddress, value: 0, data: evcI.encodeFunctionData("enableController", [liq.address, WMON_VAULT]) },
          { targetContract: EVC, onBehalfOfAccount: ethers.ZeroAddress, value: 0, data: evcI.encodeFunctionData("enableCollateral", [liq.address, ush]) },
          { targetContract: WMON_VAULT, onBehalfOfAccount: liq.address, value: 0, data: wvI.encodeFunctionData("liquidate", [op.address, ush, ethers.MaxUint256, 0]) },
          { targetContract: WMON_VAULT, onBehalfOfAccount: liq.address, value: 0, data: wvI.encodeFunctionData("repay", [own, liq.address]) },
        ]);
        const rc = await tx.wait();
        const socialized = rc.logs.map((l: any) => { try { return wvI.parseLog(l); } catch { return null; } }).filter((e: any) => e?.name === "DebtSocialized").reduce((a: bigint, e: any) => a + BigInt(e.args.assets), 0n);
        const seized: bigint = await ushC.balanceOf(liq.address);
        const debtTaken: bigint = await wv.debtOf(liq.address);
        // the unstake matures; the liquidator turns the seized shares into WMON and clears what it owes in one EVC
        // batch (its controller is enabled, so the exit must repay in the same batch, as the desk's settle does)
        await matureAndWrap();
        const ushI = new ethers.Interface(["function redeemForWmon(uint256,address,address) returns (uint256)"]);
        const owedNow: bigint = await wv.debtOf(liq.address);
        await (await evc.connect(liq).batch([
          { targetContract: ush, onBehalfOfAccount: liq.address, value: 0, data: ushI.encodeFunctionData("redeemForWmon", [seized, liq.address, liq.address]) },
          { targetContract: WMON_VAULT, onBehalfOfAccount: liq.address, value: 0, data: wvI.encodeFunctionData("repay", [ethers.MaxUint256, liq.address]) },
        ])).wait();
        const payable = seized; // redeemed in full above, or the batch would have reverted InsufficientWmon
        const owed: bigint = await wv.debtOf(liq.address);
        void owedNow;
        const wmonAfter: bigint = await wmon.balanceOf(liq.address);
        const pnl = wmonAfter - wmonBefore; // WMON the liquidator ends with, after taking the debt, paying its own WMON in and redeeming
        Object.assign(out, { seizedShares: seized.toString(), debtTaken: debtTaken.toString(), ownWmonIn: own.toString(), pnlWmon: pnl.toString(), pnlBpsOfDebt: bps(Number(pnl) / Number(maxRepay)), socializedWmon: socialized.toString(), operatorDebtLeft: (await wv.debtOf(op.address)).toString() });
        // bad debt is expected once the feed drop exceeds the lender's buffer, 1 − Lb/LLTV plus the discount the cap allows
        Object.assign(out, { payableCoversSeized: payable >= seized });
        // bad debt appears once the collateral at the feed's price, less the liquidator's discount, is under the debt:
        // (1 − d)(1 − discount) < Lb, with discount = 1 − LLTV(1 − d)/Lb; the line records it rather than asserting it away
        const discount = Math.max(0, 1 - (lltv / 1e4) * (1 - d / 1e4) / (lb / 1e4));
        const badDebtExpected = (1 - d / 1e4) * (1 - discount) < lb / 1e4;
        Object.assign(out, { badDebtExpected });
        emit(out);
        if (!badDebtExpected) expect(socialized).to.equal(0n);
      });
    }
  });
});
