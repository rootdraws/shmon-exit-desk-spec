# 12. Revenue flows: what makes money, how much, and where it goes

Fees and receivers were read on chain on 2026-11-18. Root, 2026-11-18: "the admin safe will be handed over to them"
(AlphaGrowth), so both the admin Safe's performance fees and the Euler interest fee count as AlphaGrowth's below.

## What TVL means here

TVL is the shMON that depositors put into the two vaults, valued in dollars. The bot then levers it to the 43% target
([02-alpha-structures.md](02-alpha-structures.md)), so $2M of TVL becomes:

| Piece | At $2M TVL | Formula |
|---|---|---|
| shMON collateral, supplied to Neverland and Euler | about $3.5M | TVL ÷ (1 − 0.43) |
| USDC or USDT0 borrowed | about $1.5M | TVL × 0.43 ÷ (1 − 0.43) |
| of which borrowed from the Euler cluster, at a 50% split | about $750k | borrowed × Euler share |

The vault borrows $1.5M against the $2M deposit and buys $1.5M more shMON with it. It then holds $3.5M of shMON and
owes $1.5M, so the depositors still own $2M.

WMON lending is not part of TVL. It is sized by the EulerSwap pools' volume ([05-eulerswap.md](05-eulerswap.md)).

## The pieces

| Piece | How it makes money | Where it goes | Source |
|---|---|---|---|
| Performance fee, Delta One | 10% of share price gain above the high-water mark, counted in shMON, paid as new shares | admin Safe `0xC94d…9CfD` | `getPerformanceFee()` on `0xdE30…dEC` returns 1000 bps to `0xC94d…9CfD`; `StrategyControllerSettings.sol:192-235` |
| Performance fee, Delta Zero | the same, counted in dollars | admin Safe | `getPerformanceFee()` on `0xC62D…F85a` returns 1000 bps to `0xC94d…9CfD` |
| Exit fees, both vaults | 0.30% kept from every withdrawal | the holders who stay | `WithdrawalHandler.sol:281-283` |
| EulerSwap pools | buy shMON 0.30% under shMonad's rate, pay about one day of WMON interest | the desk, then its vault | [05-eulerswap.md](05-eulerswap.md); EulerSwap's own protocol fee reads 0 for the pools |
| shMON arbitrage | the keeper buys cheap shMON on outside pools and sells it into ours | the desk, then its vault | [02-alpha-structures.md](02-alpha-structures.md) permissions table |
| Digester | the keeper's gain on each fill, plus the 0.01% pool fee on our own resting orders | the vault | `MonadRouter.sol:200` pays each cycle's gain to its vault |
| WMON lending | 90% of the interest the desks pay on WMON | WMON suppliers, today the deployer key | the WMON vault's `interestFee()` reads 1000 |
| Euler interest fee | 10% of all interest paid in the cluster, WMON and USDC alike | AlphaGrowth Euler Safe `0x4f89…Fd3C` | `interestFee()` 1000 and `feeReceiver()` `0x4f89…Fd3C` on the USDC, WMON and USDT0 vaults; `protocolFeeShare()` 0 |
| Exit bid pools | buy shMON at a 0.30% discount | the vault | both hold no bids, so they earn nothing today |
| Stable desk | moves debt between USDC and USDT0 | the vault, as lower borrow cost | takes no fee |

The exit fees, the pool margin, the arbitrage and the digester gains all raise the share price. AlphaGrowth collects
10% of that rise through the performance fee, and the holders keep the other 90%.

## Where it goes at $2M TVL

![Revenue flows at $1M per vault, 8% net carry, 150,000 MON of pool buys per 20 hours](figures/revenue-flows.svg)

| Receiver | From | $ per year |
|---|---|---|
| Admin Safe, AlphaGrowth | performance fees, both vaults | 16,951 |
| AlphaGrowth Euler Safe | Euler interest fee on WMON and USDC loans | 6,469 |
| Holders, both vaults | carry, exit fees, pool margin, after the performance fee | 152,558 |
| USDC lenders on Euler | vault loan interest, after the Euler fee | 57,711 |
| WMON suppliers | desks' WMON interest, after the Euler fee | 512 |

Inputs: $1M in each vault, 8% net carry, 10% of TVL withdrawn a month, 43% LTV, half the loan on Euler at 8.5%,
150,000 MON of pool buys per 20 hours split evenly, 170,000 MON of WMON supply, a 20-hour unstake and MON at $0.0146.
The 8% carry is a placeholder, because the carry has not been measured.

## Formulas

- Pool gross = MON bought per 20 h × 438 cycles a year × 0.30% × MON price.
- WMON interest = MON bought × 0.997 × 438 × ln(1 + borrow APY) × unstake hours ÷ 8,760 × MON price. The borrow APY
  follows the WMON vault's curve: 20% at zero use, 30% at the 90% kink, 50% at full use.
- Pool margin to the vaults = pool gross − WMON interest.
- Exit fees = TVL × share withdrawn per month × 12 × 0.30%.
- Vault gain = carry + exit fees + pool margin. The performance fee takes 10% of it, and the holders keep 90%.
- Euler loan interest = TVL × 0.43 ÷ 0.57 × Euler share × Euler borrow APR. Suppliers get 90%, and AlphaGrowth gets 10%.

The calculator with every input is the artifact at https://claude.ai/artifact/BzqBnCLXMaoxTBc7vD9nrD (private).
