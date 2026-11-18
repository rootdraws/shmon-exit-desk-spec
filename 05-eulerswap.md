# 5. EulerSwap: the public shMON buyer

Source: [euler-xyz/euler-swap](https://github.com/euler-xyz/euler-swap) at
[`a8493f8`](https://github.com/euler-xyz/euler-swap/tree/a8493f89764ce69a05915559d9061781b9a96f24) (2026-10-25), Euler Labs'
EulerSwap v2 (`EulerSwap.sol:16` `curve = "EulerSwap v2"`, BUSL-1.1). The copy under
`ag-euler/contracts/eulerswap-mm-monad/src/` matches that commit byte for byte in all 28 files (checked by blob hash
on 2026-11-16), so every `src/...` line number below is an upstream line number: for example
[`libraries/FundsLib.sol`](https://github.com/euler-xyz/euler-swap/blob/a8493f89764ce69a05915559d9061781b9a96f24/src/libraries/FundsLib.sol), [`libraries/QuoteLib.sol`](https://github.com/euler-xyz/euler-swap/blob/a8493f89764ce69a05915559d9061781b9a96f24/src/libraries/QuoteLib.sol),
[`EulerSwapFactory.sol`](https://github.com/euler-xyz/euler-swap/blob/a8493f89764ce69a05915559d9061781b9a96f24/src/EulerSwapFactory.sol), [`interfaces/IEulerSwapHookTarget.sol`](https://github.com/euler-xyz/euler-swap/blob/a8493f89764ce69a05915559d9061781b9a96f24/src/interfaces/IEulerSwapHookTarget.sol). Euler had
not deployed it on Monad, so the team did (`deploy-mm.sh:4`). Deployed on Monad (`deployed-143.env`):

| Contract | Address |
|---|---|
| Factory | [0xDD13DCECd0Da21158507385867d24ec56BF80484](https://monadscan.com/address/0xDD13DCECd0Da21158507385867d24ec56BF80484) |
| Periphery (swap and quote entry points) | [0xA4cBd6e277B7a531fF8525877a17bD31Cf28619B](https://monadscan.com/address/0xA4cBd6e277B7a531fF8525877a17bD31Cf28619B) |
| Pool implementation | 0xdEDc0388113450eb380817a8770c853C660Caf6d |
| Protocol fee config (admin: AlphaGrowth Safe 0x4f89…7Fd3C) | 0x53fBE13F8852cc9AcB5750375112346EC76532d7 |
| Management | 0xA25142Fc5d24675C1A72f418a3239782F85E4533 |
| Uniswap v4 PoolManager | 0x188d586Ddcf52439676Ca21A244753fA19F9Ea8e |

## How an EulerSwap pool works

An EulerSwap pool is an AMM whose liquidity is an **Euler account** rather than tokens it holds. Its fixed parameters
name two Euler supply vaults, two optional borrow vaults and the account (`interfaces/IEulerSwap.sol:5-13`); its
reconfigurable parameters set the curve (equilibrium reserves, a price `priceX/priceY`, concentrations), fees, an expiry
and an optional hook (`IEulerSwap.sol:15-30`, bounds in `EulerSwapManagement.sol:38-52`). The account authorises the pool
as its EVC operator; the factory deploys the pool as a metaproxy and activates it, approving the vaults and enabling the
input-side vault as collateral (`EulerSwapFactory.sol:36-55`, `EulerSwapManagement.sol:61-137`). Each pool also
registers itself as a Uniswap v4 hook with its own v4 pool (`UniswapHook.sol:36-54`), so routers and aggregators reach
it through the PoolManager, and the periphery offers direct `swapExactIn`/`swapExactOut` and quotes.

A swap runs in this order (`EulerSwap.sol:122-153`): the before-swap hook; **withdraw-then-borrow** of the output token
(`FundsLib.withdrawAssets`, 41-65: "first using available balance and then borrowing if needed", it withdraws the
account's supply from the output vault, then enables the borrow vault as controller and borrows the rest); the caller's
callback; the input is counted from balances; **deposit-and-repay** of the input (`FundsLib.depositAssets`, 78-111:
repays any debt in the input's borrow vault, deposits the rest for the account); then the curve check and the
after-swap hook (`SwapLib.finish`, 135-163).

The quote is bounded (`QuoteLib.calcLimits`, 120-195) by the input vault's `maxDeposit(account)`, the output reserve
less its minimum, the output vault's cash, the borrow vault's cap less total borrows, and the curve. The quote does
**not** model the account's loan-to-value; that check runs in the Euler vault after the borrow and reverts the swap if
the account would be over its LTV.

The fee can come from a hook: `getFee(asset0IsInput, reserve0, reserve1, readOnly)` returns a fee in 1e18 units; 1e18
or more rejects the swap (`IEulerSwapHookTarget.sol:11`, `QuoteLib.sol:85`). The hook may also `reconfigure` the pool
(`EulerSwapManagement.sol:159-161`).

## The desk's pool

Opened by the admin Safe through `ShMonadExitAdapter.deployMmPool` (lines 897-911), which requires `supplyVault0` to be
the desk's ushMON and the desk to be both the Euler account and the hook. The parameters, from the release scripts
(`alphastructures/custody/release-mm-143.ts:141-157`, `custody/release-ush2-143.ts`):

| Parameter | Value | Meaning |
|---|---|---|
| asset0 / supplyVault0 | shMON / the desk's ushMON | a seller's shMON is deposited into ushMON for the desk |
| asset1 / supplyVault1 = borrowVault1 | WMON / the cluster's WMON vault `0xE452…0eaf` | WMON paid from the desk's WMON supply, then borrowed |
| borrowVault0 | none | the pool never borrows shMON |
| eulerAccount, swapHook | the desk | the desk's collateral and loan; the desk prices every sale |
| priceX | shMonad rate × 1.02 | a fixed ceiling 2% over the live rate |
| concentrationX = concentrationY = 1e18 | | a constant-price line |
| equilibriumReserve1, initial reserve1 | 100,000,000 WMON | the most the pool may ever pay out |
| fee0 = 0, fee1 = 1e18 | | shMON in priced by the hook; WMON in refused |
| hooked operations | 6 (getFee, afterSwap) | |

`getFee` (915-920) charges shMON in whatever brings the fixed ceiling down to **the live rate less 0.30%**
(`MM_DISCOUNT_BPS = 30`, "Root 2026-11-06: 'charges .3% less'"), and returns 1e18 for WMON in, so the pool only buys.
Since v1.7.0 it also returns 1e18 for every sale while the vault has an unpaid withdrawal batch, so the vault's own
leavers get the borrowing room first and outside sellers are routed to shMonad's instant exit for those minutes.
`afterSwap` (932-943) moves the ceiling to 2% over the live rate when the rate has come within 1% of it, re-anchoring the
curve at the current reserves (`CEILING_BPS = 200`, `RESET_BPS = 100`). On the fork a seller of 60.48 shMON (99.99 MON
of value) was quoted 99.69 WMON, 0.30% under (`evidence/rehearsal-fork.log`).

A seller's shMON lands in ushMON as the desk's collateral; the WMON the pool pays raises the desk's loan. The bot then
sends that shMON into the unstake (planner step 5) and a day later the settle repays the loan and the 0.3% stays
(`evidence/hardhat-fork-ush2.txt`, steps 5 to 8). ushMON v2's receiver gate does not block the pool: the deposit names
the desk as receiver and the quote reads `maxDeposit(desk)` (`QuoteLib.sol:137`), which stays unlimited.

## What capital the pool needs

The pool pays WMON from two sources, in order, and each has a ceiling:

| Source | Bound | Where |
|---|---|---|
| The desk's own WMON supplied in the WMON vault | the desk's balance there, and the vault's cash | `FundsLib.sol:51-58`, `QuoteLib.sol:156-159` |
| WMON borrowed by the desk | the WMON vault's **cash** (what lenders have supplied and not lent) | `QuoteLib.sol:161-164` |
| | the WMON vault's **borrow cap** less total borrows: 654M WMON (set 2026-11-17) | `QuoteLib.sol:168-175`, `deploy.sh:54` |
| | the desk's **loan-to-value**: debt at most 93% of its ushMON collateral (liquidation at 95%) | `deploy.sh:57,193`; checked by the WMON vault after the borrow |
| | the pool's reserve1: 100M WMON | `QuoteLib.sol:142-147` |

The LTV bound sets a standing requirement. A sale adds collateral worth 100 and debt worth 99.7, but the vault lends only
93 against 100, so the desk must already hold about 7.2% of the day's outstanding buys as parked ushMON, or the borrow
reverts with `E_AccountLiquidity`. The fork run of 2026-11-16 found exactly this (`evidence/hardhat-fork-ush2.txt`,
first attempt) and the releases now park 80 MON of shMON (48.38 shMON) per desk as headroom before opening the pools.

So the capital is:

- **Lenders' WMON in the cluster's WMON vault.** This is the float the pool draws on. On 2026-11-18 the vault
  holds 929.88 WMON lent by the deployer key, from the 1,100 MON Root sent (the rest is headroom and gas). With 9 in
  10 shMonad instant exits under 220 MON (`evidence/data/instant-exits-30d.json`), that float serves a typical sale once
  per cycle; to carry the whole public flow at the recent 160,000 MON a day it would need lenders of that order, and
  they earn the WMON vault's rate (20% at zero use, 30% at the 90% kink, `deploy.sh:49`).
- **The desk's headroom.** About 7.2% of outstanding buys, parked as ushMON; 80 MON per desk since 2026-11-16.
- **Gas.** The deployer keeps 10 MON.

**Sizing for a capacity target.** To buy $100k of shMON in one unstake cycle:

| Need | Amount | Why |
|---|---|---|
| WMON borrowed | $99.7k | the pool pays 99.7% of the shMON's value |
| WMON supply in the WMON vault | about $111k | $99.7k is 90% of $111k, so the vault stays at its rate kink (30%); $99.7k alone works but runs the vault at 100% use and 50% |
| shMON parked as headroom | about $7.2k | the vault lends 93% against ushMON, so the desk must already hold 0.997 / 0.93 − 1 = 7.2% of the buys as collateral |

Both scale in a straight line with the target, and the headroom sits with whichever desk's pool does the buying.

The desk's margin per sale is the 0.30% discount less one day of WMON interest on the borrow and the gas of the park
and settle calls. The economics model in `evidence/data/exit-mm.md` (2026-11-05) puts the borrow-to-fill design at 1.8%
to 3.4% a year on $100k of capital from outside flow alone at a 0.3% discount, and 18% to 22% when the vault's own exits
of $500k a month also pass through it; the benchmark it states for shMonad's own instant pool is about 8% a year since
launch. Those are model figures, not measured returns.

## The keeper's shMON arbitrage

The keeper buys shMON wherever it sells for less than our pools pay, and sells it into our pools.[^arb]
* The keeper buys on Curve, Uniswap v3 or PancakeSwap v3, then sells to the desk's pool in one router call.
* The pool pays with WMON it borrows from the cluster, and the shMON unstakes for a day to repay that loan.
* The arbitrage never runs while any desk has leavers waiting.
* It always leaves the WMON vault a reserve, the larger of half its unlent WMON or the last leaver payout.
* It sends each trade to the desk whose pool can take more, and that desk keeps the profit as WMON.

[^arb]: `alphastructures/services/digesterKeeper/src/arb.ts:4-13,42-46`; Root 2026-11-17: "send it to the desk as WMON".

## How a pool is retired

`moveEulerAccount` (desk line 494) removes the pool as the desk's operator, forgets it and moves the desk's collateral
and lender to a new pair; it refuses while anything is borrowed or parked. The pool on the first cluster
(`0x9aF1E49D878A5721eC1FdDd76b2237Ff585Ee8a8`) was retired this way on 2026-11-09 (`ShMonadExitV15.fork.test.ts`,
`docs/shmon-exit-desk-plan.md:186-204`). Static parameters cannot change, so a new ushMON means a new pool.
