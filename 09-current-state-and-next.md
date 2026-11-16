# 9. Current state and what is next

As of 2026-11-16, 19:22Z (block 122821118). Live figures are in `evidence/live-reads.md`.

## Live today

| Component | State |
|---|---|
| Strategy vaults `shmon-neverland-usdc-hl` and `-d0` | Deployed, every contract at the addresses in [02-alpha-structures.md](02-alpha-structures.md). Both hold zero shares and zero assets. |
| Exit desks | v1.6.0 on both. Each holds its ushMON (v1) as its only Euler collateral and the cluster's WMON vault as its only controller. No pool open, no loan, nothing parked. |
| Euler cluster | Four vaults live, settings as deployed, zero cash and zero loans, governed by the deployer key. |
| ushMON v1 (two in use) | Live, empty, open to any depositor (issue 1). |
| Neverland | 29.5M shMON supplied; USDC 80% used with 325k of room before the kink; USDT0 85.6% used with 103k of room. |
| shMonad | 329.9M MON staked; 3.92M MON payable at once against a 6.58M target; instant-exit fee 0.4085%. |
| Digester | Hook, pool, router and keeper live; two exit bid pools (USDC, WMON) live since 2026-11-12. |
| Server | 3.211.84.65 runs the bots, oracle, monitor, keeper, API and site. |

## In flight: ushMON v2 and the public buyer

Approved by Root in the working session of 2026-11-16 ("plan it. test it. validate it. ship it.", both the three fixes and the EulerSwap pool).

| Step | State |
|---|---|
| Vault v2 code (three fixes) | Done; `ushMON/src/UnstakingShMonVault.sol` working tree, copied to `ag-euler/contracts/eulerswap-mm-monad/src/exitmm/` and built. Not yet committed or pushed. |
| Unit tests | Done, 10 of 10 pass. |
| Bot: unstake the shMON the pool parks | Done in the working tree (`packages/shared/src/chain/exitDesk.ts`, `services/rebalancingBot/src/planner/exitDesk.ts`, one new unit test passing). Not yet committed. |
| Exit desk v1.7.0 (the pool yields to the vault's leavers) | Done in the working tree; storage layout recorded; proven in the fork cycle test's step 9. Root, 2026-11-16: "build the priority rule into the desk". |
| Release script `custody/release-ush2-143.ts` | Done, rehearsed on a fork end to end at 93/95 with the v1.7.0 desk: vaults, upgrades, account moves, pools, 80 MON headroom per desk, 930 WMON float, and an outsider's sale. |
| Fork cycle test | Done, 10 of 10 pass. |
| Five-stage harness | Delta neutral passed with the v2 build. Delta one's stages 3 and 4 rerunning from its saved point. Both deltas relaunched on the final tree (v1.7.0 desk) as the holistic test. |
| Mainnet: deploy two v2 vaults (`deploy.sh desks`), repoint the desks, open the pools, park headroom, lend the float | Pending the delta-one harness result. The 400 MON Root sent sits on the deployer key. |
| ushMON repo: commit v2 and tests, update README, reply to and close issues 1 to 3 | Pending the mainnet addresses. |
| Issues 4 to 11 (ardey26, 2026-11-16 17:58Z) | Issue 4 fixed in v2 (no approval, live-shaped mock, fork test); issue 5 closed by design (the operator is the upgradeable desk); issue 6 studied in [11-ltv-study.md](11-ltv-study.md), new vaults deploy at 93/95; 7 to 11 open, each needs Root's call. |
| Bot release to the server | Pending; needs the planner change merged on the server and the bots restarted. |

## Open decisions

- **The bot's $10 floor.** Every desk step is skipped under $10 of value (`DESK_DUST_USD`). With MON near $0.018 the
  400 MON float is about $7, so the bot would not drive the unstake, settle or restake of the pool's buys on its own.
  Root sent 700 MON more on 2026-11-16 (1,100.53 MON on the deployer key): 80 MON per desk is parked as headroom at
  the 93% borrow LTV, 10 stays for gas, and about 930 WMON is lent as the float, about $17. Nothing else blocks the release.
- **The WMON float's size.** 360 MON covers a typical shMonad instant exit (median 1.85 MON, 90th percentile 220 MON)
  once per cycle. Taking the whole public flow (about 160,000 MON a day lately) needs lenders of that order in the
  cluster's WMON vault.

## Known risks

- **shMonad freezes.** If shMonad sets `closed` on a stake deficit, `requestUnstake` and `completeUnstake` revert and
  parked shMON cannot become WMON; the WMON loan runs until shMonad reopens (audit M1, accepted as a dependency; Fastlane
  calls the precondition "impossible under current Monad staking assumptions").
- **Collateral headroom.** A pool sale borrows 99.7% against collateral lent at 97%, so about 3% of outstanding buys
  must already be parked; the release parks 15 MON per desk and the bot's planner keeps the pool's buys unstaking.
- **Liquidators wait a day.** A seized ushMON share pays out only after maturity (audit L3). The price risk is MON
  against MON, so it is near zero; the cost is fewer liquidators.
- **Upstream RPC.** Fork runs and the bot depend on the Monad RPC; one harness launch today died on a 9-second timeout
  from the provider, and the public RPC refuses some pinned historical reads.
- **Governance.** The cluster is governed by the deployer key, not yet a Safe. `deploy.sh handover` exists for the move.
- **Docs drift.** The alphastructures docs still describe desk v1.5.0 as live and list older exit-bid-pool addresses;
  the chain reads in this spec take precedence.
