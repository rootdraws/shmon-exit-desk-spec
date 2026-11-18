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
| Routing savings | leavers' shMON sells on Curve or through the desk's borrow route instead of shMonad's instant exit | the vault, as a fee it does not pay | about 0.45% saved on each sale: 0.55% typical instant-exit fee (`evidence/data/shmonad-30d.md`) less about 0.10% for our route |

The exit fees, the pool margin, the arbitrage and the digester gains all raise the share price. AlphaGrowth collects
10% of every rise through the performance fee, including rises that only win back a dip. Measured against what the
holders net, that is about 21% on Delta One and 14% on Delta Zero.

Settings 1.16 charges 10% of every rise over the last published price, up or down (Root, 2026-11-18: "change the
contract to charge 10% on every gain"). It is written, tested and rehearsed on a fork of Monad with
`custody/release-settings-116.ts`. Both vaults run 1.15 on chain, which charges only above a high-water mark, until
the mainnet release.

## Where it goes at $2M TVL

![Revenue flows at $1M per vault, live net carry, 150,000 MON of pool buys per 20 hours](figures/revenue-flows.svg)

| Receiver | From | $ per year |
|---|---|---|
| Admin Safe, AlphaGrowth | performance fees, 10% on every gain: 8,579 from Delta One, 23,869 from Delta Zero | 32,448 |
| AlphaGrowth Euler Safe | Euler interest fee on WMON and USDC loans | 8,747 |
| Holders, both vaults | carry, exit fees, pool margin, routing savings, after the performance fee: 35,843 Delta One, 148,689 Delta Zero | 184,532 |
| USDC lenders on Euler | vault loan interest, after the Euler fee | 78,215 |
| WMON suppliers | desks' WMON interest, after the Euler fee | 512 |

Inputs: $1M in each vault, the live net carry below, 10% of TVL withdrawn a month, 43% LTV, 60% of the loan on Euler at 9.6%,
150,000 MON of pool buys per 20 hours split evenly, 170,000 MON of WMON supply, a 20-hour unstake and MON at $0.0146.

## Net carry, from live rates on 2026-11-18

Per $1 deposited at the 43% target, the bot's book shape (`policy/base.ts`, with margin at 28.57% plus the fee, × 1.05)
puts Delta One at $1.49 of shMON, a $0.64 loan and a $0.49 short, and Delta Zero at $1.15 of shMON, a $0.49 loan and a
$1.15 short.

| Per $1 deposited | Delta One | Delta Zero | Rate and where it was read |
|---|---|---|---|
| shMON staking on the collateral | +16.4% | +12.7% | 11.01% APR, shMonad's `convertToAssets` 30 days apart (1.6429 to 1.6542) |
| MON funding paid to shorts | +3.5% | +8.1% | 7.03% a year, the 30-day mean of Hyperliquid's hourly MON funding (live hour 6.58%) |
| USDC interest | −5.2% | −4.0% | 8.06% blended: 60% on Euler at 9.6% (its curve's 90% kink) and 40% on Neverland at its live 5.74% |
| Total in dollars | 14.7% | 16.7% | |
| Net carry used above | **3.7%** | **16.7%** | Delta One's share price is counted in shMON, so its holders' own 11.0% staking yield is taken out |

The 60% Euler share assumes the $1M of USDC lending about to arrive on the Euler cluster for these vaults (Root,
2026-11-18: "we are about to get 1m in USDC lending on euler just for this vault"). The bot borrows up to the curve's
90% kink, so $900k of the $1.5M loan at $2M TVL. With only Neverland the loan costs 5.74%, and the net carry is 5.2% and
17.9%.

Neverland pays 0% for supplied shMON. Trading fees and the cost of entering the book are left out.

## Formulas

- Pool gross = MON bought per 20 h × 438 cycles a year × 0.30% × MON price.
- WMON interest = MON bought × 0.997 × 438 × ln(1 + borrow APY) × unstake hours ÷ 8,760 × MON price. The borrow APY
  follows the WMON vault's curve: 20% at zero use, 30% at the 90% kink, 50% at full use.
- Pool margin to the vaults = pool gross − WMON interest.
- Exit fees = TVL × share withdrawn per month × 12 × 0.30%.
- Routing savings = TVL × share withdrawn per month × 12 × shMON sold per $1 withdrawn × (0.55% − 0.10%). Both vaults
  pay leavers in shMON (`asset()` is shMON on both), so a vault sells shMON only for the loan it repays less the margin
  that comes home from Hyperliquid: $0.49 per $1 withdrawn on Delta One and $0.15 on Delta Zero.
- Vault gain = carry + exit fees + pool margin + routing savings.
- Performance fee, 10% on every gain = 10% × (vault gain + carry × (churn − 1)). The churn is 2.12 for Delta One and
  1.40 for Delta Zero. A replay of every hourly Hyperliquid MON funding rate from 2025-10-08 to 2026-11-18 found that
  charging every hourly rise, including the climb back after a negative-funding dip, takes that many times the fee a
  high-water mark takes. Funding was negative in 1,567 of 9,756 hours. Under a high-water mark, the churn is 1.
- Euler loan interest = TVL × 0.43 ÷ 0.57 × Euler share × Euler borrow APR. Suppliers get 90%, and AlphaGrowth gets 10%.

The calculator with every input is the artifact at https://claude.ai/artifact/BzqBnCLXMaoxTBc7vD9nrD (private).
