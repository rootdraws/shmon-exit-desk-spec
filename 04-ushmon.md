# 4. ushMON, the unstaking shMON vault

Live: v4, one vault for both desks since 2026-11-18. Its source is
[`sources/ag-euler/.../UnstakingShMonVault.sol`](sources/ag-euler/contracts/eulerswap-mm-monad/src/exitmm/UnstakingShMonVault.sol),
copied from `ag-euler/contracts/eulerswap-mm-monad/src/exitmm/`, whose build every deploy script reads. The live code
matches that build byte for byte, apart from constructor values and metadata (read 2026-11-19).

The public repo [rootdraws/ushMON](https://github.com/rootdraws/ushMON) holds v4 at `b3ba1bf` (pushed 2026-11-19), v3 at
`48d07b3` (2026-11-17), v2 at `4235998` (2026-11-16) and v1 at `a7f4788`.

## What it is

An ERC-4626 vault whose shares (ushMON) are denominated in shMON. "An operator sends the vault's shMON into shMonad's
slow unstake (18 to 21 hours) and completes it; the MON that comes back is held as WMON. A holder redeems ushMON for WMON
at shMonad's redemption rate with `redeemForWmon`, inside the same Euler EVC batch that repays a WMON loan. The vault
runs the EVC account status checks that Euler's collateral vaults run, so a WMON vault can accept ushMON as collateral
and liquidate it." (`README.md`.) Root's brief, quoted in the NatSpec: "Custom vault for shMON, which does
rehypothecation into slow redemption" (2026-11-05).

Assets are counted in shMON units: shMON held + (MON pending in the unstake + WMON held) / shMonad's rate
(`totalAssets`, line 129). The operators are fixed at construction and are the exit desks. One vault serves both desks,
each on its own ledger.

## Functions (v4, live)

| Function | Who | What |
|---|---|---|
| `startUnstake(shmon)` 215 | operator | sends shMON into shMonad's unstake and writes the MON owed on the caller's ledger |
| `completeUnstake()` 232 | anyone | completes matured requests, wraps the MON into WMON, and credits it to the operators whose entries it pays, oldest first; it reserves other holders' part for them to claim |
| `claimUnstaked(holder)` 267 | anyone | moves a non-operator's matured unstakes from the reserved pot to its own credit |
| `redeemForWmon(shares, receiver, owner)` 330 | holder or approved | claims first, burns shares, pays at most `wmonRedeemable(owner)` at `rate()`, then the EVC account check |
| `deposit` / `mint` (OpenZeppelin) | receiver must be an operator | shMON in, shares out |
| `withdraw` / `redeem` 363, 368 | holder | shMON out, then the EVC account check |
| `transfer` / `transferFrom` 351, 357 | holder | moves the same share of the sender's WMON credit and pending unstakes to the receiver, then the EVC account check, so a controller can veto |
| `maxDeposit`, `maxMint` 147, 151 | view | `type(uint256).max` for an operator, 0 for anyone else |
| `maxWithdraw`, `maxRedeem` 157, 162 | view | 0 with a controller enabled, else the claim bounded by the shMON held |
| `wmonRedeemable(owner)` 174, `maxRedeemForWmon(owner)` 193 | view | the owner's own WMON credit, its claimable unstakes and its share of the shared pot; `maxRedeemForWmon` is 0 with a controller |
| `ledgerOf(holder)` 208, `wmonCredit(holder)`, `sharedWmon()` 169 | view | each holder's pending unstakes, its credited WMON, and the stray WMON every holder draws pro rata |
| `isOperator`, `operators()` 120 | view | the desks |
| `rate()` 125, `totalAssets()` 129, `pendingMon()` 202 | view | |

v2 at `4235998` had the same functions without the ledger: one operator, `redeemForWmon` paid from the whole WMON
balance, and `maxRedeemForWmon` read that balance.

## v1 to v2: the three issues

v1 was audited on 2026-11-15 (`evidence/audit-2026-11-15.md`, no author named: "No High. 1 Medium, 3 Low, 4
informational"). On 2026-11-16 Fábio Soares (FSoaresDev) filed three issues with reproductions on an anvil fork
(`evidence/issues/issue-1.md` to `issue-3.md`):

| Issue | Finding | Fix in v2 |
|---|---|---|
| [#1](https://github.com/rootdraws/ushMON/issues/1) High | Once an unstake matures, anyone can `completeUnstake`, deposit shMON and `redeemForWmon` in one transaction, taking the vault's WMON at par ahead of the desk's settle. The desk's loan then runs another day. Cheap to repeat. | Shares are minted only when the receiver is the operator (`maxDeposit`/`maxMint` return 0 otherwise). The desk's EulerSwap pool deposits with the desk as receiver and reads `maxDeposit(desk)` for its quote limit, so it keeps working. Shares stay transferable, so a liquidation still seizes them. |
| [#2](https://github.com/rootdraws/ushMON/issues/2) High | `maxWithdraw`/`maxRedeem` report the full claim while the shMON sits in the unstake or the owner has a loan, and the exit then reverts. Routers and liquidation bots that size from them hit reverts. | Both return 0 with a controller enabled (Euler's own rule, `euler-vault-kit/src/EVault/modules/Vault.sol:234-248`), else the claim bounded by the shMON actually held. `maxRedeemForWmon` added for the WMON exit. |
| [#3](https://github.com/rootdraws/ushMON/issues/3) Medium | MON that reaches the vault outside `completeUnstake` (a direct send, or shMonad paying the vault as receiver) is never counted and never moves. | `completeUnstake` wraps the vault's whole MON balance, so strays become a donation to holders. |

The audit's other findings stand as accepted: M1 a shMonad freeze strands the collateral until shMonad reopens; L2 a
chunk above shMonad's no-delay allowance waits two more epochs (the bot should split it); L3 a liquidator receives a
share that pays out a day later.

## Eight more issues, worked through with Root on 2026-11-16

Filed by ardey26 on 2026-11-16 at 17:58Z (`evidence/issues/issue-4.md` to `issue-11.md`). Each was taken one at a time
with Root; the calls below are his.

| Issue | Finding | Call |
|---|---|---|
| [#4](https://github.com/rootdraws/ushMON/issues/4) Medium | No tests in the repo, and the fork stand-in behaves differently from live shMonad | Fixed in v2: the stand-in is deleted, the unit tests use a mock that burns shMON as shMonad does and refuses when nothing is matured, the constructor's approval to the unstaker is gone, and a fork test runs the cycle against live shMonad |
| [#5](https://github.com/rootdraws/ushMON/issues/5) Low | The operator is a single immutable address with no rotation | Closed by design: the operator is the exit desk, an upgradeable contract under the admin Safe whose own keys rotate; a changeable operator would reopen the door issue 1 closed |
| [#6](https://github.com/rootdraws/ushMON/issues/6) Medium | A 98% liquidation LTV leaves about 2% for an exit that takes a day or more | Studied in [11-ltv-study.md](11-ltv-study.md); the new vaults deploy at 93/95 ("move to 93/95 now. It's built for external lenders.") |
| [#7](https://github.com/rootdraws/ushMON/issues/7) Low | A 1-wei withdrawal makes an exact-balance `startUnstake` revert | Fixed in v2: `startUnstake` sends what is held, up to the amount asked, and is a no-op with nothing to send |
| [#8](https://github.com/rootdraws/ushMON/issues/8) Low | `completeUnstake` reverts when nothing is matured, so a settle batch can be griefed | Fixed in v2: shMonad's refusal is swallowed and the call returns what it wrapped; the desk's settle already guarded its own call since v1.6.0 |
| [#9](https://github.com/rootdraws/ushMON/issues/9) Low | Assets in the unstake earn nothing, and every holder shares that cost | Closed by purpose: ushMON is the desk's collateral wrapper with one holder, so the day of lost yield is the exit's own cost; the audit's L3 covers a liquidator's day |
| [#10](https://github.com/rootdraws/ushMON/issues/10) Low | `totalAssets` reads raw balances, so a transfer to the vault moves the share price | Closed after 189 test cases (`evidence/donation-tests.txt`, `evidence/UnstakingShMonVault.donation.t.sol`): a gift is counted once, mints nothing, never lowers the price, goes to the holders pro rata, and costs a later deposit at most one share's worth of rounding (gift / 1e6) |
| [#11](https://github.com/rootdraws/ushMON/issues/11) Low | `redeemForWmon` emits no Withdraw event (the audit's I3) | Fixed in v2: `RedeemedForWmon(caller, receiver, owner, shares, wmon)`; wiring it into the Telegram announcements is item 12 of `alphastructures/audit/todo-before-launch.md` |

## Tests (v2, `test/UnstakingShMonVault.t.sol`, output in `evidence/forge-test.txt`; v3 in `evidence/forge-test-v3.txt`; v4 in `evidence/forge-test-v4.txt`)

Seventeen tests in three files (output in `evidence/forge-test.txt`): twelve unit tests against a mock shMON that burns
and refuses as live shMonad does, a mock WMON, the real Ethereum Vault Connector from `lib/` and a mock controller;
two fork tests against live shMonad; three donation tests (a 60-case grid and two fuzz runs). The unit cases: non-operator deposit and mint revert; a pool-style deposit
from another caller with the operator as receiver succeeds; the three-call attack of issue 1 stops at the deposit; the
max views are 0 while shMON is in the unstake and equal the claim when held; the max views are 0 with a controller;
`redeemForWmon(maxRedeemForWmon)` pays and five shares more reverts, at three rates; stray MON is wrapped and counted;
the full cycle deposit, unstake, wait, complete, redeem for WMON; `startUnstake` by a non-operator reverts; an exact
request after a wei left still goes through (issue 7); a completion with nothing matured is a no-op (issue 8); the
redemption event fires (issue 11). All pass.

```sh
git clone --recurse-submodules https://github.com/rootdraws/ushMON && cd ushMON && forge test -vv
```

The fork cycle test that drives v2 through the live desk, the pool and a matured unstake is in
[08-testing.md](08-testing.md).

## v2 to v3: one vault for both desks (2026-11-17)

Root, 2026-11-17: "it looks suspicious enough having ushMON as collateral, But ushMONdo and ushMONdn Seems like a bit
excessive." v3 lets several exit desks share one vault without sharing each other's money:

- The constructor takes a list of operators (`isOperator`, `operators()`); only an operator receives shares or starts an
  unstake, as in v2.
- `startUnstake` writes the MON shMonad now owes for the request on the caller's ledger (`ledgerOf(operator)`, oldest
  first). `completeUnstake` wraps every wei of MON as before, then credits the WMON to the operators whose matured ledger
  entries it pays (`wmonCredit(operator)`), oldest first; what is left (issue 3's stray MON, WMON sent straight in) is
  a shared pot every holder draws pro rata (`sharedWmon()`).
- `redeemForWmon(shares, receiver, owner)` pays at most `wmonRedeemable(owner)`: the owner's own credit plus its share of
  the pot. `maxRedeemForWmon` reports the same bound (0 with a controller, as v2). A liquidator who seizes shares has no
  credit of its own, so it leaves through `redeem` for shMON the vault holds, or its share of the pot.
- Shares stay one pot priced pro rata, so a desk holding shMON earns a little of the yield the other desk's unstaking
  MON does not (about 3 bps a day on the unstaking part at today's rate); stated in the README.

The other way, one desk serving both vaults, would have split every controller-bound path in the desk per vault; this
way is a vault ledger plus one read in the desk's settle ([03-exit-desk.md](03-exit-desk.md)). Tests: four two-desk cases
in `test/UnstakingShMonVault.t.sol` (A unstakes and only A can redeem the WMON; credits follow each ledger; stray MON and
WMON are shared pro rata with a liquidator; an outsider is still shut out), the donation grid and the fork tests all
pass on v3 (21 tests), and the desk-side fork test runs both live desks on one vault ([08-testing.md](08-testing.md)).

## v3 to v4: the WMON follows the shares (2026-11-18)

Root, 2026-11-18: "yes, build the ushMON fix". In v3 a liquidator that seized a desk's shares got none of the WMON
behind them, because that WMON was credited to the desk alone. v4 fixes this:

- A transfer moves the same share of the sender's WMON credit and of each pending unstake to the receiver.
- When those unstakes mature, `completeUnstake` reserves their WMON in a pot, and each holder claims its own part.
- Claims run one holder at a time, so many small holders cannot make `completeUnstake` too costly for the desks.

Tests: seven v4 cases in `evidence/UnstakingShMonVaultV4.t.sol` pass (`evidence/forge-test-v4.txt`, rerun 2026-11-19). A
seizer redeems the WMON behind its shares, a second transfer carries the claim on, and one desk still cannot take the
other's WMON.

## Deployed vaults

| ushMON | Cluster | Operator (exit desk) | Version | Note |
|---|---|---|---|---|
| [0xa753E24B0986567EDAd75f784664Ec11336f8C5e](https://monadscan.com/address/0xa753E24B0986567EDAd75f784664Ec11336f8C5e) | second (live) | 0x02Df…c770 (usdc-hl) and 0xF460…6CdE (usdc-hl-d0), both operators | v4 | both desks' collateral since 2026-11-18; 48.38 shMON parked as headroom by each; WMON vault lends 93/95 against it (read 2026-11-19); `USHMON_USDC4` in `deployed-143.env` |
| [0x37e07473F1F62CB071Db57440e242b320614A0ce](https://monadscan.com/address/0x37e07473F1F62CB071Db57440e242b320614A0ce) | second (live) | 0x02Df…c770 (usdc-hl) and 0xF460…6CdE (usdc-hl-d0), both operators | v3 | both desks' collateral 2026-11-17 to 2026-11-18; empty, retired from the cluster 2026-11-18 (WMON vault LTV 0, read 2026-11-19); `USHMON_USDC` in `deployed-143.env` |
| [0xC8f5023512c0618B754e03d675E3626a4A760092](https://monadscan.com/address/0xC8f5023512c0618B754e03d675E3626a4A760092) | second (live) | 0x02Df…c770 (usdc-hl) | v2 | the desk's collateral 2026-11-16 to 2026-11-17; emptied by `unparkShmon`; retired from the cluster 2026-11-17 (WMON vault LTV 0, unresolved on the router, read 2026-11-18); `V2_USHMON_USDC_HL` in `deployed-143.env` |
| [0xa2F34235e4C3c0706B2d5B9170F924446b1Df664](https://monadscan.com/address/0xa2F34235e4C3c0706B2d5B9170F924446b1Df664) | second (live) | 0xF460…6CdE (usdc-hl-d0) | v2 | the desk's collateral 2026-11-16 to 2026-11-17; emptied by `unparkShmon`; retired from the cluster 2026-11-17 (WMON vault LTV 0, unresolved on the router, read 2026-11-18); `V2_USHMON_USDC_HL_D0` in `deployed-143.env` |
| [0xa44220Ee57Cb879bd842a24696Df06e398601d8F](https://monadscan.com/address/0xa44220Ee57Cb879bd842a24696Df06e398601d8F) | second (live) | 0x02Df…c770 (usdc-hl) | v1 | replaced 2026-11-16, empty; retired from the cluster 2026-11-17 (WMON vault LTV 0, unresolved on the router, read 2026-11-18); `V1_USHMON_USDC_HL` in `deployed-143.env` |
| [0x066E1eb375369A00e324cF18Eb014B9AB0507690](https://monadscan.com/address/0x066E1eb375369A00e324cF18Eb014B9AB0507690) | second (live) | 0xF460…6CdE (usdc-hl-d0) | v1 | replaced 2026-11-16, empty; retired from the cluster 2026-11-17 (WMON vault LTV 0, unresolved on the router, read 2026-11-18); `V1_USHMON_USDC_HL_D0` in `deployed-143.env` |
| 0x8DB5BAA62968F8Ff971889F07C52e6BD7835Ad16, 0xE5c2612F36dC773D7d85D034F9c8E9171cE2Ef73 | second | the retired usdt0 desks (0x5fa6…3d7c, 0xfd12…86f0) | v1 | unused; recorded in the retired configs and the working-tree cluster env |
| 0x10f5ef37b3b2d3A90CB8AAADB2605CdC0C81f911 | first (handed to the AlphaGrowth Safe 2026-11-09, rejected) | usdc-hl desk | v1 | wired by desk v1.5.0 on 2026-11-09, then left behind when the desk's account moved to the second cluster's vault |
| 0x59f7f897322D5FdEFCa38beB78137559eD985F80, 0xc0CA1086131046766956bBD030fe9595Cc8204a1 | the older setup on AlphaGrowth's eWMON-14 (0xfE26…e702), 2026-11-06 | usdc-hl, usdt0-hl desks | v1 | listed in the ushMON README; the usdc-hl desk's pool on this pair (0x9aF1…e8a8) was retired with desk v1.5.0; the usdt0-hl desk and its pool (0xeC6b…68A8) were retired with the usdt0 strategy |

Operators are from the production and retired configs (`params.unstakeVault`), `docs/shmon-exit-desk-plan.md:186-204`
and the live EVC collateral reads (`evidence/live-reads.md`). The ushMON README lists v4 as the live vault. A vault is approved on the cluster by two governor calls: the router resolves it to shMON
(`govSetResolvedVault`) and the WMON vault lends 93% against it with a 95% liquidation threshold (`setLTV`), both in
`ag-euler/contracts/shmon-cluster-monad/deploy.sh` (`desks`, which since v3 takes `DESKS="usdc=0xdesk+0xdesk"` and
passes the list to the constructor).
