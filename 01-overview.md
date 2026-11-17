# 1. Overview

## What the product is

Alpha Structures runs yield vaults. A depositor puts in one asset and the vault runs a carry trade with it: it lends the
asset as collateral, borrows a stablecoin against it, buys more of the asset with the loan, and holds a Hyperliquid
perpetual short so the vault's exposure to the asset stays at a fixed "resting delta" of either one or zero. The vault
earns the funding paid to shorts less the borrow cost, and the share price is measured from live balances, never
forecast.[^arch]

On Monad the asset is **shMON**, Fastlane's liquid staking token for MON. Two vaults are live, one per resting delta:

| Vault | Resting delta | What a holder owns |
|---|---|---|
| `shmon-neverland-usdc-hl` | 1 (delta one) | shMON exposure plus the carry |
| `shmon-neverland-usdc-hl-d0` | 0 (delta neutral) | the carry only, in dollars |

Both borrow USDC or USDT0 from two lenders: Neverland (an Aave v3 fork on Monad) and an Euler cluster the team deployed
itself.[^lenders] Both are empty at the time of writing (zero shares, zero assets), after a redeployment cycle; see
[09-current-state-and-next.md](09-current-state-and-next.md).[^live]

## Why leaving shMON is the hard part

A depositor leaves by redeeming shares for the vault's asset or for stablecoin. To pay them the vault must turn shMON
back into MON or a stablecoin and repay its loan. shMON offers two ways out:[^shmonad]

- **The slow unstake.** Free, and it takes about a day: 19.6 hours typically, 18.2 to 21.3 hours for 8 in 10 requests.
- **The instant exit.** Paid from shMonad's atomic pool at a fee that moves with the pool's fill: 0.41% low, 0.55%
  typical, 0.73% high over the last 30 days read, and 0.41% at the block this spec was written.

Selling shMON on a DEX is not a third way. The shMON/MON and shMON/USDC pairs trade about $2,700 and $4 a day across
every Monad venue, against about $1.7 million a day each way for MON/USDC.[^dex] So the choice is "a day for free" or
"now for about half a percent", and the vault wants neither for its depositors.

## What the exit desk does about it

Each vault has an **exit desk**, a contract the vault's bot drives. The desk takes a leaver's shMON through the free
one-day unstake, and meanwhile raises the stablecoin the leaver is owed without paying a market's slippage:[^desk]

1. It parks the shMON in the vault's **unstaking shMON vault (ushMON)** on the Euler cluster and sends it into the
   unstake. The parked shMON is Euler collateral.
2. It borrows **WMON** (wrapped MON) against it from the cluster's WMON vault, at up to 97% of value.
3. It sells that WMON for USDC through the **digester**, the team's own Uniswap v4 pool where the desk rests small limit
   orders one tick off the market and a keeper fills them from other pools' flow.
4. A day later the unstake pays MON back into ushMON as WMON, and the desk repays the WMON loan with it in one Euler
   batch. The leaver has been paid in stablecoin at the fee-free rate, less a 0.3% exit fee that stays with the holders
   who remain.

## What the public shMON buyer adds

The same desk owns an **EulerSwap pool**, a Uniswap v4 hook AMM whose liquidity is an Euler account instead of a token
balance. The pool buys shMON from anyone at shMonad's live rate less 0.3%, undercutting the instant exit, and pays WMON
it borrows just in time against the shMON it just received, which lands in ushMON as the desk's collateral. The one-day
unstake repays the borrow and the 0.3% stays with the vault. This is how the vault captures a share of the shMON to MON
flow on Monad, which has run between 3.5 and 9.4 million MON a month since launch.[^flow] The pool was first opened on
2026-11-06 on an earlier cluster, retired on 2026-11-09 when the desk moved clusters, and was reopened on 2026-11-16 on the
ushMON v2 vaults described in [04-ushmon.md](04-ushmon.md).

## State on 2026-11-17, 18:41Z

| Piece | State |
|---|---|
| Strategy vaults (2) | live, empty, exit desk v1.8.0 on both (upgraded 2026-11-17) |
| Euler cluster on Monad | live, four vaults, 929.88 WMON lent by the deployer key, no loans, governed by the deployer key; caps set 2026-11-17: USDC and USDT0 5M supply / 4.5M borrow, WMON 727M supply / 654M borrow (about $10M) |
| ushMON v3 (one vault for both desks) | 0x37e07473F1F62CB071Db57440e242b320614A0ce, live since 2026-11-17; both desks are its operators, each on its own ledger; 96.76 shMON parked (48.38 per desk); WMON lends 93/95 against it |
| ushMON v1 and v2 vaults | replaced; empty, no longer any desk's collateral |
| EulerSwap public buyer | two pools, one per desk, reopened 2026-11-17 on the one vault (0xA65D…68a8, 0x6e44…a8a8), buying shMON at shMonad's rate less 0.3% |
| Capital for the buyer | 1,100 MON from Root: 80 MON staked per desk as headroom, 929.88 WMON lent as the float, 10 MON kept for gas |
| Audit issues | all 11 closed on 2026-11-16 (7 fixed in v2, 3 closed by design or by tests, issue 6 by the study and 93/95) |

[^arch]

On Monad the asset is **shMON**, Fastlane's liquid staking token for MON. Two vaults are live, one per resting delta:

| Vault | Resting delta | What a holder owns |
|---|---|---|
| `shmon-neverland-usdc-hl` | 1 (delta one) | shMON exposure plus the carry |
| `shmon-neverland-usdc-hl-d0` | 0 (delta neutral) | the carry only, in dollars |

Both borrow USDC or USDT0 from two lenders: Neverland (an Aave v3 fork on Monad) and an Euler cluster the team deployed
itself.[^lenders] Both are empty at the time of writing (zero shares, zero assets), after a redeployment cycle; see
[09-current-state-and-next.md](09-current-state-and-next.md).[^live]

## Why leaving shMON is the hard part

A depositor leaves by redeeming shares for the vault's asset or for stablecoin. To pay them the vault must turn shMON
back into MON or a stablecoin and repay its loan. shMON offers two ways out:[^shmonad]

- **The slow unstake.** Free, and it takes about a day: 19.6 hours typically, 18.2 to 21.3 hours for 8 in 10 requests.
- **The instant exit.** Paid from shMonad's atomic pool at a fee that moves with the pool's fill: 0.41% low, 0.55%
  typical, 0.73% high over the last 30 days read, and 0.41% at the block this spec was written.

Selling shMON on a DEX is not a third way. The shMON/MON and shMON/USDC pairs trade about $2,700 and $4 a day across
every Monad venue, against about $1.7 million a day each way for MON/USDC.[^dex] So the choice is "a day for free" or
"now for about half a percent", and the vault wants neither for its depositors.

## What the exit desk does about it

Each vault has an **exit desk**, a contract the vault's bot drives. The desk takes a leaver's shMON through the free
one-day unstake, and meanwhile raises the stablecoin the leaver is owed without paying a market's slippage:[^desk]

1. It parks the shMON in the vault's **unstaking shMON vault (ushMON)** on the Euler cluster and sends it into the
   unstake. The parked shMON is Euler collateral.
2. It borrows **WMON** (wrapped MON) against it from the cluster's WMON vault, at up to 97% of value.
3. It sells that WMON for USDC through the **digester**, the team's own Uniswap v4 pool where the desk rests small limit
   orders one tick off the market and a keeper fills them from other pools' flow.
4. A day later the unstake pays MON back into ushMON as WMON, and the desk repays the WMON loan with it in one Euler
   batch. The leaver has been paid in stablecoin at the fee-free rate, less a 0.3% exit fee that stays with the holders
   who remain.

## What the public shMON buyer adds

The same desk owns an **EulerSwap pool**, a Uniswap v4 hook AMM whose liquidity is an Euler account instead of a token
balance. The pool buys shMON from anyone at shMonad's live rate less 0.3%, undercutting the instant exit, and pays WMON
it borrows just in time against the shMON it just received, which lands in ushMON as the desk's collateral. The one-day
unstake repays the borrow and the 0.3% stays with the vault. This is how the vault captures a share of the shMON to MON
flow on Monad, which has run between 3.5 and 9.4 million MON a month since launch.[^flow] The pool was first opened on
2026-11-06 on an earlier cluster, retired on 2026-11-09 when the desk moved clusters, and was reopened on 2026-11-16 on the
ushMON v2 vaults described in [04-ushmon.md](04-ushmon.md).

## State on 2026-11-16

| Piece | State |
|---|---|
| Strategy vaults (2) | live, empty, exit desk v1.6.0 on both |
| Euler cluster on Monad | live, four vaults, no lenders yet, governed by the deployer key |
| ushMON v1 vaults (2 in use) | live, empty, open deposit (the audit's issue 1) |
| ushMON v2 | written and tested (10 unit tests, 8-step fork cycle), not yet deployed; fixes issues 1 to 3 of 11 open |
| EulerSwap public buyer | code live in the desk; no pool open; reopening rehearsed on a fork |
| Capital for the buyer | 400 MON sent to the deployer key on 2026-11-16 for the first float and headroom |

[^arch]: `alphastructures/docs/Alpha_Structures_Architecture.md:5` and `docs/Alpha_Structures_System_Overview.md:15,127-138`.
[^lenders]: `alphastructures/CLAUDE.md:32`, `docs/Alpha_Structures_Architecture.md:10-11,29`.
[^live]: `evidence/live-reads.md`, block 122821118, 2026-11-16 19:22Z: both vaults return `totalSupply() == 0`.
[^shmonad]: `evidence/data/unstake-timing-30d.md` (119 requests, read 2026-11-05); `evidence/data/shmonad-30d.md` (720 hourly reads to 2026-11-05); live fee `getCurrentUnstakeFeeRateRay() == 0.4085%` in `evidence/live-reads.md`.
[^dex]: `evidence/data/rate-30d.md` and `rate-30d.json` (1,018,207 swaps over 721 hours, blocks 111184875 to 119665718, run 2026-11-07, `backfill-30d.json`).
[^desk]: `alphastructures/docs/Alpha_Structures_Digester.md:3-7,24,37-38`; `docs/shmon-exit-desk-plan.md:36-43`; exit fee `contracts/core/WithdrawalHandler.sol:34-35,283`.
[^flow]: `evidence/data/instant-history.md`, monthly table (instant exits paid out 2025-12 to 2026-10).
