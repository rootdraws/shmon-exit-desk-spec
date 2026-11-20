# 11. How much the WMON vault lends against ushMON

The WMON vault lends up to 93% of a desk's ushMON and liquidates at 95%. Its rate runs from 20% a year when idle to 30%
at 90% use and 50% when fully used. This page shows how those numbers were chosen, from measurements and fork tests.[^files]

## The result

- **93/95 leaves room for a 2% fall.** A desk becomes liquidatable only if shMonad's rate drops about 2% in a day.
  Lenders lose money only past a 5% drop.
- **Interest is not the risk.** Holding a loan 30 hours moves it only 0.09% to 0.14%, far from the line.
- **The high rate is on purpose.** It draws WMON lenders whose money is there when exits need it.
- **The cost is a cushion.** At 93%, the desk must hold 7.2% of a day's buys as its own parked shMON.

## What prices the loan

The loan and the collateral are both priced in dollars through the same MON/USD feed. A MON price move changes both
equally, so only the shMON-to-MON rate matters.

- That rate comes from Chainlink's "SHMON / MON Exchange Rate" feed, which publishes shMonad's own rate once a day.
- Over 31 days, the feed matched shMonad's rate at each update and fell at most 0.04% behind before the next one.
- It never read above shMonad's rate. So the feed can undervalue ushMON slightly, but never overvalues it.

shMON earns about 0.03% a day, 11.4% a year, while it waits in ushMON. Its MON amount is fixed once the unstake starts.

## What can push a loan over the line

**Interest cannot.** On a Monad fork, desks borrowed to the limit and held for 30 hours, longer than any unstake seen.
The debt grew 0.09% at the 30% rate and 0.14% at the 50% top rate. No loan reached its liquidation line, even with only one
point between the borrow and liquidation limits.

**A drop in shMonad's rate can,** for example from slashing. On the fork the rate was pushed down and a liquidator
stepped in:

| Limits | Liquidatable from | Liquidator's gain at first | Lenders start losing from | Lenders' loss at a 5% drop |
|---|---|---|---|---|
| 97 / 98 | a 1.02% drop | 3.07% of the debt it took | a 3% drop | 6.4% |
| 93 / 95 | a 2.11% drop | 4.05% | a 5% drop | 0.9% |

The liquidator repays the desk's WMON loan and takes its ushMON. A day later the unstake finishes and it redeems the
ushMON at shMonad's true rate, which is how it profits.

In general, with a borrow limit b and a liquidation line L, a loan becomes liquidatable once the rate drops by 1 − b/L.

## The cushion each limit needs

The pool pays 99.7% of a sale's value with WMON it borrows against the shMON it just bought. At a borrow limit below
99.7%, the desk must already hold some shMON to cover the gap:

| Borrow limit | Cushion, as a share of a day's buys |
|---|---|
| 97% | 2.8% |
| 95% | 4.9% |
| 93% | 7.2% |
| 90% | 10.8% |
| 87% | 14.6% |

A lower limit costs the desk more parked shMON and nothing else.

## The rate curve

| Use | Borrowers pay | Lenders earn | Desk's cost per day | Share of the desk's 0.30% |
|---|---|---|---|---|
| 0% | 20.0% | 0% | 0.050% | 17% |
| 50% | 25.5% | 11.5% | 0.062% | 21% |
| 90% | 30.0% | 24.3% | 0.072% | 24% |
| 98% and up | 50.0% | 44.1% | 0.111% | 37% |

At 90% use the desk keeps about 0.23% of each sale after interest. A cheaper curve, 6% idle to 12% at the kink, was
tested and dropped. It would leave the desk more margin but pay lenders too little to draw them in.

The vault keeps 10% of the interest as a fee.

[^files]: Everything is under [`evidence/ltv-study/`](evidence/ltv-study/), with blocks and dates in each file. Feed: proxy `0x2dC0b316e3d4e673C7F9A809e80a3e60b26d7774`, read through Euler adapter `0x0A75…6c6C` (25-hour limit) and the MON/USD adapter `0xe6a6…fB9d` (2-hour limit); its fit to shMonad's rate is in `feed-divergence-30d.md` and `.json`. shMON yield: `shmon-yield-30d.json`. Fork cases: `ltv-simulation.jsonl`, 24 in all. Rate curve: IRM `0xa359026aae6c26Ba90B3D3AB78Fc483Da09DBa8a`, read back in `wmon-curve.md`. The dropped curve: `curve-proposal.md`, `curve-proposal-readback.txt`. Limits on chain: `deploy.sh` `LTV_WMON_USH=(9300 9500)`, and `LTVFull` reads 9300/9500 for the live ushMON.
