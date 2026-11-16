# 11. How much the WMON vault may lend against ushMON (issue 6 study)

Root's seven questions of 2026-11-16, each answered from a measurement or a fork simulation under
[`evidence/ltv-study/`](evidence/ltv-study/). Blocks and dates are in each file.

## 1. What oracle tracks WMON against shMON?

Chainlink's **"SHMON / MON Exchange Rate"** feed, proxy `0x2dC0b316e3d4e673C7F9A809e80a3e60b26d7774` (18 decimals,
aggregator `0xE3F1906C6b6EEA63dCc0C016C4ec6746c69e7476`). The cluster's router reads it through Euler's
`ChainlinkOracle` adapter `0x0A75454cD9c15068C4bdB57ec0436D10B0906c6C` (25 h staleness), then multiplies by the
"MON / USD" feed `0xFB504aD06Ab5E6c63FE0A46FEa245214838E8015` (adapter `0xe6a6…fB9d`, 2 h staleness) to price shMON
in USD; ushMON is resolved to shMON through its `convertToAssets`. WMON itself is priced by the same MON / USD feed, so a
MON price move changes the collateral and the debt together and cancels. What is left is the rate feed.

The feed publishes shMonad's own exchange rate (`convertToAssets`), not a market price. It updates once a day on its
heartbeat: 31 rounds, 86,400 to 86,430 s apart (`feed-divergence-30d.md`).

## 2. How far has the feed sat from shMonad's rate?

Measured over the last 31 daily rounds (2026-10-17 to 2026-11-16, `feed-divergence-30d.json`):

| | min | median | p99 | max |
|---|---|---|---|---|
| at the round's publish block | 0.00 bps | 0.00 bps | 0.00 bps | 0.00 bps |
| just before the next round, the stalest it gets | 2.31 bps under | 3.08 bps under | 3.85 bps under | **4.09 bps under** |

The feed prints shMonad's rate exactly and then lags it for a day while the rate climbs. It never read above shMonad's
rate in the window. So the oracle undervalues ushMON by up to 4 bps and never overvalues it, unless shMonad's rate
falls (a slashing event), which the feed would print within a day.

## 3. What lending rate does the WMON vault offer?

The live curve, IRM `0xa359026aae6c26Ba90B3D3AB78Fc483Da09DBa8a`, read back on chain (`wmon-curve.md`):

| use | borrow APY | supplier APY | borrower cost per day | share of the desk's 0.30% per sale |
|---|---|---|---|---|
| 0% | 20.00% | 0% | 5.0 bps | 17% |
| 50% | 25.46% | 11.46% | 6.2 bps | 21% |
| 90% (kink) | 30.00% | 24.30% | 7.2 bps | 24% |
| 98% and above | 50.00% | 44.10% | 11.1 bps | 37% |

The vault keeps 10% of interest as a fee. Today it holds no lender money and no loans.

## 4. What is shMON's rate, per day?

Over the same 30.0 days shMonad's rate rose from 1.6379 to 1.6533 MON per shMON: **93.8 bps in 30 days, 3.11 bps a
day, 11.36% APR, 12.03% APY** (`shmon-yield-30d.json`). shMON in ushMON keeps earning this until it enters the
unstake; a request's MON amount is fixed when it is made.

## 5. What is the highest LTV possible?

Two things can push the desk's loan over the liquidation line: interest on the loan, and a drop in the feed's rate.

**Interest cannot do it.** On a fork of Monad (`ltv-simulation.jsonl`, 12 cases) the desk borrowed to the borrow LTV
and held for 30 hours, longer than the longest unstake seen (21.9 h) plus two extra epochs. At the 90% kink the debt
grew 8.99 bps, at the 50% cap 13.90 bps, both exactly the curve's figure. With a one-point gap between the borrow and
liquidation LTVs (97/98) health ended at 1.0094 and 1.0089; no pair crossed, and `checkLiquidation` returned zero in
every case. Collateral in the vault that is not yet in the unstake also grows 3.1 bps a day, which offsets a little under
half of the interest at the kink; the simulation put all of it into the unstake, so it earned nothing there.

**A rate drop can.** The feed was moved under shMonad's rate by d bps on the fork, and a liquidator was let loose
(12 cases):

| LTV pair | liquidatable from | liquidator's result at the first crossing | bad debt appears from | at a 5% drop the lender loses |
|---|---|---|---|---|
| 97 / 98 | a **2%** drop (1.02% exactly; at 1.00% health was 1.0002) | +3.07% of the debt it took, no bad debt | a 3% drop (5.82 WMON on 285, 2.0%) | 17.46 WMON on 274 (6.4%) |
| 93 / 95 | a **3%** drop (2.11% exactly) | +4.05%, no bad debt | a 5% drop (2.43 WMON on 277, 0.9%) | 2.43 WMON (0.9%) |

The liquidator's result includes taking the debt over, paying about (1 − borrow LTV) of it in its own WMON to pass
Euler's check, waiting for the desk's unstake to mature, redeeming the seized ushMON for WMON at shMonad's true rate,
and repaying. It profits because ushMON is redeemed at the true rate while it was seized at the feed's lower price.

So the highest LTV is set by how far shMonad's rate could fall in one day, not by interest or the one-day wait. The
feed has moved only upward in the window measured. The rule from the simulation: with liquidation LTV L and borrow LTV
b, the position is liquidatable once the rate drops by 1 − b/L, and the lender starts losing once
(1 − d)(1 − discount) < b, where the discount is 1 − L(1 − d)/b.

## 6. How much LTV does EulerSwap's exchange need?

The pool pays 99.7% of a sale's value in WMON it borrows against the shMON it just received. At borrow LTV b the desk
must already hold 0.997 / b − 1 of the day's sales as parked ushMON, or the borrow reverts `E_AccountLiquidity`
(seen on the fork on 2026-11-16 before the headroom step was added):

| borrow LTV | headroom per unit of daily sales | headroom for a 1,060 WMON float turned over once a day |
|---|---|---|
| 97% | 2.8% | 30 MON |
| 96% | 3.9% | 41 MON |
| 95% | 4.9% | 52 MON |
| 93% | 7.2% | 76 MON |
| 90% | 10.8% | 114 MON |
| 87% | 14.6% | 155 MON |

The pool does not require any particular LTV. A lower LTV costs the desk more parked shMON and nothing else.

## 7. Which rate curve should the WMON vault hold against ushMON?

The curve belongs to the WMON vault, not to the collateral, so it applies to every WMON borrower; today that is the
desk alone. The desk holds each loan about a day and earns 0.30% per sale, so the curve's job is to pay lenders enough
to come while leaving the desk its margin. Euler's deepest WMON vault on Monad paid lenders 4.95% at 71% use on
2026-11-05 (`alphastructures/services/rebalancingBot/test/sim/exitMm.sim.ts:26-36`).

Proposed: **6% at zero use, 12% at the 90% kink, 30% cap**, deployed on a fork through the live kinky IRM factory and
read back (`curve-proposal.md`, `curve-proposal-readback.txt`):

| use | live APY | proposed APY | proposed supplier APY | desk cost per day | share of the 0.30% |
|---|---|---|---|---|---|
| 50% | 25.5% | 9.29% | 4.18% | 2.4 bps | 8% |
| 90% | 30.0% | 12.00% | 9.72% | 3.1 bps | 10% |
| 95% | 34.1% | 14.42% | 12.33% | 3.7 bps | 12% |
| 98% | 50.0% | 26.58% | 23.44% | 6.5 bps | 22% |

Factory arguments: `deploy(1847694955732363770, 451674395, 5, 3865470565, 8319516250237539940)`. Cost: at the kink
lenders earn 9.7% instead of 24.3%, and the desk keeps 90% of each sale's margin instead of 76%.

## Recommendation on issue 6

Keep 97 / 98 while the only WMON lender is us, and lower to 93 / 95 the day an outside lender joins the vault. The
first costs nothing today; the second costs the desk about 4.4 points more parked shMON per day of sales and buys the
lender one more point of rate drop before it loses anything.

Both are one governor call on the WMON vault (`setLTV`, immediate when lowering), and neither changes a contract.

## The answer to post on issue 6

The LTV was tested on a fork against the live oracle. Interest over a 30-hour hold moves the loan 9 to 14 bps and
never reaches the line at any pair from 97/98 to 87/90. The collateral and the debt are both priced from the same
MON/USD feed, so only the shMON/MON exchange-rate feed matters; it publishes shMonad's own rate once a day and sat at
most 4.1 bps under it in the last 30 days, never over. A liquidator who seizes ushMON can complete the desk's unstake
and redeem at the true rate, and on the fork it earned 3.1% at the first crossing. The exposure that remains is a fall
in shMonad's rate of 2% or more in one day; the pair stays at 97/98 while the vault's only lender is its operator and
moves to 93/95 when outside lenders join.
