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
