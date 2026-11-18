# 9. Current state and what is next

As of 2026-11-18, block 123,359,143. Live figures are in the last section of `evidence/live-reads.md`; the release
logs are in `evidence/release-ush3/` (2026-11-17) and `evidence/release-mainnet/` (2026-11-16).

## Live today

| Component | State |
|---|---|
| Strategy vaults `shmon-neverland-usdc-hl` and `-d0` | Deployed, every contract at the addresses in [02-alpha-structures.md](02-alpha-structures.md). Both hold zero shares and zero assets. Settings 1.16 on both since 2026-11-18: each delta fixed, and the 10% performance fee charged on every gain ([12-revenue-flows.md](12-revenue-flows.md)). |
| Exit desks | v1.8.0 on both (implementation 0xDF9515a5d2f68B12a4fAFc44e518B13751A1c3B2, upgraded by the admin Safe on 2026-11-17). Each holds the one ushMON v3 as its only Euler collateral and the cluster's WMON vault as its only controller. No loan. `leaversWaiting()` is false on both. |
| ushMON v3 | 0x37e07473F1F62CB071Db57440e242b320614A0ce, one vault for both desks, operators 0x02Df…c770 and 0xF460…6CdE. 96.76 shMON parked (48.38 by each desk), every share held by the desks, both ledgers empty, no WMON credit. Source verified on Monadscan. |
| EulerSwap pools | 0xA65De145091aaa6e4540830A34Fc098dE3E668a8 (usdc-hl) and 0x6e44D5d4c8a4dA51027A71789934bA33799ca8a8 (usdc-hl-d0), opened 2026-11-17 on the one vault, buying shMON at shMonad's rate less 0.3% and refusing WMON in. The pools of 2026-11-16 were retired by the account moves. |
| Euler cluster | Four vaults live. The WMON vault holds 929.88 WMON lent by the deployer key, no loans, and lends 93/95 against ushMON v3. Caps set today: USDC and USDT0 5M supply / 4.5M borrow, WMON 727M supply / 654M borrow (about $10M). Governed by the deployer key. |
| ushMON v1 and v2 | Replaced. Empty, retired from the cluster 2026-11-17 (WMON vault LTV 0, unresolved on the router, read 2026-11-18); recorded as `V1_USHMON_*` and `V2_USHMON_*` in `deployed-143.env`. |
| Audit issues | All 11 closed on 2026-11-16 with a reply on each: 1, 2, 3, 4, 7, 8 and 11 fixed in v2; 5, 9 and 10 closed by design or by the donation tests; 6 by [11-ltv-study.md](11-ltv-study.md) and the move to 93/95. v3 keeps every v2 rule. |
| Server | 3.211.84.65 (`monad.structures.gg`) runs 12 containers: the two shMON bots, oracle, monitor, digester keeper (`monad-digester`), funding feed, API, site, Caddy, research refresh, RPC meter and MongoDB. The bots and site run the service image built 2026-11-18 14:12Z, read over SSH 2026-11-18 18:38Z; the API moved to the admin-page build at 18:59Z, and `admin.structures.gg` serves the live revenue page behind a password. |

## Shipped on 2026-11-17

Root, 2026-11-17: "it looks suspicious enough having ushMON as collateral, But ushMONdo and ushMONdn Seems like a bit
excessive", then "one ushMON". In order:

1. ushMON v3 (`48d07b3`): several operators on one vault, each on its own ledger ([04-ushmon.md](04-ushmon.md)); 21 tests pass.
2. Desk v1.8.0: the settle reads `wmonRedeemable(desk)`; `unparkShmon` ([03-exit-desk.md](03-exit-desk.md)). The storage
   layout is unchanged.
3. The fork test of both live desks on one vault (5 of 5), the release rehearsed twice on a fork, and the five-stage
   harness on both deltas from the final tree, both **FINAL PASSED** ([08-testing.md](08-testing.md)).
4. `deploy.sh desks` made the one vault; `custody/release-ush3-143.ts` upgraded both desks, moved their accounts, opened
   the two pools and parked the headroom again.
5. Earlier the same day: the Exit Desk page rebuilt as tiles with each desk's funnel and its pool's sales; the vault page's
   withdrawal tracker reordered; the cluster's USDC, USDT0 and WMON caps changed.

## Pending for Root

| Step | State |
|---|---|
| Merge the alphastructures branch | Every change of 2026-11-16 to 2026-11-18 is on branch `shmon-release-2026-11-18`, pushed 2026-11-18: the contracts and release at `be23722`, the runbook at `89d7d6d`, the admin site at `ef0f756`; master is still `bd9a894`. |
| Headroom at scale | 80 MON per desk covers about 1,100 MON of pool buys a day at the 93% borrow LTV (7.2% of a day's sales). At Root's target of 50k to 150k MON every 20 hours the desks need 3,600 to 10,800 MON parked; whether that comes from the vaults' own shMON or new MON is Root's call. |
| Lenders | The float is 929.88 WMON. Taking the public flow (about 160,000 MON a day lately) needs WMON lenders of that order in the cluster's WMON vault; the curve charges borrowers 20% at zero use and 30% at the 90% kink, and lenders get 90% of what is paid. |

## Known risks

- **shMonad freezes.** If shMonad sets `closed` on a stake deficit, `requestUnstake` and `completeUnstake` revert and
  parked shMON cannot become WMON; the WMON loan runs until shMonad reopens (audit M1, accepted as a dependency; Fastlane
  calls the precondition "impossible under current Monad staking assumptions").
- **Collateral headroom.** A pool sale borrows 99.7% against collateral lent at 93%, so about 7.2% of a day's buys must
  already be parked; each desk has 48.38 shMON (80 MON) parked and the bot's planner keeps the pool's buys unstaking.
- **One vault, two desks.** Shares are priced pro rata over one pot, so a desk holding shMON earns a little of the yield
  the other desk's unstaking MON does not (about 3 bps a day on the unstaking part). Each desk's WMON is its own by the
  ledger; the stray pot is shared pro rata.
- **Liquidators wait a day.** A seized ushMON share pays out only after maturity (audit L3). The price risk is MON
  against MON; at 93/95 the position becomes liquidatable from a 3% one-day fall in shMonad's rate and the lender's
  first loss comes at 5% ([11-ltv-study.md](11-ltv-study.md)).
- **Upstream RPC.** Fork runs and the bot depend on the Monad RPC; the public RPC caps `eth_getLogs` at 20,000 blocks
  (rpc2) or 100 blocks (rpc), which the API's sales scan works around in chunks.
- **Governance.** The cluster is governed by the deployer key, not yet a Safe. `deploy.sh handover` exists for the move.
- **Docs drift.** The alphastructures docs were brought to the 2026-11-16 release; the chain reads in this spec take
  precedence where they differ.
