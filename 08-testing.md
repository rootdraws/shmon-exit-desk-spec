# 8. Testing

Every result here has its log under `evidence/` and a command to rerun it. Dates are 2026-11-16 unless stated; the
one-vault (v3) results of 2026-11-17 are in sections 1, 2a, 3a, 4 and 9.

## 1. ushMON unit tests (`evidence/forge-test.txt` for v2; v3 run on 2026-11-17)

On v2, twelve Foundry unit tests in `ushMON/test/UnstakingShMonVault.t.sol` against mocks and the real Ethereum Vault
Connector, plus three donation tests and two fork tests: **17 passed, 0 failed** (`evidence/forge-test.txt`); the cases
are listed in [04-ushmon.md](04-ushmon.md). On v3 (`48d07b3`, 2026-11-17, rerun 2026-11-18 in `evidence/forge-test-v3.txt`) the
suite is 16 unit tests (the ten, the two of issues 7 and 8, and four two-desk cases: only the unstaking desk redeems its
WMON; credits follow each desk's ledger; stray MON and WMON are shared pro rata, a liquidator included; an outsider is
still shut out), the three donation tests and the two live-shMonad fork tests: **21 passed, 0 failed**.

```sh
cd ushMON && forge test --match-path test/UnstakingShMonVault.t.sol -vv
```

## 2. Fork cycle test: v2 vault, live desk, public buyer, matured unstake (`evidence/hardhat-fork-ush2.txt`)

`alphastructures/contracts/test/NeverlandMarketAdapter/ShMonadExitUsh2.fork.test.ts` on a Hardhat fork of live Monad at
its head, impersonating the cluster governor and the admin Safe. Ten steps, **10 passing** (rerun after the desk's
v1.7.0 priority rule was added):

1. The governor approves a v2 vault for the live usdc-hl desk on the cluster (router resolves it, WMON vault lends 97/98).
1a. The admin Safe upgrades the desk to this tree's v1.7.0 implementation.
2. The admin Safe moves the desk's account onto it and opens the EulerSwap pool; the fee hook quotes under 1e18 for
   shMON in and refuses WMON in.
3. A lender seeds the WMON vault with 390 WMON.
4. The desk parks 15 MON of shMON as headroom (without it the first sale reverted `E_AccountLiquidity`: the pool pays
   99.7% of value against collateral lent at 97%).
5. An outsider sells 300 MON of shMON into the pool for WMON at the rate less 0.30%; the shMON lands in ushMON for the
   desk and the desk's WMON debt rises by the amount paid; `maxRedeem(desk)` reads 0 while indebted.
6. The issue-1 attack stops at the deposit: an outsider cannot mint shares.
7. The desk unstakes the bought shMON with `parkShmon(0, sold)`, leaving the headroom parked.
8. shMonad's epoch is moved on (storage slot 18, low 64 bits, the audit's method, since a fork cannot crank);
   `settleEulerUnstake` repays the whole loan from the WMON that came back; `restakeWmon` sends the 0.3% surplus home as
   shMON.
9. Priority: a depositor joins the live vault (reopened by the admin, since it sealed itself when its last holder
   left) and asks to leave. With that batch unpaid the desk reads `leaversWaiting() == true`, the fee hook returns
   1e18 and the pool's quote reverts. Once the handler's last-processed id catches up, the pool quotes again.

```sh
cd alphastructures/contracts && FORK_MONAD=true MONAD_RPC_URL=<rpc> \
  npx hardhat test test/NeverlandMarketAdapter/ShMonadExitUsh2.fork.test.ts
```

## 2a. Fork test of v3: both live desks on one vault (`evidence/hardhat-fork-ush3.txt`, 2026-11-17)

`alphastructures/contracts/test/NeverlandMarketAdapter/ShMonadExitUsh3.fork.test.ts` on a Hardhat fork of live Monad at
head. Five steps, **5 passing**: the governor approves one v3 vault with both desks as operators (router, 93/95); the
admin Safe upgrades both desks to v1.8.0, brings each desk's 48.38 shMON headroom home with `unparkShmon` (the first
run showed the vault refuses a redeem while a controller is enabled, so the desk steps out from under the WMON vault for
it), moves both accounts onto the one vault and opens a pool per desk; outsiders sell into both pools and each desk
borrows only for its own pool's buy; desk A unstakes its buy and the ledger is A's alone; the unstake matures (shMonad's
epoch written), B's settle takes nothing (its loan only grew by interest; the first run asserted equality and was
corrected) and A's settle repays A's loan and restakes the surplus. The first run of the settle step also showed the
desk must read `wmonRedeemable`, not `maxRedeemForWmon`, which is 0 under a controller.

```sh
cd alphastructures/contracts && FORK_MONAD=true MONAD_RPC_URL=<rpc> npx hardhat test test/NeverlandMarketAdapter/ShMonadExitUsh3.fork.test.ts
```

## 3. Release rehearsal on an anvil fork (`evidence/rehearsal-fork-final.log`, on the final vault build with issues 7, 8 and 11; earlier runs in `rehearsal-fork-9395.log` and `rehearsal-fork.log`)

The exact mainnet release path on a fresh fork of Monad at head (final run at 93/95 with the v1.7.0 desk and the 80 MON
headroom, 2026-11-16 22:45Z): `deploy.sh desks` deploys two v2 vaults and sets the router and WMON-vault settings (`govSetResolvedVault … OK`, `setLTV 9700 9800: OK` per vault; the first rehearsal's
`verify` step in `evidence/rehearsal-fork-first.log` reads `ok` for both), then `custody/release-ush2-143.ts` moves both desks' accounts, opens
both pools, parks 15 MON of headroom per desk, and lends 360 WMON into the WMON vault. Every step ran and read back OK. A
seller's sale into the pool simulated correctly (`cast call --trace`, 0.30% under the rate, the desk's account check
passing); an earlier run's sale sent through `cast send` with anvil's gas estimate returned `status 0 (failed)`; in the final
run the same sale with an explicit gas limit of 1.5M succeeded: 121 shMON (199.98 MON of value) sold for 199.38 WMON,
0.30% under, the desk's debt equal to the WMON paid, the shMON in the vault for the desk.

```sh
anvil --fork-url <rpc> --port 8700 --chain-id 143
cd ag-euler/contracts/shmon-cluster-monad && RPC=http://127.0.0.1:8700 DESKS="usdc-hl=0x02Df…,usdc-hl-d0=0xF460…" zsh deploy.sh desks
cd alphastructures && RPC=http://127.0.0.1:8700 FORK=1 CLUSTER_ENV=…/deployed-143-fork.env npx tsx custody/release-ush2-143.ts
```

## 3a. Rehearsal of the one-vault release (`evidence/release-ush3/rehearsal-ush3.log`, 2026-11-17)

Twice on a fresh anvil fork of Monad at head, the second on the final desk build: `deploy.sh desks` with
`DESKS="usdc=0x02Df…+0xF460…"` deploys one v3 vault with both desks as operators (`govSetResolvedVault … OK`,
`setLTV 9300 9500: OK`, `verify: all OK`), then `custody/release-ush3-143.ts` deploys desk v1.8.0, upgrades both desks,
takes each desk's 48.38 shMON out of its v2 vault, moves both accounts onto the v3 vault, opens a pool per desk (read-back
`OK`, fee 2.2549% under the ceiling, WMON in refused) and parks the headroom again. Eight steps `ok`, two read-backs `OK`.

## 4. The five-stage fork harness (`evidence/harness/`)

`alphastructures/services/rebalancingBot/test/sim/multi/final.ts`, run by `harness/fresh-try.sh` under launchd: a fork
of live Monad at head with the real bot, oracle, monitor and keeper, one vault on both lenders, the stable desk and the
exit desk. The stages (`final.ts:1-12`):

0. The exit desk gets its Euler account: a fresh ushMON on the cluster, operated by the desk.
1. Growth: a $300k deposit; borrowed USDC buys MON only through the desk's resting buys, filled by the keeper.
2. Neverland USDC goes past its kink and the stable desk moves debt to USDT0.
3. MON and shMON fall 35% with the bot running: no lender may liquidate, each comes back under its unwind line.
4. Wind-down: half the shares redeem; the bot raises the loan share through the desk's chunked route and serves the batch.

Through all of it no market swap may run. shMonad's unstake cannot mature on a fork, so a stage 4 in which the desk
parks shMON into the unstake to fund the batch ends waiting for MON the fork never pays: "FINAL WAITS ON UNSTAKE" on the
delta-one base (`evidence/harness/final-live-11/scenario.log:261`; the reason is in `docs/testbook.md:178-182`), and
in wd-253 the batch check timed out after 101 minutes for the same reason. The one-day leg is covered by test 2 above
and by the planner tests of `settleEulerUnstake` and `restakeWmon` (`services/rebalancingBot/test/exitDeskEuler.test.ts`).

| Run | Base | Vault build | Result |
|---|---|---|---|
| final-live-10, 2026-11-15 | delta neutral | v1 | FINAL PASSED (batch served, debt 100,883 to 3,108) |
| final-live-11, 2026-11-15 | delta one | v1 | 32 PASS checks, no FAIL, stage 4 FINAL WAITS ON UNSTAKE; stage 2 logged a TIMEOUT on the debt move, as final-live-10 and ush2-d0 also did |
| ush2-hl, 2026-11-16 18:19Z | delta one | v2 + planner change | FAIL at stage 0: the upstream RPC timed out ("failsafe timeout policy exceeded"); relaunched |
| ush2-d0, 2026-11-16 18:13Z to 19:22Z | delta neutral | v2 + planner change | **FINAL PASSED**, 29 PASS checks, no FAIL; one TIMEOUT line in stage 2 (debt move) and one in stage 4 (desk sells after the payout) |
| ush2-hl2, 2026-11-16 18:32Z | delta one | v2 + planner change | stages 0 to 2 passed; stages 3 and 4 rerun as wd-251 from its saved point: **FINAL PASSED** |
| ush4-d0, 2026-11-16 21:36Z | delta neutral | final tree (v2, v1.7.0 desk, planner change) | stages 0 and 1 passed; stopped at the start of stage 2 on a revert from Neverland's pool: its WMON supply cap (100M) was hit by the stage's deposit (Aave error 51). `final.ts` now lifts the cap on the fork. |
| ush3-hl, 2026-11-16 21:32Z | delta one | final tree | stages 0 and 1 passed; the same stage-2 revert as ush4-d0 |
| wd-253, 2026-11-16 23:00Z to 2026-11-17 01:09Z | delta neutral | final tree | resumed from ush4-d0's saved point: stages 2 and 3 passed; stage 4 served the loan (debt 100,893 to 0) and parked 3.23M shMON into shMonad's unstake, which the fork cannot mature, so "the withdrawal batch was served" timed out after 101 minutes. No bot transaction reverted. |
| wd-254, 2026-11-16 23:04Z to 2026-11-17 00:02Z | delta one | final tree | resumed from ush3-hl's saved point: stages 2 to 4 passed, FINAL WAITS ON UNSTAKE |
| ush5-d0, 2026-11-17 15:56Z to 16:39Z | delta neutral | one-vault tree (v3 vault, v1.8.0 desk, shared reader) | **FINAL PASSED**, no FAIL; the usual TIMEOUT line on the stage-2 debt move |
| ush5-hl, 2026-11-17 15:47Z to 18:37Z | delta one | one-vault tree | **FINAL PASSED**, no FAIL: the wind-down served the batch in full (`evidence/harness/ush5-hl/`) |

```sh
cd alphastructures/services/rebalancingBot/test/sim/multi/harness
./launch-try.sh fresh-try.sh RUN=<name> PORT=<port> BASE=shmon-desk-hl      # delta one
./launch-try.sh fresh-try.sh RUN=<name> PORT=<port> BASE=shmon-desk-hl-d0   # delta neutral
```

## 5. Earlier fork tests of the desk (`alphastructures/contracts/test/NeverlandMarketAdapter/`)

These were written against the live state of their day and are not all runnable today: `ShMonadExitSettle.fork.test.ts`
fails 5 of 5 on the untouched tree (it upgrades the live desk to v1.6.0, which is already live) and 4 of 5 with the
v1.7.0 tree (the cluster's WMON vault has no cash to borrow, `E_InsufficientCash`); both runs on 2026-11-16, the
stash-and-rerun proof that the change is not the cause.

`ShMonadExit.fork.test.ts` (unstake and v3 orders, oracle refusals, roles), `ShMonadExitV11.fork.test.ts` (v4, Hanji,
digester orders), `ShMonadExitV111.fork.test.ts` (one listing per tick), `ShMonadExitV15.fork.test.ts` (the account
move to the second cluster and the pool's retirement, then park, borrow, repay), `ShMonadExitSettle.fork.test.ts`
(v1.6.0's settle fixes H2, H3, H10, M10, and pause/halt gating).

## 6. The LTV simulation (`evidence/ltv-study/`)

`ShMonadExitUshLtv.fork.test.ts`, 24 cases on a Monad fork: twelve 30-hour holds at six LTV pairs and two
utilizations (interest matches the curve within 1 bp, nothing liquidatable), and twelve feed drops at two pairs with a
real liquidation, maturity and redemption. **24 passing.** The results and their reading are in
[11-ltv-study.md](11-ltv-study.md).

## 7. The audit (`evidence/audit-2026-11-15.md`)

2026-11-15, on ushMON v1 and its three live copies (no author named in the report): "No High. 1 Medium, 3 Low, 4
informational." Fábio Soares' three GitHub issues of 2026-11-16 raise L1 and I2 to High and I1 to Medium with
reproductions on an anvil fork of Monad (issue 1 names block 122775206); the fixes are v2 (sections 1 and 2 above). Eight further issues
(4 to 11, two Medium and six Low) were filed by ardey26 the same day and are listed in [04-ushmon.md](04-ushmon.md).

## 8. The mainnet release (`evidence/release-mainnet/`)

2026-11-16, after the fork tests above. `mainnet-desks.log`: `deploy.sh desks` created the two v2 vaults
(0xC8f5023512c0618B754e03d675E3626a4A760092 for the usdc-hl desk, 0xa2F34235e4C3c0706B2d5B9170F924446b1Df664 for the usdc-hl-d0 desk), the router
resolves each to shMON and the WMON vault lends 93/95 against each; `deploy.sh verify` reads "all OK" and both vaults'
source is verified on Monadscan. `release-mainnet.log`: the admin Safe upgraded both desks from v1.6.0 to v1.7.0
(implementation 0xBE243F5e4215720080929eeCfe77047D2Fd2a410), moved each desk's Euler account onto its v2 vault, opened the two
EulerSwap pools (0x9028e8aF57Da3173B9136189A7E5f0c32d5eA8a8, 0x748aD60aff8Fee5C552Cc7Cd480aE2D5226028a8; the read-back quotes a fee of 2.25% under the
ceiling and refuses WMON in), staked 80 MON per desk and parked 48.38 shMON in each vault as headroom, and lent
929.88 WMON to the WMON vault as the float. The dev key kept 9.96 MON for gas. The state read back after the release is
the last section of `evidence/live-reads.md`.

## 9. The one-vault release (`evidence/release-ush3/`)

2026-11-17, after sections 1, 2a, 3a and the two ush5 harness runs. `mainnet-desks-v3.log`: `deploy.sh desks` created
one v3 vault, 0x37e07473F1F62CB071Db57440e242b320614A0ce, with both desks as operators; the router resolves it to shMON
and the WMON vault lends 93/95 against it; `deploy.sh verify` reads "all OK" and the source is verified on Monadscan
(the v2 lines in `deployed-143.env` are kept as `V2_USHMON_*`). `release-ush3-mainnet.log`: the admin Safe upgraded both
desks from v1.7.0 to v1.8.0 (implementation 0xDF9515a5d2f68B12a4fAFc44e518B13751A1c3B2), took each desk's 48.38 shMON
out of its v2 vault with `unparkShmon`, moved each desk's Euler account onto the one vault, opened a pool per desk
(0xA65De145091aaa6e4540830A34Fc098dE3E668a8 for usdc-hl, 0x6e44D5d4c8a4dA51027A71789934bA33799ca8a8 for usdc-hl-d0; the
read-back quotes 2.2549% under the ceiling and refuses WMON in) and parked the headroom again; the WMON float of 929.88
stayed where it was. The state read back after the release is the last section of `evidence/live-reads.md`.
