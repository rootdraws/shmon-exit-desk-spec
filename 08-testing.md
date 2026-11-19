# 8. Testing

Every result here has its log under `evidence/` and a command to rerun it. The newest tests come first.

## 1. ushMON unit tests (`evidence/forge-test-v4-all.txt`, 2026-11-19)

The ushMON repo at `b3ba1bf` (v4): **28 passed, 0 failed**.

- **The seven v4 tests** (`test/UnstakingShMonVaultV4.t.sol`):
  - The WMON follows the shares, and a second transfer carries it on.
  - A credit already earned moves with the shares.
  - The holders' pot is reserved for holders and is not shared.
  - Many dust holders do not slow `completeUnstake`.
  - One desk still cannot take the other desk's WMON.
  - Only operators get new shares and start unstakes.
  - A liquidator redeems the WMON behind the shares it seized.
- **The earlier tests**, all still passing:
  - 16 unit tests in `test/UnstakingShMonVault.t.sol`.
  - 3 donation tests.
  - 2 fork tests on live shMonad.

The v2 run (17 passed) is in `evidence/forge-test.txt`, and the v3 run (21 passed) is in `evidence/forge-test-v3.txt`.
The cases are listed in [04-ushmon.md](04-ushmon.md).

```sh
cd ushMON && MONAD_RPC_URL=<rpc> forge test
```

## 2. Emergency sale fork test (`evidence/hardhat-fork-panic.txt`, 2026-11-19)

`alphastructures/contracts/test/NeverlandMarketAdapter/ShMonadExitPanic.fork.test.ts` forks Monad at block 123,554,000.
The admin Safe upgrades the live Delta One controller to 1.15.0 and its desk to 1.10.0, then pauses the vault.
**8 passing**:

1. Both contracts upgrade to the new versions.
2. While paused, margin reaches the desk, and the desk parks, unstakes, borrows, sells MON and places orders.
3. While paused, `buyMonV4` and `sellShmonV4` stay blocked, and other venues get no margin.
4. A full halt stops every one of them.
5. `sellMonV4` fills 1.9% under the oracle only while the loan is at or over 65%, and refuses 2.1% under.
6. Borrow-to-fill runs in one controller call while paused, and the USDC comes home.
7. Borrow-to-fill sends its WMON to the controller, which sells it into Uniswap v3 0.3% in the same call.
8. Borrow-to-fill is refused under the floor, runs only for the controller, and stops at a full halt.

The test borrows from the cluster's WMON vault, so it runs at block 123,554,000. At block 123,554,268 the Delta Neutral
pool borrowed the vault's whole 929.8 WMON float to pay a shMON seller.

```sh
cd alphastructures/contracts && FORK_MONAD=true MONAD_RPC_URL=<rpc> MONAD_FORK_BLOCK=123554000 \
  npx hardhat test test/NeverlandMarketAdapter/ShMonadExitPanic.fork.test.ts
```

## 3. Emergency sale bot tests (`evidence/bot-emergency-sale-tests.txt`, 2026-11-19)

`services/rebalancingBot/test/planner/marketSell.test.ts` and `test/panicFills.test.ts`: **29 passed, 0 failed**.

- **The short's money:** at 67% the bot trims the short, brings the margin home and repays first.
- **The 65% and 55% lines:** market sales start at 65.0% and stop at 55.0%.
- **WMON first:** leftover WMON sells before any new shMON turns into WMON.
- **Resting orders:** at 66% the desk cancels them, taker-sells the sell orders' WMON and repays with the buy order's USDC.
- **Borrow-to-fill:** the v4 pool first, then several Uniswap v3 rounds, all in one transaction.
- **The 2% limit:** a WMON sale fills at 1.9% and is refused at 2.1%.
- **The 1.5% limits:** the instant redemption and Curve are used at 1.4% and skipped at 1.6%.
- **Refusals:** a slice too small to lower the loan is refused, and so is a repay that would land on the stable desk.
- **No half-close:** with nothing to sell, the bot stops after the short's money.

```sh
cd alphastructures/services/rebalancingBot && npx tsx --test test/planner/marketSell.test.ts test/panicFills.test.ts
```

## 4. The five-stage fork harness (`evidence/harness/`)

`alphastructures/services/rebalancingBot/test/sim/multi/final.ts` forks live Monad with the real bot, oracle, monitor
and keeper. It runs one vault on both lenders, with the stable desk and the exit desk (`final.ts:1-12`):

0. The exit desk gets its Euler account on a fresh ushMON.
1. Growth: a $300k deposit buys MON only through the desk's resting buys.
2. Neverland USDC goes past its kink, and the stable desk moves debt to USDT0.
3. MON and shMON fall 35%, and neither lender may liquidate.
4. Wind-down: half the shares redeem, and the bot serves the batch.

No market swap may run in any stage. A fork cannot mature shMonad's unstake, so a stage 4 that waits on it ends
"FINAL WAITS ON UNSTAKE" (`docs/testbook.md:178-182`). The matured unstake is covered by section 6 and by
`services/rebalancingBot/test/exitDeskEuler.test.ts`.

| Run | Base | Build | Result |
|---|---|---|---|
| ushv4b-d0, 2026-11-18 22:16Z to 23:00Z | delta neutral | ushMON v4 | **FINAL PASSED**, no FAIL |
| ushv4-d0, 2026-11-18 19:18Z to 19:56Z | delta neutral | ushMON v4 | FINAL FAILED: one stable desk debt move reverted; rerun as ushv4b-d0 |
| ush4-hl, 2026-11-18 19:09Z to 22:15Z | delta one | ushMON v4 | **FINAL PASSED**, no FAIL |
| ush5-hl, 2026-11-17 | delta one | ushMON v3, desk v1.8.0 | **FINAL PASSED**, no FAIL |
| ush5-d0, 2026-11-17 | delta neutral | ushMON v3, desk v1.8.0 | **FINAL PASSED**, no FAIL |
| wd-254, 2026-11-16 | delta one | ushMON v2, desk v1.7.0 | stages 2 to 4 passed, FINAL WAITS ON UNSTAKE |
| wd-253, 2026-11-16 | delta neutral | ushMON v2, desk v1.7.0 | stages 2 and 3 passed; stage 4 repaid the loan, then waited on the unstake |
| ush4-d0, ush3-hl, 2026-11-16 | both | ushMON v2 | stopped at stage 2 on Neverland's WMON supply cap; `final.ts` now lifts it |
| ush2-d0, ush2-hl2, 2026-11-16 | both | ushMON v2 | **FINAL PASSED** (ush2-hl2 finished as wd-251) |
| final-live-10, final-live-11, 2026-11-15 | both | ushMON v1 | delta neutral passed; delta one waited on the unstake |

```sh
cd alphastructures/services/rebalancingBot/test/sim/multi/harness
./launch-try.sh fresh-try.sh RUN=<name> PORT=<port> BASE=shmon-desk-hl      # delta one
./launch-try.sh fresh-try.sh RUN=<name> PORT=<port> BASE=shmon-desk-hl-d0   # delta neutral
```

## 5. Desk fork tests (`evidence/hardhat-fork-desk-2026-11-19.txt`, 2026-11-19)

Each test in `alphastructures/contracts/test/NeverlandMarketAdapter/` passed on 2026-11-19.

- **At block 123,554,000** (today's chain):
  - `ShMonadExit.fork.test.ts`: 7 passing. It covers unstake and v3 orders, oracle refusals and roles.
  - `ShMonadExitV11.fork.test.ts`: 14 passing. It covers v4, Hanji and digester orders.
  - `ShMonadExitV111.fork.test.ts`: 4 passing. It covers one listing per tick.
  - `ShMonadExitUsh3.fork.test.ts`: 5 passing. It covers both desks on one v3 vault.
- **At block 123,378,188** (2026-11-18 19:09Z, before the v4 move):
  - `ShMonadExitV15.fork.test.ts`: 5 passing. It covers the account move, then park, borrow and repay.
  - `ShMonadExitSettle.fork.test.ts`: 5 passing. It covers the settle fixes H2, H3, H10 and M10.
  - `ShMonadExitUsh2.fork.test.ts`: 10 passing. It covers the public buyer and a matured unstake.

These three expect the v3 vault, so they fail at today's block.

```sh
cd alphastructures/contracts && FORK_MONAD=true MONAD_RPC_URL=<rpc> MONAD_FORK_BLOCK=<block> \
  npx hardhat test test/NeverlandMarketAdapter/<file>
```

## 6. Fork cycle tests of v2 and v3 (`evidence/hardhat-fork-ush2.txt`, `evidence/hardhat-fork-ush3.txt`)

**v2, 2026-11-16: 10 passing.**

- The governor approves a v2 vault for the usdc-hl desk, and the admin Safe upgrades the desk to v1.7.0.
- The desk parks 15 MON of shMON as headroom. Without it the first sale reverted `E_AccountLiquidity`.
- An outsider sells 300 MON of shMON into the pool at the rate less 0.30%, and the desk's WMON debt rises by that.
- An outsider cannot mint shares, which closes issue 1.
- The unstake matures (shMonad's epoch is written to storage slot 18), and the settle repays the whole loan.
- While a leaver waits, the fee hook returns 1e18 and the pool quotes nothing.

**v3, 2026-11-17: 5 passing.**

- One v3 vault serves both desks, and each desk borrows only for its own pool's buy.
- Desk A's unstake is on A's ledger alone, and A's settle repays A's loan.
- The desk must read `wmonRedeemable`, because `maxRedeemForWmon` is 0 under a controller.

## 7. Release rehearsals on anvil forks

- **v2, 2026-11-16** (`evidence/rehearsal-fork-final.log`): `deploy.sh desks` and `custody/release-ush2-143.ts` read
  back OK. A 121 shMON sale filled 0.30% under the rate once given a 1.5M gas limit.
- **v3, 2026-11-17** (`evidence/release-ush3/rehearsal-ush3.log`): `custody/release-ush3-143.ts` ran eight steps
  `ok` and two read-backs `OK`.

```sh
anvil --fork-url <rpc> --port 8700 --chain-id 143
cd alphastructures && RPC=http://127.0.0.1:8700 FORK=1 npx tsx custody/release-ush3-143.ts
```

## 8. The LTV simulation (`evidence/ltv-study/`)

`ShMonadExitUshLtv.fork.test.ts` runs 24 cases on a Monad fork: **24 passing**.

- Twelve 30-hour holds at six LTV pairs: interest matches the curve within 1 bp, and nothing becomes liquidatable.
- Twelve feed drops with a real liquidation, maturity and redemption.

The results are in [11-ltv-study.md](11-ltv-study.md).

## 9. The audit (`evidence/audit-2026-11-15.md`)

The audit of 2026-11-15 covered ushMON v1: "No High. 1 Medium, 3 Low, 4 informational."

- Fábio Soares filed three issues on 2026-11-16 that raise L1 and I2 to High and I1 to Medium. v2 fixed them.
- ardey26 filed eight more the same day (issues 4 to 11). They are listed in [04-ushmon.md](04-ushmon.md).

## 10. The mainnet releases

- **v2, 2026-11-16** (`evidence/release-mainnet/`): two v2 vaults, desk v1.7.0, two pools, 929.88 WMON lent as the
  float.
- **v3, 2026-11-17** (`evidence/release-ush3/`): one v3 vault for both desks (`0x37e07473F1F62CB071Db57440e242b320614A0ce`)
  and desk v1.8.0.
- **v4, 2026-11-18** (`custody/deployments/release-ush4-143.json`):
  - `deploy.sh desks` created the v4 vault, `0xa753E24B0986567EDAd75f784664Ec11336f8C5e`.
  - `custody/release-ush4-143.ts` upgraded both desks to v1.9.0 (`0x959FA2e2ab953B1C2cCE71c036Aafbf584409c16`).
  - It moved both desks onto v4 and opened the Delta One pool (`0x56aEAB6F7a33573CdEF9B59a8d330F0e1b2128A8`) and the
    Delta Neutral pool (`0x19241Ff986e1dFE848A8C2a8AC2C21C0E7cFe8a8`).
- **Emergency sale, 2026-11-19** (`custody/deployments/release-panic-143.json`):
  - The admin Safe upgraded both controllers to 1.15.0 (`0x77799C4BEE051d22a75Db768364DEBC24df9297E`).
  - It upgraded both desks to 1.10.0 (`0x74eCd223208D812098487D4090d964005370BDc7`).
  - At block 123,611,133 both controllers read `VERSION` 11500 and both desks read 11000.
