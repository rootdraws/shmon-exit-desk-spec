# 3. The exit desk

Contract: `alphastructures/contracts/adapters/venue/ShMonadExitAdapter.sol`, a UUPS proxy per vault, `VERSION = 1_10_00`
(line 307), live on both production desks (`VERSION()` reads 11000, 2026-11-19). Bot: `services/rebalancingBot/src/planner/exitDesk.ts`.

## What it does

shMON to USDC needs a pathway with greater capacity and less slippage than what is currently available onchain. 

Each vault has an Exit Desk, which rests small limit orders in our own Uniswap v4 pool, one tick off the market.
wMON/USDC pools on Monad are monitored by websocket, so when they trade past our orders, Uniswap v4 Flash accounting is used to execute the trade.

| Digester piece | Address | Note |
|---|---|---|
| Hook | [0x94Df2bffA788BBd918179f4CCB5A22DbAD7e1040](https://monadscan.com/address/0x94Df2bffA788BBd918179f4CCB5A22DbAD7e1040) | OpenZeppelin `LimitOrderHook` (uniswap-hooks 1.3.0), CREATE2 |
| Pool | poolId `0x3957bb3c02c319231713c06853de9bfc8e7d1aaa276873cd65fc028efc0b1314` | WMON/USDC, fee 100, tick spacing 1, PoolManager `0x188d586Ddcf52439676Ca21A244753fA19F9Ea8e` |
| Router v2 | [0xE1fe1Ea6677Ea56eEFD381045AAcf86D541C3776](https://monadscan.com/address/0xE1fe1Ea6677Ea56eEFD381045AAcf86D541C3776) | Owned by the keeper key (read 2026-11-19). Fills orders, sending the gain to the vault, and runs the shMON arbitrage, sending the gain to the desk. |
| Keeper wallet | 0xEE51d642304f8F0b272Fc79cf851CE76ee24c3A7 | container `monad-digester`, minimum gain $0.01 |

The ladder is five rungs one tick apart. It sells at +1 to +5 ticks and buys at −2 to −6, and a rung left 20 ticks behind
for 3 minutes is re-laddered. The keeper tries sizes 1, ½, ¼, ⅛ and 1/16 of an order (`Digester.md:31-57`).

**The borrow route (v1.4.0, 2026-11-06).** The desk parks shMON in ushMON, its Euler collateral, and starts the unstake.
It borrows WMON against it at up to 93% of value and sells the WMON through the digester. The USDC goes home to repay.
A day later the unstake returns WMON, and the desk repays the loan in one Euler batch (`settleEulerUnstake`). Leftover
WMON is restaked as shMON and sent home (`restakeWmon`).

**The public buyer (v1.4.0).** The desk owns an EulerSwap pool that buys shMON at shMonad's live rate less 0.30%
(`MM_DISCOUNT_BPS = 30`), and is that pool's pricing hook. See [05-eulerswap.md](05-eulerswap.md).

**The priority rule (v1.7.0, 2026-11-16).** While the vault has an unpaid withdrawal batch, the pool quotes nothing, so
the desk's borrowing room serves the vault's own leavers first (`leaversWaiting()`). Root, 2026-11-16: "build the
priority rule into the desk".

**One vault for both desks (v1.8.0, 2026-11-17).** Root, 2026-11-17: "it looks suspicious enough having ushMON as
collateral, But ushMONdo and ushMONdn Seems like a bit excessive." Both desks park in one ushMON (v4 since 2026-11-18,
[04-ushmon.md](04-ushmon.md)), which keeps each desk's unstakes and returned WMON on that desk's own ledger. The settle
redeems only `wmonRedeemable(desk)`, so one desk never takes the other's WMON. `unparkShmon(shares)` brings parked shMON
back to the desk.

**The emergency sale (v1.9.0, 2026-11-18, and v1.10.0, 2026-11-19).** Root, 2026-11-18: "we should not obstruct our way
to in one tx decreasing LTV through borrow-to-fill and then a taker wMON to USDC order".
* Paused, the desk still parks, unstakes, borrows and places orders. Only a full halt stops them.
* While the loan is at or over 65%, the desk's WMON sale may fill up to 2% under the oracle, instead of 1%.
* The controller can hand the desk shMON in one call (`fillFromController`). The desk parks it, borrows WMON, and sells
  it into the v4 pool or sends it home for Uniswap v3. The controller repays the loan in the same transaction.

## Liquidity map

![Exit desk liquidity map, from the production configs, the code and the chain, 2026-11-19](figures/exit-desk-liquidity-map.svg)

Leavers' shMON sells on Curve first, and the rest goes the borrow route. The desk sells WMON for USDC through its digester
ladder at the market's own pace, never more than 1% under the oracle, or 2% while the loan is over 65%. Both vaults share
every venue.

| Venue | Address or pool id | Pair, fee | What the desk does there |
|---|---|---|---|
| Curve MON LSTs | `0x74d80ee400d3026fdd2520265cc98300710b25d4` | WMON / shMON, 0.01% | The vault sells leavers' shMON here first, any amount over $10, while the average cost stays within 0.15% of the rate; the arbitrage also buys here. |
| EulerSwap pool, Delta One | `0x56aEAB6F7a33573CdEF9B59a8d330F0e1b2128A8` | shMON / WMON | Buys anyone's shMON at rate less 0.30%, paid with borrowed WMON. |
| EulerSwap pool, Delta Neutral | `0x19241Ff986e1dFE848A8C2a8AC2C21C0E7cFe8a8` | shMON / WMON | Same, for its desk. |
| Digester | `0x3957bb3c02c319231713c06853de9bfc8e7d1aaa276873cd65fc028efc0b1314` | WMON / USDC, 0.01%, tick 1, hook `0x94Df2bffA788BBd918179f4CCB5A22DbAD7e1040` | Rests five sell rungs and five buy rungs; hits stray bids and asks. In the emergency sale it takes borrowed WMON as a taker. |
| Exit bid pool, USDC | `0xEA93Cb7Af4bcdAfF8312BEe55dF369970070C4a9` | shMON / USDC, 0.01% | Would take shMON into standing bids; empty today. |
| Exit bid pool, WMON | `0xB03b966811eBd2E481a77d2ce118f8fA2c5fD716` | shMON / WMON, 0.01% | Would take shMON into standing bids; empty today. |
| Uniswap v4 MON/USDC 0.05% | `0x18a9fc874581f3ba12b7898f80a683c66fd5877fd74b26a85ba9a3a79c549954` | MON / USDC, 0.05%, tick 10 | The ladder's reference price; keeper prices fills here; flow counted. |
| Uniswap v4 MON/USDC 0.001% | `0x77169f9b5da147c4952896072951e84e4f4aad7b4d68ebe626ba358ed4e9c1e6` | MON / USDC, 0.001%, tick 1 | Flow counted; rests here only without a digester. |
| Uniswap v3 | `0x659bD0BC4167BA25c62E05656F78043E7eD4a9da` | WMON / USDC, 0.3% | Keeper prices fills here; flow counted. In the emergency sale the vault sells borrowed WMON here when the v4 pool falls 2% short. |
| PancakeSwap v3 | `0x63e48B725540A3Db24ACF6682a29f877808C53F2` | WMON / USDC, 0.05% | Keeper prices fills here; flow counted. |
| PancakeSwap v3 | `0xD5b70d70CBE6C42bCD1aaa662A21673A83f4615b` | AUSD / WMON | Flow counted; rests here only without a digester. |
| Uniswap v3 shMON | `0x1f86a9F2441caC9B942CFb5445530CdBB28717eD`, `0xc27EEbd865051020F9BDEb12398790f356a7B684` | shMON / WMON, 0.01% and 0.3% | The arbitrage buys cheap shMON here. |
| PancakeSwap v3 shMON | `0x66553f37ea7FdC092193dCeFaA7a32F94B1bE4d0` | shMON / WMON, 0.01% | The arbitrage buys cheap shMON here. |
| Hanji book | `0xc35b1ca1a2c398a21df5783b3a5ea6a2d56f298f` | MON / USDC | Flow counted; keeper's last resort for a fill. |
| Kuru book | `0xc9dE998e272d59a19CEA3783C8dd44f87A86405D` | MON / USDC | Flow counted only. |
| Stable desk pool | EulerSwap USDC/USDT0 on vaults `0x5aB0…0948` and `0xD664…963E` | USDC / USDT0 | Moves the vault's debt between the two stables; priced off Curve `0x9426…91ab`. |
| Euler WMON vault | `0xE4522663752AC47516e39aD11d3780a116850eaf` | WMON | Lends the desk WMON against its ushMON at 93/95. |
| shMonad | `0x1B68626dCa36c7fE922fD2d55E4f631d962dE19c` | shMON | The slow unstake, about a day, and the rate. |

## The contract, by group (line numbers in the live 1.10.0 source)

| Group | Functions | Who |
|---|---|---|
| Setup | `initialize` 449, `initializeV1_1` 468, `initializeV1_4` 487, `initializeV1_5` 502, `moveEulerAccount` 510 (reverts `MarketMakerBusy` with any debt or parked shares), `setPool` 1176, `setV4Pool` 1181, `setHanjiBook` 1186, `rescueTokens` 1199, `_authorizeUpgrade` 1482 (VERSION must rise) | admin Safe |
| Funds in and out | `deposit` 582 (controller only), `returnToController` 1165 | controller, executor |
| shMonad unstake | `requestUnstake` 594, `completeUnstake` 601 | executor |
| Resting orders | v3 `placeOrder` 616 / `closeOrder` 632; v4 `placeV4Order` 672 / `closeV4Order` 698; Hanji `placeHanjiOrder` 1052 / `claimHanjiOrder` 1078; digester `placeLimitOrder` 1109 / `withdrawLimitOrder` 1139 / `cancelLimitOrder` 1149 | executor, all checked against the oracle |
| Selling shMON into bids | `sellShmonV4` 755, floor at the oracle less the swap limit | executor |
| Euler account | `parkShmon(shmon, unstake)` 790, `unparkShmon(shares)` 799, `borrowWmon` 811, `repayWmon` 817, `settleEulerUnstake` 920, `restakeWmon` 943, view `getEulerPosition` 1002 | executor |
| Digester with own funds | `sellMonV4` 826, `buyMonV4` 891 | executor |
| Borrow-to-fill | `fillFromController` 860 | controller |
| EulerSwap pool | `deployMmPool` 952 (admin; requires `supplyVault0 == unstakeVault`, `eulerAccount == swapHook == this`), `getFee` 970, view `leaversWaiting` 979, `afterSwap` 987 (pool only) | admin, pool |
| Halts | `whenNotHalted` 552 stops every executor and controller function at a full halt. `whenNotPaused` 557 also stops `sellShmonV4` and `buyMonV4` while paused. | guardian |

Version history (lines 285-306):
* v1.1.0 adds Uniswap v4 and Hanji, and v1.1.1 lets a second placement add to a listing.
* v1.4.0 adds the Euler account and the EulerSwap pool.
* v1.5.0 moves the account to the 2026-11-09 cluster and retires the old pool.
* v1.6.0 lets the settle skip a failed `completeUnstake`, and adds `buyMonV4` (audit 2026-11-10 H2, H3, H5, H10).
* v1.7.0 adds the priority rule, at 0xBE243F5e4215720080929eeCfe77047D2Fd2a410.
* v1.8.0 shares one ushMON between both desks, at 0xDF9515a5d2f68B12a4fAFc44e518B13751A1c3B2.
* v1.9.0 runs the exits while paused and allows the 2% sale over 65%, at 0x959FA2e2ab953B1C2cCE71c036Aafbf584409c16.
* v1.10.0 adds `fillFromController`, at 0x74eCd223208D812098487D4090d964005370BDc7, live on both desks since 2026-11-19.

## The desk's step order, one step per tick

Bot: `services/rebalancingBot/src/planner/exitDesk.ts`. Every step is gated by `DESK_DUST_USD = 10` (planner line 24):
the bot leaves anything under $10 alone.

| # | When | Step |
|---|---|---|
| 1 | an order filled, or every order while the emergency sale runs | close it |
| 2 | the desk's own unstake matured | `completeUnstake` |
| 3 | withdrawing | close a buy rung; send a leftover between $10 and $1,000 home with no rung open; send USDC home |
| 4 | a ushMON unstake matured, or over $10 of WMON is back, with a loan or parked shMON | `settleEulerUnstake`: redeem the desk's own WMON, repay |
| 5 | no loan and over $10 of WMON on the desk | `restakeWmon`: back to shMON, home |
| 6 | a batch is open, or the loan has shMON not yet unstaking | `parkShmon`: deposit and unstake what the loan needs |
| 7 | a rung is stale or rested inside the price | cancel it |
| 8 | over $10 of WMON | sell into stray bids, else rest a sell rung |
| 9 | over $10 of USDC to buy with | buy from stray asks, else rest a buy rung |
| 10 | shMON on the desk and a bid standing | `sellShmonV4` into the exit pools, USDC first |
| 11 | over $10 of shMON left | `requestUnstake` |
| | paused | every step runs, except selling shMON into bids and buying from stray asks |
