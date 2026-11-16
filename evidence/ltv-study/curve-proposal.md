# A proposed WMON rate curve for the ushMON desk (computed 2026-11-16)

Formula check on the live curve (should read 20.0 / 25.5 / 30.0 / 50.0): 20.0%, 25.5%, 30.0%, 50.0%

Proposed factory arguments `deploy(baseRate, slope, shape, kink, cutoff)`: `IRM_ARGS=(1847694955732363770 451674395 5 3865470565 8319516250237539940)`

| utilization | live curve APY | proposed APY | proposed supplier APY | proposed borrower cost per day | share of the 0.30% margin |
|---|---|---|---|---|---|
| 0% | 20.0% | 6.00% | 0.00% | 1.60 bps | 5% |
| 50% | 25.5% | 9.29% | 4.18% | 2.43 bps | 8% |
| 80% | 28.8% | 11.32% | 8.15% | 2.94 bps | 10% |
| 90% | 30.0% | 12.00% | 9.72% | 3.11 bps | 10% |
| 95% | 34.1% | 14.42% | 12.33% | 3.69 bps | 12% |
| 98% | 50.0% | 26.58% | 23.44% | 6.46 bps | 22% |
| 100% | 50.0% | 30.00% | 27.00% | 7.19 bps | 24% |

Reasoning. The borrower holds each loan about a day and earns 0.30% per sale, so the curve's job is to pay lenders enough to come while leaving the desk most of its margin. At the 90% kink the live curve takes 7.2 bps a day (24% of the margin) and pays suppliers 24.3%; the proposal takes 3.1 bps a day (10%) and pays suppliers 9.7%, still double the 4.95% Euler's deepest WMON vault on Monad paid lenders at 71% use on 2026-11-05. The cap keeps the desk from sitting above the kink.
