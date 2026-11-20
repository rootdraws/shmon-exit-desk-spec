# 7. Market data: how much shMON turns into MON, at what fee, through what capacity

All historical figures were read from Monad by the scripts in
`alphastructures/services/rebalancingBot/test/sim/` (`instantExits.ts`, `instantExitHistory.ts`, `shmonadHistory.ts`,
`unstakeTiming.ts`, `backfill.ts`, `replay.ts`, `exitMm.sim.ts`) and are copied under `evidence/data/` with their read
dates. Live figures are from `evidence/live-reads.md` (2026-11-19, block 123490991, unless noted). MON traded at about $0.0184 on
2026-11-04 (Uniswap v3 WMON/USDC); dollar figures use each day's price unless stated.

## The rate of shMON to MON consumption

shMonad offers two exits, and almost all shMON leaves through them rather than through a DEX.

**Instant exits (the atomic pool).** Each is an ERC-4626 `Withdraw` on shMonad paid from the pool at a fee
(`evidence/data/instant-exits-30d.json`, 30 days to 2026-11-05):

| 30 days to 2026-11-05 | |
|---|---|
| Instant exits | 9,055 |
| MON paid out | 6,283,894 MON (about 209,000 MON a day) |
| Fees paid | 34,157 MON, average 0.54% |
| Exit size median / 90th percentile / largest | 1.85 / 220 / 547,416 MON |
| Pool target / liquidity, average | 6.41M / 2.86M MON |
| Fee yield to the pool | 6.5% a year on target, 14.5% on liquidity |

By month since launch (`evidence/data/instant-history.md`):

| Month | Instant exits | Paid out (MON) | Paid out ($) | One-day unstakes requested ($) |
|---|---|---|---|---|
| 2025-12 | 863 | 6,196,943 | 151,533 | 4,664,077 |
| 2026-01 | 661 | 6,056,177 | 125,315 | 5,960,969 |
| 2026-02 | 659 | 7,655,624 | 160,854 | 2,239,537 |
| 2026-03 | 596 | 9,437,172 | 257,205 | 4,323,555 |
| 2026-04 | 735 | 7,254,730 | 221,750 | 5,360,664 |
| 2026-05 | 566 | 6,453,552 | 153,440 | 4,621,754 |
| 2026-06 | 521 | 4,326,742 | 90,515 | 861,470 |
| 2026-07 | 488 | 4,865,185 | 103,240 | 1,072,791 |
| 2026-08 | 762 | 4,905,765 | 129,789 | 2,688,335 |
| 2026-09 | 274 | 3,548,632 | 88,492 | 2,269,922 |
| 2026-10 | 8,683 | 3,788,208 | 83,699 | 1,440,955 |
| 2026-11 (4 days) | 363 | 1,429,527 | 25,644 | 87,141 |

Instant exits have run between 3.5 and 9.4 million MON a month, about $84k to $257k at each month's price. October's
exit count jumped (449 to 1,130 exits on several days) while the MON paid out stayed small.

**The slow unstake.** 119 requests for 69.5M MON in the 30 days to 2026-11-05, 7,331 requests for 1.49 billion MON
since launch (`instant-exits-30d.json`, `instant-history-daily.csv`). Request to ready: 18.2 h at the 10th percentile,
19.6 h typical, 21.3 h at the 90th, 21.9 h longest, 5 or 6 epochs of about 4 hours (`evidence/data/unstake-timing-30d.md`).

**DEX flow** (`evidence/data/rate-30d.md` and `rate-30d.json`: 1,018,207 swaps over 721 hours, blocks 111184875 to 119665718 per `backfill-30d.json`, run 2026-11-07):

| Pair | Per day, 30-day mean |
|---|---|
| MON to USDC | $1,698,732 |
| USDC to MON | $1,651,523 |
| shMON to MON | $2,701 |
| MON to shMON | $2,369 |
| shMON to USDC | $4 |

shMON itself hardly trades on DEXes. A 24-hour read of 2026-11-05 (`evidence/data/flow-24h-2026-11-05.json`) split the
MON/USDC flow as: Uniswap v4 0.05% $1.51M bought and $1.59M sold, PancakeSwap v3 0.05% $202k and $210k, Uniswap v3
0.3% $166k and $221k, the Hanji MON/USDC book $95k and $88k.

## The instant-exit fee and shMonad's pool depth

Hourly reads (`evidence/data/shmonad-30d.md`, 720 hours to 2026-11-05; `shmonad-1d.md`, 25 hours):

| | 30d low (p10) | 30d typical | 30d high (p90) | Live 2026-11-19 |
|---|---|---|---|---|
| MON payable at once | 1,691,332 | 2,962,823 | 3,889,584 | 3,420,528 |
| Pool target | 6,053,067 (first row) | 6,412,155 (30-day average, `instant-exits-30d.json`) | 6,256,184 (last row) | 6,577,624 |
| Instant-exit fee | 0.41% | 0.55% | 0.73% | 0.4850% |
| Refill after a drain, MON per hour | | 1,258 | 37,378 | |

The desk's 0.30% discount sits under the instant exit's 10th-percentile hour of the last 30 days read (the file gives percentiles, not the lowest hour). shMonad holds 329.2M MON
in total (`totalAssets`, live), and 1 shMON is worth 1.6544 MON.

## Capacities

**Digesting shMON through the one-day unstake** is bounded by shMonad's own rules, not by the desk: a request above
shMonad's no-delay allowance waits two more epochs (audit L2). The desk's throughput is then bounded by the WMON it can
borrow or hold while the unstake runs (see [05-eulerswap.md](05-eulerswap.md)).

**Digesting WMON into USDC (the digester).** Replays of 30 days of Monad flow with five rungs one tick off the market
(`evidence/data/rate-30d.md`, lines 16-31):

| Inventory to sell | Share of passing flow filled | Typical time to finish | 90th percentile |
|---|---|---|---|
| $50k | 25% | 4.4 h | 7.5 h |
| $200k | 25% | 13.5 h | 23.8 h |
| $200k | 10% | 35.5 h | 46.9 h |
| $500k | 25% | 35.5 h | 46.9 h |
| $500k | 10% | 73.9 h | 99.6 h (2 of 224 starts never finished) |

The digester pool itself is empty between orders; its depth is the desk's resting orders, and the keeper fills them
from the MON/USDC flow of about $3.35M a day (`docs/Alpha_Structures_Digester.md:59`, `rate-30d.md`). A 24-hour read put the
digester's buy flow at $82,178 an hour, with 10% fills at $8,218 an hour
(`alphastructures/services/rebalancingBot/test/sim/withdrawal-sim.md:1`, undated in the file).

**Selling WMON as a taker within 2% (the emergency sale).** Each pool was measured alone on a copy of Monad at block
123451592, with MON at $0.01407. About $27,000 of MON sells within 2% of the oracle across all WMON/USDC pools:
* Uniswap v3 0.3%: 1,041,000 MON for $14,358.
* Uniswap v4 0.05%, where the emergency sale sells: 774,000 MON for $10,668.
* PancakeSwap v3 0.05%: 132,000 MON for $1,820.
* Every other pool took under $30. The Hanji book had almost no bids, and the Kuru book refused the test sales.

Each emergency sale goes to whichever of those two pools pays more. Together they took about $25,000 within 2% at that depth.

**Borrowing USDC and USDT0 (what the vaults can raise against shMON).** Room before each lender's rate kink, live
2026-11-19:

| Lender | USDC room | USDT0 room | Note |
|---|---|---|---|
| Neverland | 118,279 | 19,273 | 85.8% and 89.1% used, kink 90% |
| Our Euler cluster | 0 | 0 | borrow caps of 4.5M each, but no lenders yet (`cash()` 0 on both, read 2026-11-20) |

**Moving USDC to USDT0 and back** (Curve, live quotes of 2026-11-09, `docs/Alpha_Structures_Rebalancing_Policy.md:278`):
USDC to USDT0 pays a premium of +0.083% at $10k and +0.045% at $160k; USDT0 to USDC costs 0.10% at $10k and 0.19% at
$160k; the pool held $368k USDC and $799k USDT0. A replay of 168 hours of Curve USDC to USDT0 buys shows a resting
USDT0 ask one blip better than Curve would sell about 63,000 to 66,500 USDT0 a day (`digester-flow/stable-fill/quote-168-*.json`,
2026-11-06).

## The desk's economics model (`evidence/data/exit-mm.md`, 2026-11-05)

Yearly return on $100,000 for a desk that buys shMON at the fee-free rate less a discount, sends it through the unstake
and gets MON back after 19.6 hours. "Design 2" is the borrow-to-fill EulerSwap pool, lending idle WMON at 4.95% and
borrowing at 7.78% (`exitMm.sim.ts:26-36`; the rates of Euler's deepest WMON vault on Monad that day; the md rounds it to 7.8%). Outside flow is filled only in hours
when the discount beats the live instant-exit fee.

| Discount | Vault's own exits per month | Design 2 return per year, at 0% / 50% / 100% of outside flow |
|---|---|---|
| 0.3% | $0 | 0.1% / 1.8% / 3.4% |
| 0.3% | $100k | 3.8% / 5.4% / 7.1% |
| 0.3% | $500k | 18.4% / 20.0% / 21.7% |
| 0.3% | $2M | 73.2% / 74.8% / 76.5% |

The file's stated benchmark: "shMonad's instant exit, ~8% a year on its capital since launch." These are model outputs
on 2026-11-05 data, not measured returns. The desk's own exits dominate the return; outside flow adds a few points.
