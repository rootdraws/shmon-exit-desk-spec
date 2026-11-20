# 7. Market data

How much shMON leaves for MON, what it costs, and how much the routes can carry. Dollar figures use each day's MON price
unless noted.[^sources]

## How shMON leaves

Almost all shMON leaves through shMonad's own two exits. Very little trades on DEXes.

**Instant exit.** shMonad pays out at once from a pool, for a fee. Over the 30 days to 2026-11-05:

| | |
|---|---|
| Exits | 9,055 |
| MON paid out | 6.28M, about 209,000 a day |
| Fees paid | 34,157 MON, 0.54% on average |
| Exit size | median 1.85 MON, 90th percentile 220 MON, largest 547,416 MON |
| Pool size | target 6.41M MON, available 2.86M MON on average |
| The pool's fee income | 6.5% a year on its target, 14.5% on what it held |

Each month since launch:

| Month | Exits | MON paid out | $ paid out | $ sent to the slow unstake |
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
| 2026-11, 4 days | 363 | 1,429,527 | 25,644 | 87,141 |

Instant exits run 3.5M to 9.4M MON a month, about $84k to $257k. October's exit count jumped while the MON paid out
stayed small.

**Slow unstake.** It is free and takes about a day.
- 119 requests for 69.5M MON in the 30 days to 2026-11-05, and 7,331 requests for 1.49 billion MON since launch.
- Time to ready: 19.6 hours typical, 18.2 hours at the 10th percentile, 21.3 at the 90th and 21.9 at the longest.

**DEX trading,** daily average over 30 days:

| Pair | Per day |
|---|---|
| MON to USDC | $1,698,732 |
| USDC to MON | $1,651,523 |
| shMON to MON | $2,701 |
| MON to shMON | $2,369 |
| shMON to USDC | $4 |

On 2026-11-05 the MON/USDC flow split across four venues, in dollars bought and sold:

- **Uniswap v4 0.05%:** $1.51M bought, $1.59M sold.
- **PancakeSwap v3 0.05%:** $202k bought, $210k sold.
- **Uniswap v3 0.3%:** $166k bought, $221k sold.
- **Hanji book:** $95k bought, $88k sold.

## The instant exit's fee and depth

| | Low hour (10th pct) | Typical | High hour (90th pct) | Read 2026-11-19 |
|---|---|---|---|---|
| MON payable at once | 1,691,332 | 2,962,823 | 3,889,584 | 3,420,528 |
| Pool target | | 6,412,155 | | 6,577,624 |
| Fee | 0.41% | 0.55% | 0.73% | 0.485% |
| Refill after a drain, MON per hour | | 1,258 | 37,378 | |

The desk's 0.30% discount beats the instant exit's fee in at least 9 of 10 hours. shMonad holds 329.2M MON, and
1 shMON is worth 1.6544 MON.

## Capacity

**The slow unstake.** shMonad sets the limit, not the desk. An unstake above shMonad's no-delay allowance waits two extra
epochs. The desk can buy only as much shMON as it can borrow WMON against while the unstake runs. See
[05-eulerswap.md](05-eulerswap.md).

**Selling WMON for USDC through the digester.** A replay of 30 days of Monad trading, with the desk's orders one tick
off the market:

| To sell | Share of passing flow filled | Typical time | 90th percentile |
|---|---|---|---|
| $50k | 25% | 4.4 h | 7.5 h |
| $200k | 25% | 13.5 h | 23.8 h |
| $200k | 10% | 35.5 h | 46.9 h |
| $500k | 25% | 35.5 h | 46.9 h |
| $500k | 10% | 73.9 h | 99.6 h |

The digester holds only the desk's own orders, and the keeper fills them from about $3.35M a day of MON/USDC trading.

**Selling WMON at once, within 2% of the oracle.** This is the emergency sale. Each pool was tested alone on a copy of
Monad, with MON at $0.01407:

- **Uniswap v3 0.3%:** 1,041,000 MON for $14,358.
- **Uniswap v4 0.05%:** 774,000 MON for $10,668.
- **PancakeSwap v3 0.05%:** 132,000 MON for $1,820.
- **Every other pool:** under $30. Hanji had almost no bids, and Kuru refused the sales.

Each emergency sale goes to whichever of the first two pools pays more. Together they took about $25,000 within 2%.

**Borrowing USDC and USDT0.** Room before each lender's rate jumps:

| Lender | USDC | USDT0 | Note |
|---|---|---|---|
| Neverland | 118,279 | 19,273 | 85.8% and 89.1% used, rate jump at 90%, read 2026-11-19 |
| Our Euler cluster | 0 | 0 | No lenders yet, read 2026-11-20. |

**Swapping USDC and USDT0 on Curve.** On 2026-11-09:
- USDC to USDT0 paid a premium of 0.083% at $10k and 0.045% at $160k.
- USDT0 to USDC cost 0.10% at $10k and 0.19% at $160k.

A replay of a week of Curve trading shows a USDT0 sell order one blip better than Curve would fill about 63,000 to
66,500 USDT0 a day.

## The desk's return, modeled

A model of a desk with $100,000 that buys shMON at the rate less 0.30%, unstakes it and gets MON back in 19.6 hours.
It buys from outside sellers only in hours when it beats the instant exit's fee.

| Vault's own exits per month | Return a year, at 0% / 50% / 100% of outside sellers |
|---|---|
| $0 | 0.1% / 1.8% / 3.4% |
| $100k | 3.8% / 5.4% / 7.1% |
| $500k | 18.4% / 20.0% / 21.7% |
| $2M | 73.2% / 74.8% / 76.5% |

The vault's own exits drive the return, and outside sellers add a few points. For comparison, shMonad's instant exit
earns about 8% a year on its capital. These are model figures, not measured returns.[^model]

[^sources]: Read from Monad by the scripts in `alphastructures/services/rebalancingBot/test/sim/` (`instantExits.ts`, `instantExitHistory.ts`, `shmonadHistory.ts`, `unstakeTiming.ts`, `backfill.ts`, `replay.ts`, `exitMm.sim.ts`), copied under `evidence/data/`. Instant exits: `instant-exits-30d.json`, `instant-history.md`, `instant-history-daily.csv`. Unstake time: `unstake-timing-30d.md`. DEX flow: `rate-30d.md`, `rate-30d.json` (1,018,207 swaps over 721 hours), `flow-24h-2026-11-05.json`. Fee and depth: `shmonad-30d.md`, `shmonad-1d.md`. Digester replay: `rate-30d.md:16-31`. Live reads, the emergency sale depth (block 123451592) and Neverland (block 123490679): `evidence/live-reads.md`. Curve quotes: `docs/Alpha_Structures_Rebalancing_Policy.md:278`; stable replay `digester-flow/stable-fill/quote-168-*.json`. The no-delay allowance is the ushMON audit's L2.
[^model]: `evidence/data/exit-mm.md`, 2026-11-05: the borrow-to-fill design ("Design 2"), lending idle WMON at 4.95% and borrowing at 7.78% (`exitMm.sim.ts:26-36`).
