# 5. EulerSwap: the public shMON buyer

Each exit desk owns an EulerSwap pool that buys anyone's shMON for WMON at shMonad's rate less 0.30%. Routers and
aggregators reach it as an ordinary Uniswap v4 pool.[^source]

| Pool | Address |
|---|---|
| Delta One desk | [0x56aEAB6F7a33573CdEF9B59a8d330F0e1b2128A8](https://monadscan.com/address/0x56aEAB6F7a33573CdEF9B59a8d330F0e1b2128A8) |
| Delta Neutral desk | [0x19241Ff986e1dFE848A8C2a8AC2C21C0E7cFe8a8](https://monadscan.com/address/0x19241Ff986e1dFE848A8C2a8AC2C21C0E7cFe8a8) |

## How an EulerSwap pool works

An EulerSwap pool trades from an Euler account instead of holding its own tokens.

1. A seller sends one token in.
2. The pool pays the other token out of the account's deposits in Euler, and borrows the rest.
3. The token that came in repays any debt in that token, and the rest is deposited for the account.
4. The account must still be within its loan limit after the swap, or the swap fails.

Each pool is also a Uniswap v4 hook, so any router that reaches Uniswap v4 can trade with it. An outside contract can
set the fee on every swap, and can refuse a swap with a fee of 100%.

## How the desk's pool works

When someone sells shMON to the pool:

1. The pool deposits the shMON into ushMON for the desk, where it becomes the desk's collateral.
2. It pays the seller in WMON, from the desk's own WMON first, then borrowed from the cluster's WMON vault.
3. The bot sends that shMON into the unstake.
4. A day later the unstake returns WMON, which repays the loan. The desk keeps the 0.30%.

- **Price.** The pool's base price sits 2% above shMonad's rate. On every sale the desk charges a fee that brings the
  price down to the rate less 0.30%, so a seller always gets that price.
- **Price reset.** shMON's rate rises every day with staking yield. When it comes within 1% of the base price, the pool
  resets the base to 2% above the rate again.
- **Buys only.** The pool refuses WMON in.
- **Leavers first.** While the vault has an unpaid withdrawal batch, the pool quotes nothing, so the desk's borrowing
  room goes to the vault's own leavers.

On a fork, a seller of 60.48 shMON worth 99.99 MON was quoted 99.69 WMON, 0.30% under.[^fork]

| Setting | Value | What it does |
|---|---|---|
| Tokens | shMON in, WMON out | The pool only buys shMON. |
| shMON goes to | ushMON `0xa753…8C5e` | Both desks share this vault, each on its own ledger. |
| WMON comes from | the WMON vault `0xE452…0eaf` | The desk's own WMON is used first, then a loan. |
| Account and pricing | the desk | The desk holds the collateral and the loan, and sets every sale's price. |
| Base price | shMonad's rate × 1.02 | The fee brings it down to the rate less 0.30%. |
| Curve | flat | Every sale gets the same price, whatever its size. |
| Most it can pay out | 100,000,000 WMON | A ceiling far above any real sale. |

## What capital the pool needs

The pool can only pay what all of these allow:

- **The desk's own WMON** in the WMON vault, used first.
- **The WMON vault's cash:** what lenders have supplied and nobody has borrowed yet.
- **The WMON vault's borrow cap,** less what is already borrowed.
- **The desk's loan limit:** the WMON vault lends up to 93% of the desk's ushMON, and liquidates at 95%.

The loan limit means the desk must hold some shMON in ushMON before it buys. A sale adds collateral worth 100 and a loan
worth 99.7, but the vault lends only 93 against 100. So the desk must already hold about 7.2% of a day's buys as parked
shMON, or the borrow fails. Each desk parks 80 MON worth of shMON for this.

To buy $100k of shMON in one unstake cycle:

| Need | Amount | Why |
|---|---|---|
| WMON borrowed | $99.7k | The pool pays 99.7% of the shMON's value. |
| WMON lenders have supplied | about $111k | At 90% use the WMON vault stays at its rate kink, 30% a year. At 100% use it charges 50%. |
| shMON parked by the desk | about $7.2k | The 7.2% the loan limit needs. |

Each need grows in a straight line with the target.

The desk earns the 0.30% discount less a day of interest on the loan and the gas of the park and settle calls. A model
puts that at 1.8% to 3.4% a year on $100k of capital from outside sellers alone. It rises to 18% to 22% when the
vault's own exits of $500k a month also pass through. Those are model figures, not measured returns.[^model]

## The keeper's shMON arbitrage

The keeper buys shMON wherever it sells for less than our pools pay, and sells it into our pools.[^arb]
* The keeper buys on Curve, Uniswap v3 or PancakeSwap v3, then sells to the desk's pool in one router call.
* The pool pays with WMON it borrows from the cluster, and the shMON unstakes for a day to repay that loan.
* The arbitrage never runs while any desk has leavers waiting.
* It always leaves the WMON vault a reserve, the larger of half its unlent WMON or the last leaver payout.
* It sends each trade to the desk whose pool can take more, and that desk keeps the profit as WMON.

## Replacing a pool

A pool's tokens and vaults cannot change, so a new ushMON needs a new pool. The admin Safe moves the desk's Euler account
to the new vaults with `moveEulerAccount`, which works only when the desk has no loan and no parked shMON. It then opens
the new pool with `deployMmPool`.[^retire]

## EulerSwap on Monad

Euler had not deployed EulerSwap on Monad, so the team deployed it.

| Contract | Address |
|---|---|
| Factory | [0xDD13DCECd0Da21158507385867d24ec56BF80484](https://monadscan.com/address/0xDD13DCECd0Da21158507385867d24ec56BF80484) |
| Periphery, for swaps and quotes | [0xA4cBd6e277B7a531fF8525877a17bD31Cf28619B](https://monadscan.com/address/0xA4cBd6e277B7a531fF8525877a17bD31Cf28619B) |
| Pool implementation | 0xdEDc0388113450eb380817a8770c853C660Caf6d |
| Protocol fee config, run by the AlphaGrowth Safe `0x4f89…7Fd3C` | 0x53fBE13F8852cc9AcB5750375112346EC76532d7 |
| Management | 0xA25142Fc5d24675C1A72f418a3239782F85E4533 |
| Uniswap v4 PoolManager | 0x188d586Ddcf52439676Ca21A244753fA19F9Ea8e |

[^source]: [euler-xyz/euler-swap](https://github.com/euler-xyz/euler-swap) at [`a8493f8`](https://github.com/euler-xyz/euler-swap/tree/a8493f89764ce69a05915559d9061781b9a96f24), EulerSwap v2 (BUSL-1.1). The copy under `ag-euler/contracts/eulerswap-mm-monad/src/` matches it byte for byte in all 28 files. Swap order `EulerSwap.sol:122-153`; payout `FundsLib.sol:41-111`; quote limits `QuoteLib.sol:120-195`; fee hook `IEulerSwapHookTarget.sol:11`; v4 hook `UniswapHook.sol:36-54`. Addresses in `deployed-143.env`.
[^fork]: `evidence/rehearsal-fork.log`. The desk's price and reset: `ShMonadExitAdapter.sol` `getFee` line 970 and `afterSwap` line 987, `MM_DISCOUNT_BPS = 30`, `CEILING_BPS = 200`, `RESET_BPS = 100`. Settings read with `getDynamicParams` and `getReserves`.
[^model]: `evidence/data/exit-mm.md`. Loan limit `deploy.sh:57,193`; rate curve `deploy.sh:49`; borrow cap `deploy.sh:54`; the 7.2% need was found on the fork in `evidence/hardhat-fork-ush2.txt`.
[^arb]: `alphastructures/services/digesterKeeper/src/arb.ts:4-13,42-46`.
[^retire]: `ShMonadExitAdapter.sol` `moveEulerAccount` line 510 and `deployMmPool` line 952.
