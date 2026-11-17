# 9. Current state and what is next

As of 2026-11-17, 03:00Z (block 122910315). Live figures are in the last section of `evidence/live-reads.md`; the
release logs are in `evidence/release-mainnet/`.

## Live today

| Component | State |
|---|---|
| Strategy vaults `shmon-neverland-usdc-hl` and `-d0` | Deployed, every contract at the addresses in [02-alpha-structures.md](02-alpha-structures.md). Both hold zero shares and zero assets. |
| Exit desks | v1.7.0 on both (implementation 0xBE243F5e4215720080929eeCfe77047D2Fd2a410, upgraded by the admin Safe on 2026-11-16). Each holds its ushMON v2 as its only Euler collateral and the cluster's WMON vault as its only controller. No loan. `leaversWaiting()` is false on both. |
| ushMON v2 | 0xC8f5023512c0618B754e03d675E3626a4A760092 (usdc-hl) and 0xa2F34235e4C3c0706B2d5B9170F924446b1Df664 (usdc-hl-d0). Each holds 48.38 shMON parked by its desk as headroom, every share held by the desk, deposit closed to outsiders. Source verified on Monadscan. |
| EulerSwap pools | 0x9028e8aF57Da3173B9136189A7E5f0c32d5eA8a8 (usdc-hl) and 0x748aD60aff8Fee5C552Cc7Cd480aE2D5226028a8 (usdc-hl-d0), open since 2026-11-16, buying shMON at shMonad's rate less 0.3% and refusing WMON in. |
| Euler cluster | Four vaults live. The WMON vault holds 929.88 WMON lent by the deployer key, no loans, and lends 93/95 against both ushMON v2 vaults. Governed by the deployer key. |
| ushMON v1 | Replaced. Empty, no longer any desk's collateral; recorded as `V1_USHMON_*` in `deployed-143.env`. |
| Audit issues | All 11 closed on 2026-11-16 with a reply on each: 1, 2, 3, 4, 7, 8 and 11 fixed in v2; 5, 9 and 10 closed by design or by the donation tests; 6 by [11-ltv-study.md](11-ltv-study.md) and the move to 93/95. |
| Server | 3.211.84.65 runs the bots, oracle, monitor, keeper, API and site, still on the code before this release (see below). |

## Shipped on 2026-11-16

Root, 2026-11-16: "ship it". In order:

1. `deploy.sh desks` created the two v2 vaults, resolved them on the router and set the WMON vault's LTV to 93/95; `deploy.sh verify` read "all OK".
2. `custody/release-ush2-143.ts` deployed desk v1.7.0 and had the admin Safe upgrade both desks, move each desk's Euler account onto its v2 vault, open the two pools, stake 80 MON per desk and park 48.38 shMON in each vault, then wrapped and lent 929.88 WMON as the float.
3. ushMON v2 and its 17 tests were committed as `4235998` and pushed to `rootdraws/ushMON`; the eleven issues were answered and closed.

## Pending for Root

| Step | State |
|---|---|
| Commit the alphastructures working tree | The desk v1.7.0 source and its storage layout, the planner's `parkShmon` step, the release script, the fork tests, and the production configs and manifests the release wrote (each config's `unstakeVault` now names the v2 vault) are uncommitted. The spec's Claude session does not commit in that repo. |
| Ship the bots | Merge the commit onto `/opt/alphastructures/src` on the server, build there and restart the bots (Runbook §4). Until then the bots on the server read the old configs, which still name the v1 vaults, and will not drive the pools' buys through the unstake. |
| Headroom at scale | 80 MON per desk covers about 1,100 MON of pool buys a day at the 93% borrow LTV (7.2% of a day's sales). At Root's target of 50k to 150k MON every 20 hours the desks need 3,600 to 10,800 MON parked; whether that comes from the vaults' own shMON or new MON is Root's call. |
| Lenders | The float is 929.88 WMON. Taking the public flow (about 160,000 MON a day lately) needs WMON lenders of that order in the cluster's WMON vault; the curve charges borrowers 20% at zero use and 30% at the 90% kink, and lenders get 90% of what is paid. |

## Known risks

- **shMonad freezes.** If shMonad sets `closed` on a stake deficit, `requestUnstake` and `completeUnstake` revert and
  parked shMON cannot become WMON; the WMON loan runs until shMonad reopens (audit M1, accepted as a dependency; Fastlane
  calls the precondition "impossible under current Monad staking assumptions").
- **Collateral headroom.** A pool sale borrows 99.7% against collateral lent at 93%, so about 7.2% of a day's buys must
  already be parked; the release parked 48.38 shMON (80 MON) per desk and the bot's planner keeps the pool's buys unstaking.
- **Liquidators wait a day.** A seized ushMON share pays out only after maturity (audit L3). The price risk is MON
  against MON; at 93/95 the position becomes liquidatable from a 3% one-day fall in shMonad's rate and the lender's
  first loss comes at 5% ([11-ltv-study.md](11-ltv-study.md)).
- **Upstream RPC.** Fork runs and the bot depend on the Monad RPC; one harness launch on 2026-11-16 died on a 9-second
  timeout from the provider, and the public RPC refuses some pinned historical reads.
- **Governance.** The cluster is governed by the deployer key, not yet a Safe. `deploy.sh handover` exists for the move.
- **Docs drift.** The alphastructures docs still describe desk v1.5.0 as live and list older exit-bid-pool addresses;
  the chain reads in this spec take precedence.
