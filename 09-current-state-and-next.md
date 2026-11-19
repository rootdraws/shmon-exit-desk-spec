# 9. Current state and what is next

As of 2026-11-19 15:11Z, block 123,614,706. The reads are in the last section of `evidence/live-reads.md`, and the
release records are listed in [08-testing.md](08-testing.md).

## Live today

| Component | State |
|---|---|
| Strategy vaults `shmon-neverland-usdc-hl` and `-d0` | Deployed at the addresses in [02-operations.md](02-operations.md). Both hold zero shares and zero assets. Both controllers run v1.15.0, upgraded by the admin Safe on 2026-11-19. The 10% performance fee is charged on every gain ([12-revenue-flows.md](12-revenue-flows.md)). |
| Exit desks | v1.10.0 on both (`0x74eCd223208D812098487D4090d964005370BDc7`), upgraded by the admin Safe on 2026-11-19. Each holds ushMON v4 as its only Euler collateral, and the cluster's WMON vault is its only lender. `leaversWaiting()` is false on both. |
| Delta One desk | 48.38 shMON parked as headroom. No loan. |
| Delta Neutral desk | 611.93 shMON parked: the 48.38 headroom and 563.55 its pool bought at 10:05Z (block 123,554,268). It owes 929.83 WMON for that buy. None of it is unstaking yet. |
| ushMON v4 | `0xa753E24B0986567EDAd75f784664Ec11336f8C5e`, one vault for both desks. It holds 660.31 shMON, every share held by the desks. Both ledgers are empty. Source verified on Monadscan. |
| EulerSwap pools | `0x56aEAB6F7a33573CdEF9B59a8d330F0e1b2128A8` (Delta One) and `0x19241Ff986e1dFE848A8C2a8AC2C21C0E7cFe8a8` (Delta Neutral), opened 2026-11-18 on the v4 vault. They buy shMON at shMonad's rate less 0.3% and refuse WMON in. |
| Euler cluster | Four vaults live, governed by the deployer key. The WMON vault lends 93/95 against ushMON v4. Its 929.88 WMON float is lent out to the Delta Neutral desk, leaving 0.26 WMON. The USDC and USDT0 vaults have no lenders. Caps: USDC and USDT0 5M supply and 4.5M borrow; WMON 727M supply and 654M borrow. |
| ushMON v1, v2 and v3 | Empty and retired from the cluster (WMON vault LTV 0). v1 and v2 went on 2026-11-17, and v3 (`0x37e07473F1F62CB071Db57440e242b320614A0ce`) on 2026-11-18. |
| Audit issues | All 11 closed on 2026-11-16 with a reply on each ([04-ushmon.md](04-ushmon.md)). v4 keeps every v2 rule. |
| Server | 3.211.84.65 (`monad.structures.gg`) runs 12 containers: the two shMON bots, oracle, monitor, digester keeper, funding feed, API, site, Caddy, research refresh, RPC meter and MongoDB. The bots run image `panic-20261119`, built 2026-11-19 03:48Z. `admin.structures.gg` serves the live revenue page behind a password. |

## Shipped on 2026-11-18 and 2026-11-19

1. **ushMON v4** (Root 2026-11-18: "yes, build the ushMON fix"): the WMON a finished unstake returns follows the shares,
   so a liquidator can redeem what it seized ([04-ushmon.md](04-ushmon.md)).
2. **Desk v1.9.0** and the move onto v4: both desks moved their accounts, opened the two new pools and parked the
   headroom again.
3. **The deposit cap:** 84M shMON (about $2M) on both shMON vaults, set through the admin Safe.
4. **The monitor** unpauses a vault after 30 minutes at or under 50%, the bot's unwind stop.
5. **The emergency sale** (Root 2026-11-18: "if you are pressed to the wall, you should avail yourself of every
   shMON/wMON opportunity available"): controller v1.15.0 and desk v1.10.0. Over 65% the bot sells MON as a taker
   within 2% of the oracle, and borrow-to-fill runs in one transaction ([03-exit-desk.md](03-exit-desk.md)).

## Pending for Root

| Step | State |
|---|---|
| Headroom at scale | 80 MON per desk covers about 1,100 MON of pool buys a day at the 93% borrow LTV (7.2% of a day's sales). At Root's target of 50k to 150k MON every 20 hours, the desks need 3,600 to 10,800 MON parked. Whether that comes from the vaults' own shMON or new MON is Root's call. |
| Lenders | The whole 929.88 WMON float is lent out, so the two pools can pay out only 0.26 WMON until the loan is repaid. Taking the public flow (about 160,000 MON a day lately) needs WMON lenders of that order. The curve charges borrowers 20% at zero use and 30% at the 90% kink, and lenders get 90% of what is paid. |

## Known risks

- **shMonad freezes.** If shMonad closes on a stake deficit, parked shMON cannot become WMON. The WMON loan then runs
  until shMonad reopens (audit M1, accepted as a dependency).
- **Collateral headroom.** A pool sale borrows 99.7% against collateral lent at 93%, so about 7.2% of a day's buys must
  already be parked.
- **One vault, two desks.** Shares are priced pro rata over one pot. A desk holding shMON earns a little of the yield
  the other desk's unstaking MON does not, about 3 bps a day on the unstaking part.
- **Liquidators wait a day.** A seized share pays out only after its unstake matures (audit L3). At 93/95 a 3% one-day
  fall in shMonad's rate makes the desk liquidatable, and the lender's first loss comes at 5%
  ([11-ltv-study.md](11-ltv-study.md)).
- **Upstream RPC.** The fork runs and the bot depend on the Monad RPC.
- **Governance.** The cluster is governed by the deployer key, not yet a Safe. `deploy.sh handover` exists for the move.
