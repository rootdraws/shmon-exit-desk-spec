# The WMON vault's rate curve, IRM 0xa359026aae6c26Ba90B3D3AB78Fc483Da09DBa8a, read at block 122852972 (2026-11-16)

Rates from `computeInterestRateView` with cash + borrows = 1e24. APR = per-second rate × 31,536,000; APY compounds per second. The supplier rate is APY × utilization × 0.9 (the vault keeps a 10% interest fee). The borrower's cost per day is set against the desk's 0.30% margin per sale.

| utilization | per-second rate (ray) | APR | APY | supplier APY | borrower cost per day | share of the 0.30% sale margin |
|---|---|---|---|---|---|---|
| 0% | 5781378640092421120 | 18.23% | 20.00% | 0.00% | 5.00 bps | 17% |
| 50% | 7191455089630521825 | 22.68% | 25.46% | 11.46% | 6.22 bps | 21% |
| 80% | 8037500959878676660 | 25.35% | 28.85% | 20.77% | 6.95 bps | 23% |
| 90% | 8319516249523649595 | 26.24% | 30.00% | 24.30% | 7.19 bps | 24% |
| 95% | 9306569765579217920 | 29.35% | 34.11% | 29.16% | 8.04 bps | 27% |
| 98% | 12857214234784512000 | 40.55% | 50.00% | 44.10% | 11.11 bps | 37% |
| 100% | 12857214234784512000 | 40.55% | 50.00% | 45.00% | 11.11 bps | 37% |

The curve was deployed from `deploy-mm.sh:39` as `IRM_ARGS=(5781378640092421120 656618015 5 3865470565 12857214234784512000)`: 20% at zero use, 30% at the 90% kink, a 50% cap that binds from about 98% use.

## What WMON lending pays elsewhere on Monad (read 2026-11-16 22:37Z, block 122859275)

| Lender | WMON supplied | Use | Borrow rate | Supplier rate |
|---|---|---|---|---|
| Neverland WMON reserve (pool 0x80F00661b13CC5F6ccd3885bE7b4C9c67545D585) | 56,420,374 | 89.7% | 8.98% APR | 4.02% APR |
| Euler 0x7B4BcAEAC5Eb67ae947903F24BBa660eE06A5231 | 1,308,060 | 74.2% | 8.17% APY | 5.45% APY |
| Euler 0x9eA1b948186F9A8cfe375278d96363103f4fa42B | 870,630 | 51.6% | 5.61% APY | 2.61% APY |
| Euler 0x28bD4F19C812CBF9e33A206f87125f14E65dc8aA | 200,880 | 70.0% | 7.69% APY | 4.84% APY |

Every other WMON vault from Euler's factory on Monad (163 vaults scanned by `asset()`) holds under 1,000 WMON or
nothing. Aave's Monad market lists wMON as collateral only, not borrowable (Aave governance ARFC "Deploy Aave Protocol
v3.7 on Monad"), so it has no WMON lending rate. Root, 2026-11-16: the cluster's curve stays at 20/30/50 ("I want it to
be expensive, to use, and attract resting capital").
