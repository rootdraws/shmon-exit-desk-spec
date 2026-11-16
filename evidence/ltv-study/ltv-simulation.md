# LTV simulation on a fork of Monad, 2026-11-16 (`ShMonadExitUshLtv.fork.test.ts`)

## Interest drift: the desk borrows to the borrow LTV, holds 30 hours, nobody can liquidate

| borrow / liquidation LTV | use | curve APY | debt growth (bps) | curve's figure (bps) | health after | liquidatable |
|---|---|---|---|---|---|---|
| 97 / 98 | 90.0% | 30.00% | 8.99 | 8.99 | 1.0094 | no |
| 97 / 98 | 98.5% | 50.00% | 13.90 | 13.90 | 1.0089 | no |
| 96 / 97 | 90.0% | 30.00% | 8.99 | 8.99 | 1.0095 | no |
| 96 / 97 | 98.5% | 50.00% | 13.90 | 13.90 | 1.0090 | no |
| 95 / 96 | 90.0% | 30.00% | 8.99 | 8.99 | 1.0096 | no |
| 95 / 96 | 98.5% | 50.00% | 13.90 | 13.90 | 1.0091 | no |
| 93 / 95 | 90.0% | 30.00% | 8.99 | 8.99 | 1.0206 | no |
| 93 / 95 | 98.5% | 50.00% | 13.90 | 13.90 | 1.0201 | no |
| 90 / 93 | 90.0% | 30.00% | 8.99 | 8.99 | 1.0324 | no |
| 90 / 93 | 98.5% | 50.00% | 13.90 | 13.90 | 1.0319 | no |
| 87 / 90 | 90.0% | 30.00% | 8.99 | 8.99 | 1.0336 | no |
| 87 / 90 | 98.5% | 50.00% | 13.90 | 13.90 | 1.0330 | no |

## The feed drops under shMonad's rate by d: liquidation and the liquidator's result

| borrow / liquidation LTV | drop (bps) | health | liquidatable | debt taken (WMON) | liquidator's result (bps of debt taken) | bad debt (WMON) | bad debt expected by the rule |
|---|---|---|---|---|---|---|---|
| 97 / 98 | 10 | 1.0093 | no | 0.00 |  | 0.00 |  |
| 97 / 98 | 50 | 1.0053 | no | 0.00 |  | 0.00 |  |
| 97 / 98 | 100 | 1.0002 | no | 0.00 |  | 0.00 |  |
| 97 / 98 | 200 | 0.9901 | yes | 290.97 | 306.73 | 0.00 | False |
| 97 / 98 | 300 | 0.9800 | yes | 285.15 | 520.34 | 5.82 | True |
| 97 / 98 | 500 | 0.9598 | yes | 273.51 | 967.96 | 17.46 | True |
| 93 / 95 | 10 | 1.0205 | no | 0.00 |  | 0.00 |  |
| 93 / 95 | 50 | 1.0164 | no | 0.00 |  | 0.00 |  |
| 93 / 95 | 100 | 1.0113 | no | 0.00 |  | 0.00 |  |
| 93 / 95 | 200 | 1.0011 | no | 0.00 |  | 0.00 |  |
| 93 / 95 | 300 | 0.9909 | yes | 278.97 | 405.03 | 0.00 | False |
| 93 / 95 | 500 | 0.9704 | yes | 276.54 | 847.75 | 2.43 | True |

The liquidator takes the debt over, pays about (1 − borrow LTV) of it in its own WMON to pass Euler's check, waits for the unstake to mature (shMonad's epoch written on the fork), redeems the seized ushMON for WMON at shMonad's true rate in one EVC batch with the repay, and the result is its WMON after minus before, over the debt it took. Bad debt is the `DebtSocialized` amount the WMON vault wrote off.
