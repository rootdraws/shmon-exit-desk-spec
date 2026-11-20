# 10. References

## Code

| Repo | Version | Used for |
|---|---|---|
| [alphagrowth/alphastructures](https://github.com/alphagrowth/alphastructures), private | branch `shmon-release-2026-11-18` at `a539a19`, not yet merged into `master` (`268892c`) | the vaults, the exit desk, the bot, the tests and the docs |
| [rootdraws/ushMON](https://github.com/rootdraws/ushMON), private | `b3ba1bf` | the unstaking shMON vault |
| Our Euler deploy scripts | copied in this repo under [`sources/ag-euler/`](sources/ag-euler/) | deploying the cluster, EulerSwap and ushMON |

The cluster and pools are built from Euler's open-source contracts and other standard libraries:

| Repo | Version | Used for |
|---|---|---|
| [euler-xyz/ethereum-vault-connector](https://github.com/euler-xyz/ethereum-vault-connector) | v1.0.1 | account checks across vaults |
| [euler-xyz/euler-vault-kit](https://github.com/euler-xyz/euler-vault-kit) | | the cluster's lending vaults |
| [euler-xyz/euler-price-oracle](https://github.com/euler-xyz/euler-price-oracle) | `63f20a4` | the price router and Chainlink SVR adapters |
| [euler-xyz/euler-swap](https://github.com/euler-xyz/euler-swap) | [`a8493f8`](https://github.com/euler-xyz/euler-swap/tree/a8493f89764ce69a05915559d9061781b9a96f24) | the EulerSwap pools |
| [OpenZeppelin/openzeppelin-contracts](https://github.com/OpenZeppelin/openzeppelin-contracts) | 5.2.0 | ushMON's ERC-4626 base |
| [OpenZeppelin/uniswap-hooks](https://github.com/OpenZeppelin/uniswap-hooks) | 1.3.0 | the digester's limit order hook |
| [Uniswap/v4-core](https://github.com/Uniswap/v4-core), [v4-periphery](https://github.com/Uniswap/v4-periphery) | | the v4 pool manager and hooks |
| [foundry-rs/forge-std](https://github.com/foundry-rs/forge-std) | 1.17 | ushMON's tests |

## Contracts on Monad (chain 143)

Links go to Monadscan.

**Alpha Structures, production**

| Contract | usdc-hl (delta one) | usdc-hl-d0 (delta neutral) |
|---|---|---|
| Vault | [0xeEe3dAb9fc5d3833aE219F87A1Fbb68F3d4431D3](https://monadscan.com/address/0xeEe3dAb9fc5d3833aE219F87A1Fbb68F3d4431D3) | [0x187bEF1d746350B22e0Ab1FAfA2A96a6F4aF272C](https://monadscan.com/address/0x187bEF1d746350B22e0Ab1FAfA2A96a6F4aF272C) |
| StrategyController | [0xc27A2eA394c1499FA6261bd12f38D813C2DecB51](https://monadscan.com/address/0xc27A2eA394c1499FA6261bd12f38D813C2DecB51) | [0x13B7aF96a7f1F7E0A4E228CcC0e437389492F5Ae](https://monadscan.com/address/0x13B7aF96a7f1F7E0A4E228CcC0e437389492F5Ae) |
| StrategyControllerSettings | [0xdE30DFdC5107D52c1Dec101db4afDC6a7372adEC](https://monadscan.com/address/0xdE30DFdC5107D52c1Dec101db4afDC6a7372adEC) | [0xC62D354c3B8fbBEEA9Bee2D35Da38e015770F85a](https://monadscan.com/address/0xC62D354c3B8fbBEEA9Bee2D35Da38e015770F85a) |
| WithdrawalHandler | [0xFb78583f6D8A9F6c2cCae6111e2817AC9824162a](https://monadscan.com/address/0xFb78583f6D8A9F6c2cCae6111e2817AC9824162a) | [0x4B821aFd90eF4F5a35Dec5e4AeeA7C00c7d90Af2](https://monadscan.com/address/0x4B821aFd90eF4F5a35Dec5e4AeeA7C00c7d90Af2) |
| Exit desk proxy (`ShMonadExitAdapter`) | [0x02Df7fb3b4535361EE10C391e3bDDAEe9001c770](https://monadscan.com/address/0x02Df7fb3b4535361EE10C391e3bDDAEe9001c770) | [0xF460C4C68704Da32Ba3cefC2feEcaA3C3f3d6CdE](https://monadscan.com/address/0xF460C4C68704Da32Ba3cefC2feEcaA3C3f3d6CdE) |
| Stable desk proxy (`StableDeskAdapter`) | [0xc19aa853D2a300462Cf558EB16397de35702599a](https://monadscan.com/address/0xc19aa853D2a300462Cf558EB16397de35702599a) | [0x2dCDEB8BBdF3F0D8b89A373bFcc3C4B2eBAF28f1](https://monadscan.com/address/0x2dCDEB8BBdF3F0D8b89A373bFcc3C4B2eBAF28f1) |
| Vault implementation 1.12.0 | [0xBB3008d28Fe70607fD09385bA9f9De9669da3898](https://monadscan.com/address/0xBB3008d28Fe70607fD09385bA9f9De9669da3898) | same |
| StrategyController implementation 1.16.0 | [0x2cE43698496BB52E2ce3aD506e7367a02b7A6aE6](https://monadscan.com/address/0x2cE43698496BB52E2ce3aD506e7367a02b7A6aE6) | same |
| Settings implementation 1.16.0 | [0x6B25C62bB8732669174E42CD571839b4AAa3C113](https://monadscan.com/address/0x6B25C62bB8732669174E42CD571839b4AAa3C113) | same |
| WithdrawalHandler implementation 1.11.0 | [0xA26047836A996d81bEA2b3A017E99825Db3D0b9d](https://monadscan.com/address/0xA26047836A996d81bEA2b3A017E99825Db3D0b9d) | same |
| Exit desk implementation 1.10.0 | [0x74eCd223208D812098487D4090d964005370BDc7](https://monadscan.com/address/0x74eCd223208D812098487D4090d964005370BDc7) | same |
| Stable desk implementation 1.3.0 | [0x640c3af4878961d461ddd2dde508641d6464a501](https://monadscan.com/address/0x640c3af4878961d461ddd2dde508641d6464a501) | same |
| ushMON, one vault for both desks | [0xa753E24B0986567EDAd75f784664Ec11336f8C5e](https://monadscan.com/address/0xa753E24B0986567EDAd75f784664Ec11336f8C5e) | same |
| EulerSwap pool, the public buyer | [0x56aEAB6F7a33573CdEF9B59a8d330F0e1b2128A8](https://monadscan.com/address/0x56aEAB6F7a33573CdEF9B59a8d330F0e1b2128A8) | [0x19241Ff986e1dFE848A8C2a8AC2C21C0E7cFe8a8](https://monadscan.com/address/0x19241Ff986e1dFE848A8C2a8AC2C21C0E7cFe8a8) |
| Admin Safe | [0xC94dd8e928D681bd85BeB94a8729709d189cCF9D](https://monadscan.com/address/0xC94dd8e928D681bd85BeB94a8729709d189cCF9D) | same |

Source: `alphastructures/deploy/deployments/production/*.json`. Every implementation was read from its proxy on chain
on 2026-11-20.

**Keys and roles** (from [02-operations.md](02-operations.md))

| Role | Delta One | Delta Neutral |
|---|---|---|
| Executor | 0xC95F60fdE77ECEBf9DED1228A939ac8eDB2671D3 | 0xF3206EfC847386E66043459832eDb74998C63669 |
| Oracle | 0x77d550f9C11AAFC69Cb7651d7B2E405BE43Eb0B9 | 0x2ECF679c2DF38a758F365f1EEc7CD090567FD5e7 |
| Hedge Safe (HyperEVM) | 0x704f20644035b5fA822cC920a25C99F97BF7C6ed | 0x213a4C29c42Bb956c34064750b689baB313561C3 |
| Guardian | 0x868736358fA307d70b359BcaB2e92e6A7ED0734C | same |
| Freeze module | 0x6c3A2bE9c75b5ed1b8144EB970Bcd35A52F93D4d | same |
| custody-admin key (owner of the admin Safe) | 0xb9a86575182c0F0F07e8b7404612c8207c87681B | same |

**Markets the desk uses** (from [03-exit-desk.md](03-exit-desk.md))

| Market | Address or pool id |
|---|---|
| Curve MON LSTs (WMON / shMON) | 0x74d80ee400d3026fdd2520265cc98300710b25d4 |
| Uniswap v4 MON/USDC 0.05% | 0x18a9fc874581f3ba12b7898f80a683c66fd5877fd74b26a85ba9a3a79c549954 |
| Uniswap v4 MON/USDC 0.001% | 0x77169f9b5da147c4952896072951e84e4f4aad7b4d68ebe626ba358ed4e9c1e6 |
| Uniswap v3 WMON/USDC 0.3% | [0x659bD0BC4167BA25c62E05656F78043E7eD4a9da](https://monadscan.com/address/0x659bD0BC4167BA25c62E05656F78043E7eD4a9da) |
| PancakeSwap v3 WMON/USDC 0.05% | 0x63e48B725540A3Db24ACF6682a29f877808C53F2 |
| PancakeSwap v3 AUSD/WMON | 0xD5b70d70CBE6C42bCD1aaa662A21673A83f4615b |
| Uniswap v3 shMON/WMON | 0x1f86a9F2441caC9B942CFb5445530CdBB28717eD, 0xc27EEbd865051020F9BDEb12398790f356a7B684 |
| PancakeSwap v3 shMON/WMON | 0x66553f37ea7FdC092193dCeFaA7a32F94B1bE4d0 |
| Hanji book (MON / USDC) | 0xc35b1ca1a2c398a21df5783b3a5ea6a2d56f298f |
| Kuru book (MON / USDC) | 0xc9dE998e272d59a19CEA3783C8dd44f87A86405D |

**The digester and exit bid pools**

| Contract | Address | Source |
|---|---|---|
| LimitOrderHook | [0x94Df2bffA788BBd918179f4CCB5A22DbAD7e1040](https://monadscan.com/address/0x94Df2bffA788BBd918179f4CCB5A22DbAD7e1040) | OpenZeppelin uniswap-hooks |
| Digester pool | poolId `0x3957bb3c02c319231713c06853de9bfc8e7d1aaa276873cd65fc028efc0b1314` (WMON/USDC, fee 100, spacing 1) | `docs/Alpha_Structures_Digester.md:21` |
| Digester router (owner: the keeper key) | [0xE1fe1Ea6677Ea56eEFD381045AAcf86D541C3776](https://monadscan.com/address/0xE1fe1Ea6677Ea56eEFD381045AAcf86D541C3776) | read on chain 2026-11-18 |
| Keeper wallet | 0xEE51d642304f8F0b272Fc79cf851CE76ee24c3A7 | `custody/deployments/exit-pool-143.json` |
| ExitBidPool USDC | [0xEA93Cb7Af4bcdAfF8312BEe55dF369970070C4a9](https://monadscan.com/address/0xEA93Cb7Af4bcdAfF8312BEe55dF369970070C4a9) | `alphastructures/contracts/exit-pool/ExitBidPool.sol` |
| ExitBidPool WMON | [0xB03b966811eBd2E481a77d2ce118f8fA2c5fD716](https://monadscan.com/address/0xB03b966811eBd2E481a77d2ce118f8fA2c5fD716) | same |
| Uniswap v4 PoolManager | [0x188d586Ddcf52439676Ca21A244753fA19F9Ea8e](https://monadscan.com/address/0x188d586Ddcf52439676Ca21A244753fA19F9Ea8e) | |

**The Euler cluster**, from `sources/ag-euler/contracts/shmon-cluster-monad/deployed-143.env`

| Contract | Address |
|---|---|
| Oracle router | [0x99f7105CAC565Ac830cf2d66527FBb06dD322C32](https://monadscan.com/address/0x99f7105CAC565Ac830cf2d66527FBb06dD322C32) |
| shMON vault | [0xD81D3E243760eD23Ac3DEf2b08d4989bA2790Dfe](https://monadscan.com/address/0xD81D3E243760eD23Ac3DEf2b08d4989bA2790Dfe) |
| USDC vault | [0x5aB09A3EDbb0937Db454f54e6CF04Dd982c40948](https://monadscan.com/address/0x5aB09A3EDbb0937Db454f54e6CF04Dd982c40948) |
| WMON vault | [0xE4522663752AC47516e39aD11d3780a116850eaf](https://monadscan.com/address/0xE4522663752AC47516e39aD11d3780a116850eaf) |
| USDT0 vault | [0xD6645190976d456907c9807d08E4E4E220c96a3E](https://monadscan.com/address/0xD6645190976d456907c9807d08E4E4E220c96a3E) |
| SVR adapters: shMON/USD, WMON/USD, USDC/USD, USDT0/USD, shMON/WMON | 0x2B435c1D99A8D1667838d7d9a9d1636849E3eAB6, 0xe6a6243E10C3D01b723bC806Da0226425dc0fB9d, 0x74594f3CAc8B43DAF148c8ff5323C40440F18284, 0xBD48e8B62d39C2d3337A342Fd70Ef8ACD173519F, 0x0A75454cD9c15068C4bdB57ec0436D10B0906c6C |
| Rate curves: USDC/USDT0, WMON | 0xe743F06a8A2Dcc9565926a9b11513e957e1897c6, 0xa359026aae6c26Ba90B3D3AB78Fc483Da09DBa8a |
| Governor (deployer) | 0x501107fe590c8F9b81c00b81867fD19e0d9c0253 |
| AlphaGrowth Euler Safe (fee receiver, governor after handover) | 0x4f894Bfc9481110278C356adE1473eBe2127Fd3C |
| Ethereum Vault Connector | [0x7a9324E8f270413fa2E458f5831226d99C7477CD](https://monadscan.com/address/0x7a9324E8f270413fa2E458f5831226d99C7477CD) |

**EulerSwap on Monad**, from the deploy scripts' `eulerswap-mm-monad/deployed-143.env`: factory
[0xDD13DCECd0Da21158507385867d24ec56BF80484](https://monadscan.com/address/0xDD13DCECd0Da21158507385867d24ec56BF80484), periphery
[0xA4cBd6e277B7a531fF8525877a17bD31Cf28619B](https://monadscan.com/address/0xA4cBd6e277B7a531fF8525877a17bD31Cf28619B), implementation
0xdEDc0388113450eb380817a8770c853C660Caf6d, fee config 0x53fBE13F8852cc9AcB5750375112346EC76532d7, management
0xA25142Fc5d24675C1A72f418a3239782F85E4533.

**Tokens and outside protocols**

| Contract | Address |
|---|---|
| shMON, Fastlane's shMonad | [0x1B68626dCa36c7fE922fD2d55E4f631d962dE19c](https://monadscan.com/address/0x1B68626dCa36c7fE922fD2d55E4f631d962dE19c) |
| WMON | 0x3bd359C1119dA7Da1D913D1C4D2B7c461115433A |
| USDC | 0x754704Bc059F8C67012fEd69BC8A327a5aafb603 |
| USDT0 | 0xe7cd86e13AC4309349F30B3435a9d337750fC82D |
| Neverland pool | [0x80F00661b13CC5F6ccd3885bE7b4C9c67545D585](https://monadscan.com/address/0x80F00661b13CC5F6ccd3885bE7b4C9c67545D585) |
| Neverland aTokens: shMON, USDC, USDT0 | 0xC64d73Bb8748C6fA7487ace2D0d945B6fBb2EcDe, 0x38648958836eA88b368b4ac23b86Ad44B0fe7508, 0x39F901c32b2E0d25AE8DEaa1ee115C748f8f6bDf |

## Files cited, by component

- Vault system: `alphastructures/AGENTS.md`, `CLAUDE.md`, `docs/Alpha_Structures_System_Overview.md`,
  `docs/Alpha_Structures_Architecture.md`, `docs/Alpha_Structures_Threat_Model.md`,
  `docs/Alpha_Structures_Production_Server_Runbook.md`, `docs/Alpha_Structures_Rebalancing_Policy.md`,
  `contracts/core/WithdrawalHandler.sol`, `deploy/configs/production/*.json`, `deploy/deployments/production/*.json`.
- Exit desk and digester: `contracts/adapters/venue/ShMonadExitAdapter.sol`, `contracts/digester/MonadRouter.sol`,
  `contracts/exit-pool/ExitBidPool.sol`, `docs/shmon-exit-desk-plan.md`, `docs/Alpha_Structures_Digester.md`,
  `services/rebalancingBot/src/planner/exitDesk.ts`, `services/rebalancingBot/src/lenders.ts`,
  `packages/shared/src/chain/exitDesk.ts`, `custody/release-mm-143.ts`, `custody/release-ml-143.ts`,
  `custody/release-ush2-143.ts`, `custody/release-ush3-143.ts`, `custody/release-ush4-143.ts`,
  `custody/deployments/exit-pool-143.json`.
- Emergency sale: `contracts/core/StrategyController.sol` (`deskFill`), `ShMonadExitAdapter.sol` (`fillFromController`),
  `services/rebalancingBot/src/planner/panic.ts`, `custody/release-panic-143.ts`, `custody/deployments/release-panic-143.json`.
- Loan lines, pause and hedge orders: `custody/set-ltv-lines-143.ts`, `custody/release-pause-143.ts`,
  `contracts/core/Vault.sol`, `packages/shared/src/modes.ts`, `services/rebalancingBot/src/actions/venue.ts`.
- Tests: `contracts/test/NeverlandMarketAdapter/ShMonadExit*.fork.test.ts`, `services/rebalancingBot/test/planner/marketSell.test.ts`,
  `services/rebalancingBot/test/panicFills.test.ts`,
  `services/rebalancingBot/test/sim/multi/final.ts`, `services/rebalancingBot/test/sim/multi/harness/*`,
  `docs/testbook.md`, `docs/audits/2026_11_15_Unstaking_shMON_Vault_Audit/report.md`.
- Research data: `services/rebalancingBot/test/sim/{instantExits,instantExitHistory,shmonadHistory,unstakeTiming,backfill,replay}.ts`,
  `exitMm.sim.ts`, with outputs under this repo's `evidence/data/`.
- Euler cluster and EulerSwap: `sources/ag-euler/contracts/shmon-cluster-monad/deploy.sh` and `deployed-143.env`,
  `sources/ag-euler/contracts/eulerswap-mm-monad/deploy-mm.sh` and `deployed-143.env`, `src/exitmm/UnstakingShMonVault.sol`; EulerSwap itself at upstream `a8493f8`: `src/EulerSwap.sol`, `src/EulerSwapFactory.sol`,
  `src/EulerSwapManagement.sol`, `src/EulerSwapPeriphery.sol`, `src/UniswapHook.sol`, `src/libraries/FundsLib.sol`,
  `src/libraries/QuoteLib.sol`, `src/libraries/SwapLib.sol`, `src/interfaces/*.sol`.
- ushMON: `ushMON/src/UnstakingShMonVault.sol`, `test/UnstakingShMonVault.t.sol`, `test/UnstakingShMonVaultV4.t.sol`,
  `test/UnstakingShMonVault.donation.t.sol`, `test/UnstakingShMonVault.fork.t.sol`, `script/Deploy.s.sol`, `README.md`,
  issues 1 to 11.
