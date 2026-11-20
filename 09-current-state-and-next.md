# 9. Current state and what is next

Read on chain and on the server on 2026-11-20 at 05:22Z, block 123,782,520.

## Live today

| Part | State |
|---|---|
| Strategy vaults | Both are deployed and empty, with zero shares. Each takes up to 84M shMON, about $2M. They run Vault 1.12.0, controller 1.16.0 and settings 1.16.0. Addresses are in [02-operations.md](02-operations.md). |
| Exit desks | Both run 1.10.0. Each borrows only from the cluster's WMON vault, against its ushMON. No leavers are waiting. |
| Delta One desk | It has 48.37 shMON parked as its collateral cushion, and no loan. |
| Delta Neutral desk | It has 611.85 shMON parked: its 48.37 cushion and 563.48 its pool bought. It owes about 930.4 WMON for that buy. The shMON is unstaking for 930.97 MON, due at epoch 1744; shMonad is at epoch 1742. |
| ushMON | One vault for both desks, `0xa753E24B0986567EDAd75f784664Ec11336f8C5e`, holding 660.22 shMON. Only the desks hold shares. |
| EulerSwap pools | Delta One `0x56aE…28A8` and Delta Neutral `0x1924…e8a8`. Each buys shMON at shMonad's rate less 0.30% and refuses WMON. |
| Euler cluster | Four vaults, governed by the deployer key. The WMON vault's 930.7 WMON is almost all lent to the Delta Neutral desk, so 0.26 WMON is free. The USDC and USDT0 vaults have no lenders. |
| Server | `3.211.84.65` runs 12 containers for `monad.structures.gg`. The two bots run image `bandsale-20261120`. |

## Shipped from 2026-11-18 to 2026-11-20

- **ushMON v4.** The WMON behind a share moves with it, so a liquidator can redeem what it seizes.
- **The emergency sale.** At a 65% loan the bot sells WMON within 2% of the oracle, borrowing and selling in one
  transaction.
- **The deposit cap.** 84M shMON on each vault.
- **New loan lines.** The short's profit repays the loan over 55%, the unwind starts at 60% and stops at 52.5%, and
  margin may be borrowed up to 55%. Euler's lines match, scaled to its 80% liquidation line.
- **Deposits during a pause.** A paused vault still takes deposits and adds them to the lender as collateral. Borrowing
  stays blocked.
- **Maker orders on Hyperliquid.** The bot grows the short with a resting order one tick above mid.
- **The 58% band sale is gone.** It sold shMON ahead of the 60% unwind.

## Open decisions

- **The desks' collateral cushion at scale.** 80 MON per desk covers about 1,100 MON of pool buys a day. At the target
  of 50k to 150k MON every 20 hours, the desks need 3,600 to 10,800 MON parked. Whether that comes from the vaults' own
  shMON or new MON is still open.
- **WMON lenders.** The pools can buy only as much as lenders supply. The full instant-exit flow, about 120,000 to
  310,000 MON a day, needs WMON supply of that size, about $1,800 to $4,500.

## Known risks

- **shMonad freezes.** If shMonad stops unstaking, parked shMON cannot become WMON, and the WMON loan runs until it
  reopens.
- **The cushion.** A pool sale borrows 99.7% of its value against collateral lent at 93%. About 7.2% of a day's buys
  must already be parked, or the pool stops buying.
- **Shared ushMON.** Shares are priced over one pot, so a desk holding shMON earns a little of the yield the other
  desk's unstaking MON forgoes, about 0.03% a day on the unstaking part.
- **Liquidators wait a day.** A seized share pays out only after its unstake finishes. At 93/95, a 3% one-day fall in
  shMonad's rate makes a desk liquidatable, and the lender first loses at 5%. See [11-ltv-study.md](11-ltv-study.md).
- **One RPC.** The bots and the oracle read Monad through one Alchemy key, with no backup.
- **Governance.** The deployer key governs the Euler cluster, not a Safe. `deploy.sh handover` exists for the move.
