# 3. The exit desk

Each vault has an exit desk. It turns the vault's shMON into USDC without the slippage of today's shMON pools, and
without waiting a day for the unstake.[^contract]

## How it works

1. The desk parks shMON in ushMON on the Euler cluster and starts the unstake. The parked shMON is Euler collateral.
2. It borrows WMON against it, at up to 93% of value.
3. It sells the WMON for USDC through the **digester**, its own Uniswap v4 pool, with small limit orders one tick off
   the market. A keeper fills them from flow on other WMON/USDC venues.
4. The USDC goes home and repays the vault's loan.
5. A day later the unstake returns WMON. The desk repays the WMON loan in one Euler batch, then restakes any leftover
   WMON as shMON and sends it home.

## The digester

The desk rests five sell orders at +1 to +5 ticks and five buy orders at −2 to −6 ticks. An order the market leaves 20
ticks behind for 3 minutes is cancelled and placed again. The keeper tries the whole order, then ½, ¼, ⅛ and 1/16 of
it.[^digester]

| Piece | Address | Note |
|---|---|---|
| Hook | [0x94Df2bffA788BBd918179f4CCB5A22DbAD7e1040](https://monadscan.com/address/0x94Df2bffA788BBd918179f4CCB5A22DbAD7e1040) | OpenZeppelin `LimitOrderHook` (uniswap-hooks 1.3.0) |
| Pool | poolId `0x3957bb3c02c319231713c06853de9bfc8e7d1aaa276873cd65fc028efc0b1314` | WMON/USDC, 0.01% fee, tick spacing 1, PoolManager `0x188d586Ddcf52439676Ca21A244753fA19F9Ea8e` |
| Router | [0xE1fe1Ea6677Ea56eEFD381045AAcf86D541C3776](https://monadscan.com/address/0xE1fe1Ea6677Ea56eEFD381045AAcf86D541C3776) | Owned by the keeper key. Fills orders with the gain to the vault, and runs the shMON arbitrage with the gain to the desk. |
| Keeper wallet | 0xEE51d642304f8F0b272Fc79cf851CE76ee24c3A7 | Runs in the `monad-digester` container, and fills only for a gain of $0.01 or more. |

## What else the desk does

- **Public buyer.** The desk owns an EulerSwap pool that buys anyone's shMON for WMON at shMonad's rate less 0.30%.
  Routers and aggregators reach it as an ordinary Uniswap v4 pool. It pays with WMON the desk borrows against the shMON
  it just bought. See [05-eulerswap.md](05-eulerswap.md).
- **Leavers first.** While the vault has an unpaid withdrawal batch, the pool quotes nothing, so the desk's borrowing
  room goes to the vault's own leavers.
- **One ushMON for both desks.** Each desk's unstakes and returned WMON stay on its own ledger, so one desk never takes
  the other's WMON. See [04-ushmon.md](04-ushmon.md).
- **Emergency sale.** At a 65% loan, the desk may sell WMON up to 2% below the oracle price instead of 1%, so the sale
  fills faster. The bot then sells in one transaction, and the loan drops at once:
  1. The vault hands the desk shMON.
  2. The desk borrows WMON against it.
  3. The desk sells the WMON for USDC.
  4. The vault repays its loan with the USDC.
- **During a pause.** The desk still parks, unstakes, borrows and places orders. It stops selling shMON into bids and
  buying from stray asks. A full halt stops everything.

## Liquidity map

![Exit desk liquidity map, from the production configs, the code and the chain, 2026-11-19](figures/exit-desk-liquidity-map.svg)

Leavers' shMON sells on Curve first, and the rest goes the borrow route. The desk sells WMON for USDC at the market's own
pace. Both vaults share every venue.

| Venue | Address or pool id | Pair, fee | What the desk does there |
|---|---|---|---|
| Curve MON LSTs | `0x74d80ee400d3026fdd2520265cc98300710b25d4` | WMON / shMON, 0.01% | The vault sells leavers' shMON here first, any amount over $10, while the average cost stays within 0.15% of shMonad's rate. The WMON goes to the desk. The arbitrage keeper also buys cheap shMON here. |
| EulerSwap pool, Delta One | `0x56aEAB6F7a33573CdEF9B59a8d330F0e1b2128A8` | shMON / WMON | The Delta One desk's pool. It buys anyone's shMON at shMonad's rate less 0.30% and pays in WMON. |
| EulerSwap pool, Delta Neutral | `0x19241Ff986e1dFE848A8C2a8AC2C21C0E7cFe8a8` | shMON / WMON | The Delta Neutral desk's pool. It works the same way. |
| Digester | `0x3957bb3c02c319231713c06853de9bfc8e7d1aaa276873cd65fc028efc0b1314` | WMON / USDC, 0.01% | The desk's own pool. Its buy and sell orders rest here. The desk also fills other traders' stray orders here. |
| Exit bid pool, USDC | `0xEA93Cb7Af4bcdAfF8312BEe55dF369970070C4a9` | shMON / USDC, 0.01% | Holds standing bids for shMON. The desk would sell shMON into them, this pool first. It holds no bids today. |
| Exit bid pool, WMON | `0xB03b966811eBd2E481a77d2ce118f8fA2c5fD716` | shMON / WMON, 0.01% | Holds standing bids for shMON. The desk would sell shMON into them after the USDC pool. It holds no bids today. |
| Uniswap v4 MON/USDC 0.05% | `0x18a9fc874581f3ba12b7898f80a683c66fd5877fd74b26a85ba9a3a79c549954` | MON / USDC, 0.05% | The digester's orders are priced off this pool. The keeper fills against it. In the emergency sale the desk sells borrowed WMON here. Its trades count toward the desk's selling pace. |
| Uniswap v4 MON/USDC 0.001% | `0x77169f9b5da147c4952896072951e84e4f4aad7b4d68ebe626ba358ed4e9c1e6` | MON / USDC, 0.001% | Its trades count toward the desk's selling pace. |
| Uniswap v3 | `0x659bD0BC4167BA25c62E05656F78043E7eD4a9da` | WMON / USDC, 0.3% | The keeper fills against it. In the emergency sale the vault sells borrowed WMON here when it pays more than the v4 pool. Its trades count toward the desk's selling pace. |
| PancakeSwap v3 | `0x63e48B725540A3Db24ACF6682a29f877808C53F2` | WMON / USDC, 0.05% | The keeper fills against it. Its trades count toward the desk's selling pace. |
| PancakeSwap v3 | `0xD5b70d70CBE6C42bCD1aaa662A21673A83f4615b` | AUSD / WMON | Its trades count toward the desk's selling pace. |
| Uniswap v3 shMON | `0x1f86a9F2441caC9B942CFb5445530CdBB28717eD`, `0xc27EEbd865051020F9BDEb12398790f356a7B684` | shMON / WMON, 0.01% and 0.3% | The arbitrage keeper buys cheap shMON here. |
| PancakeSwap v3 shMON | `0x66553f37ea7FdC092193dCeFaA7a32F94B1bE4d0` | shMON / WMON, 0.01% | The arbitrage keeper buys cheap shMON here. |
| Hanji book | `0xc35b1ca1a2c398a21df5783b3a5ea6a2d56f298f` | MON / USDC | The keeper fills against it when no pool can. Its trades count toward the desk's selling pace. |
| Kuru book | `0xc9dE998e272d59a19CEA3783C8dd44f87A86405D` | MON / USDC | Its trades count toward the desk's selling pace. |
| Stable desk pool | EulerSwap USDC/USDT0 on vaults `0x5aB0…0948` and `0xD664…963E` | USDC / USDT0 | Moves the vault's debt between USDC and USDT0. Its price comes from Curve `0x9426…91ab`. |
| Euler WMON vault | `0xE4522663752AC47516e39aD11d3780a116850eaf` | WMON | Lends the desk WMON against its ushMON. It lends up to 93% of value and liquidates at 95%. |
| shMonad | `0x1B68626dCa36c7fE922fD2d55E4f631d962dE19c` | shMON | Unstakes shMON to MON in about a day, and sets shMON's rate. |

## The contract

The bot's server key calls most functions. The admin Safe sets the desk up, and the vault's controller moves money in
and out.[^lines]

| Group | Functions | Who calls them |
|---|---|---|
| Setup | `initialize`, `moveEulerAccount` (only with no debt or parked shMON), `setPool`, `setV4Pool`, `setHanjiBook`, `rescueTokens` | admin Safe |
| Money in and out | `deposit`, `returnToController` | controller, bot |
| shMonad unstake | `requestUnstake`, `completeUnstake` | bot |
| Resting orders, each checked against the oracle | place and close on Uniswap v3, Uniswap v4, Hanji and the digester | bot |
| Selling shMON into bids, never under the oracle less the swap limit | `sellShmonV4` | bot |
| Euler account | `parkShmon`, `unparkShmon`, `borrowWmon`, `repayWmon`, `settleEulerUnstake`, `restakeWmon` | bot |
| Trading in the digester with the desk's own WMON and USDC | `sellMonV4`, `buyMonV4` | bot |
| Emergency sale in one call | `fillFromController` | controller |
| EulerSwap pool | `deployMmPool`, `getFee`, `leaversWaiting`, `afterSwap` | admin Safe, the pool |
| Halts | `whenNotHalted`, `whenNotPaused` | guardian |

## The desk's steps

The bot takes one desk step per tick, the first that has work. It leaves anything under $10 alone.[^steps]

| # | When | Step |
|---|---|---|
| 1 | An order filled, or the emergency sale is running | Close the order. |
| 2 | The desk's own unstake has matured | Collect it. |
| 3 | Leavers are waiting | Close a buy order, and send USDC and leftovers of $10 to $1,000 home. |
| 4 | A ushMON unstake matured, or WMON is back, while a loan or parked shMON is open | Redeem the desk's own WMON and repay the loan. |
| 5 | No loan, and over $10 of WMON on the desk | Restake it as shMON and send it home. |
| 6 | A withdrawal batch is waiting, or the loan has shMON not yet unstaking | Park and unstake what the loan needs. |
| 7 | An order is stale, or sits inside the price | Cancel it. |
| 8 | Over $10 of WMON | Sell into stray bids, or rest a sell order. |
| 9 | Over $10 of USDC to buy with | Buy from stray asks, or rest a buy order. |
| 10 | shMON on the desk and a bid standing | Sell into the exit bid pools, USDC first. |
| 11 | Over $10 of shMON left | Start the unstake. |

[^contract]: `alphastructures/contracts/adapters/venue/ShMonadExitAdapter.sol`, a UUPS proxy per vault, `VERSION = 1_10_00` (line 307); `VERSION()` reads 11000 on both live desks, 2026-11-20.
[^digester]: `alphastructures/docs/Alpha_Structures_Digester.md:31-57`; the router's owner read on chain 2026-11-20.
[^lines]: Line numbers in the live 1.10.0 source: `initialize` 449, `moveEulerAccount` 510, `deposit` 582, `requestUnstake` 594, `placeLimitOrder` 1109, `sellShmonV4` 755, `parkShmon` 790, `settleEulerUnstake` 920, `sellMonV4` 826, `fillFromController` 860, `deployMmPool` 952, `leaversWaiting` 979, `whenNotHalted` 552, `whenNotPaused` 557; version history at lines 285-306.
[^steps]: `alphastructures/services/rebalancingBot/src/planner/exitDesk.ts`; `DESK_DUST_USD = 10` at line 24.
