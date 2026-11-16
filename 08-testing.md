# 8. Testing

Every result here has its log under `evidence/` and a command to rerun it. Dates are 2026-11-16 unless stated.

## 1. ushMON v2 unit tests (`evidence/forge-test.txt`)

Ten Foundry tests in `ushMON/test/UnstakingShMonVault.t.sol` against mocks and the real Ethereum Vault Connector; the
cases are listed in [04-ushmon.md](04-ushmon.md). Result: **10 passed, 0 failed**.

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

## 3. Release rehearsal on an anvil fork (`evidence/rehearsal-fork.log`)

The exact mainnet release path on a fresh fork of Monad at head: `deploy.sh desks` deploys two v2 vaults and sets the
router and WMON-vault settings (`govSetResolvedVault … OK`, `setLTV 9700 9800: OK` per vault; the first rehearsal's
`verify` step in `evidence/rehearsal-fork-first.log` reads `ok` for both), then `custody/release-ush2-143.ts` moves both desks' accounts, opens
both pools, parks 15 MON of headroom per desk, and lends 360 WMON into the WMON vault. Every step ran and read back OK. A
seller's sale into the pool simulated correctly (`cast call --trace`, 0.30% under the rate, the desk's account check
passing); the same sale sent through `cast send` returned `status 0 (failed)`; the log records only the status, and the
writer's reading is anvil's gas estimate on nested EVC calls, to be checked at the mainnet release with an explicit gas
limit.

```sh
anvil --fork-url <rpc> --port 8700 --chain-id 143
cd ag-euler/contracts/shmon-cluster-monad && RPC=http://127.0.0.1:8700 DESKS="usdc-hl=0x02Df…,usdc-hl-d0=0xF460…" zsh deploy.sh desks
cd alphastructures && RPC=http://127.0.0.1:8700 FORK=1 CLUSTER_ENV=…/deployed-143-fork.env npx tsx custody/release-ush2-143.ts
```

## 4. The five-stage fork harness (`evidence/harness/`)

`alphastructures/services/rebalancingBot/test/sim/multi/final.ts`, run by `harness/fresh-try.sh` under launchd: a fork
of live Monad at head with the real bot, oracle, monitor and keeper, one vault on both lenders, the stable desk and the
exit desk. The stages (`final.ts:1-12`):

0. The exit desk gets its Euler account: a fresh ushMON on the cluster, operated by the desk.
1. Growth: a $300k deposit; borrowed USDC buys MON only through the desk's resting buys, filled by the keeper.
2. Neverland USDC goes past its kink and the stable desk moves debt to USDT0.
3. MON and shMON fall 35% with the bot running: no lender may liquidate, each comes back under its unwind line.
4. Wind-down: half the shares redeem; the bot raises the loan share through the desk's chunked route and serves the batch.

Through all of it no market swap may run. shMonad's unstake cannot mature on a fork, so stage 4 on the delta-one base
ends at "FINAL WAITS ON UNSTAKE" (`evidence/harness/final-live-11/scenario.log:261`; the reason is in
`docs/testbook.md:178-182`); the one-day leg is covered by test 2 above.

| Run | Base | Vault build | Result |
|---|---|---|---|
| final-live-10, 2026-11-15 | delta neutral | v1 | FINAL PASSED (batch served, debt 100,883 to 3,108) |
| final-live-11, 2026-11-15 | delta one | v1 | 32 PASS checks, no FAIL, stage 4 FINAL WAITS ON UNSTAKE; stage 2 logged a TIMEOUT on the debt move, as final-live-10 and ush2-d0 also did |
| ush2-hl, 2026-11-16 18:19Z | delta one | v2 + planner change | FAIL at stage 0: the upstream RPC timed out ("failsafe timeout policy exceeded"); relaunched |
| ush2-d0, 2026-11-16 18:13Z to 19:22Z | delta neutral | v2 + planner change | **FINAL PASSED**, 29 PASS checks, no FAIL; one TIMEOUT line in stage 2 (debt move) and one in stage 4 (desk sells after the payout) |
| ush2-hl2, 2026-11-16 18:27Z | delta one | v2 + planner change | in progress at the time of writing; see `evidence/harness/ush2-hl2/` |

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

## 6. The audit (`evidence/audit-2026-11-15.md`)

2026-11-15, on ushMON v1 and its three live copies (no author named in the report): "No High. 1 Medium, 3 Low, 4
informational." Fábio Soares' three GitHub issues of 2026-11-16 raise L1 and I2 to High and I1 to Medium with
reproductions on an anvil fork of Monad (issue 1 names block 122775206); the fixes are v2 (sections 1 and 2 above). Eight further issues
(4 to 11, two Medium and six Low) were filed by ardey26 the same day and are listed in [04-ushmon.md](04-ushmon.md).
