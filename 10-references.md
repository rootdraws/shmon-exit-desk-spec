# 10. References

## Repositories and commits

| Repo | Commit | Used for |
|---|---|---|
| [alphagrowth/alphastructures](https://github.com/alphagrowth/alphastructures) (private) | `be23722`, merged into master as `ef0f756` on 2026-11-18 | the vault system, exit desk, bot, harness, docs, audit |
| [KyrilVlasenko/ag-euler](https://github.com/KyrilVlasenko/ag-euler) (private) | local working tree on 2026-11-18 (last commit `6ecd9ad`, 2026-11-12, with uncommitted edits since); the remote lacks the cited projects, which are copied in this repo under [`sources/ag-euler/`](sources/ag-euler/) | the Euler cluster, EulerSwap v2 deployment, ushMON build artifact |
| [rootdraws/ushMON](https://github.com/rootdraws/ushMON) (public) | [`48d07b3`](https://github.com/rootdraws/ushMON/tree/48d07b3) (v3, live 2026-11-17); [`a7f4788`](https://github.com/rootdraws/ushMON/tree/a7f478847134a5ff5afdb672ddd97398b3eae713) (v1); [`4235998`](https://github.com/rootdraws/ushMON/tree/4235998) (v2, 2026-11-16) | the unstaking shMON vault |
| [euler-xyz/ethereum-vault-connector](https://github.com/euler-xyz/ethereum-vault-connector) | v1.0.1 | EVC, account status checks |
| [euler-xyz/euler-vault-kit](https://github.com/euler-xyz/euler-vault-kit) | vendored in ag-euler | the cluster's vaults; `maxRedeem` rule at `src/EVault/modules/Vault.sol:234-248` |
| [euler-xyz/euler-price-oracle](https://github.com/euler-xyz/euler-price-oracle) | `63f20a4` | the Chainlink SVR adapters and the router |
| [euler-xyz/euler-swap](https://github.com/euler-xyz/euler-swap) | [`a8493f8`](https://github.com/euler-xyz/euler-swap/tree/a8493f89764ce69a05915559d9061781b9a96f24), 2026-10-25; the vendored copy in `ag-euler/contracts/eulerswap-mm-monad/src/` matches it byte for byte (28 files) | the public buyer |
| [OpenZeppelin/openzeppelin-contracts](https://github.com/OpenZeppelin/openzeppelin-contracts) | 5.2.0 | ERC4626 base of ushMON |
| [OpenZeppelin/uniswap-hooks](https://github.com/OpenZeppelin/uniswap-hooks) | 1.3.0 | the digester's LimitOrderHook |
| [Uniswap/v4-core](https://github.com/Uniswap/v4-core), [Uniswap/v4-periphery](https://github.com/Uniswap/v4-periphery) | 1.0.1 | the PoolManager and hook base |
| [foundry-rs/forge-std](https://github.com/foundry-rs/forge-std) | 1.9.4 / 1.17 | tests |

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
| Exit desk implementation (v1.8.0, upgraded 2026-11-17) | [0xDF9515a5d2f68B12a4fAFc44e518B13751A1c3B2](https://monadscan.com/address/0xDF9515a5d2f68B12a4fAFc44e518B13751A1c3B2) | same |
| Settings implementation 1.16 (fee on every gain, upgraded 2026-11-18) | [0x6B25C62bB8732669174E42CD571839b4AAa3C113](https://monadscan.com/address/0x6B25C62bB8732669174E42CD571839b4AAa3C113) | same |
| Exit desk implementation v1.7.0 (replaced 2026-11-17) | [0xBE243F5e4215720080929eeCfe77047D2Fd2a410](https://monadscan.com/address/0xBE243F5e4215720080929eeCfe77047D2Fd2a410) | same |
| Exit desk implementation v1.6.0 (replaced) | [0x623E3EC3E218FcA770eF4bb5Ce5c1399F86Ba467](https://monadscan.com/address/0x623E3EC3E218FcA770eF4bb5Ce5c1399F86Ba467) | same |
| ushMON v3 (one vault, in use since 2026-11-17) | [0x37e07473F1F62CB071Db57440e242b320614A0ce](https://monadscan.com/address/0x37e07473F1F62CB071Db57440e242b320614A0ce) | same |
| EulerSwap pool (the public buyer, reopened 2026-11-17 on the v3 vault) | [0xA65De145091aaa6e4540830A34Fc098dE3E668a8](https://monadscan.com/address/0xA65De145091aaa6e4540830A34Fc098dE3E668a8) | [0x6e44D5d4c8a4dA51027A71789934bA33799ca8a8](https://monadscan.com/address/0x6e44D5d4c8a4dA51027A71789934bA33799ca8a8) |
| ushMON v2 (replaced 2026-11-17, empty) | [0xC8f5023512c0618B754e03d675E3626a4A760092](https://monadscan.com/address/0xC8f5023512c0618B754e03d675E3626a4A760092) | [0xa2F34235e4C3c0706B2d5B9170F924446b1Df664](https://monadscan.com/address/0xa2F34235e4C3c0706B2d5B9170F924446b1Df664) |
| EulerSwap pools of 2026-11-16 (retired by the account move) | [0x9028e8aF57Da3173B9136189A7E5f0c32d5eA8a8](https://monadscan.com/address/0x9028e8aF57Da3173B9136189A7E5f0c32d5eA8a8) | [0x748aD60aff8Fee5C552Cc7Cd480aE2D5226028a8](https://monadscan.com/address/0x748aD60aff8Fee5C552Cc7Cd480aE2D5226028a8) |
| ushMON v1 (replaced 2026-11-16) | [0xa44220Ee57Cb879bd842a24696Df06e398601d8F](https://monadscan.com/address/0xa44220Ee57Cb879bd842a24696Df06e398601d8F) | [0x066E1eb375369A00e324cF18Eb014B9AB0507690](https://monadscan.com/address/0x066E1eb375369A00e324cF18Eb014B9AB0507690) |
| Admin Safe | [0xC94dd8e928D681bd85BeB94a8729709d189cCF9D](https://monadscan.com/address/0xC94dd8e928D681bd85BeB94a8729709d189cCF9D) | same |

Source: `alphastructures/deploy/deployments/production/*.json`, `deploy/configs/production/*.json:306-307`.

**The digester and exit bid pools**

| Contract | Address | Source |
|---|---|---|
| LimitOrderHook | [0x94Df2bffA788BBd918179f4CCB5A22DbAD7e1040](https://monadscan.com/address/0x94Df2bffA788BBd918179f4CCB5A22DbAD7e1040) | OpenZeppelin uniswap-hooks |
| Digester pool | poolId `0x3957bb3c02c319231713c06853de9bfc8e7d1aaa276873cd65fc028efc0b1314` (WMON/USDC, fee 100, spacing 1) | `docs/Alpha_Structures_Digester.md:21` |
| Digester router v2 (owner: the keeper key) | [0xE1fe1Ea6677Ea56eEFD381045AAcf86D541C3776](https://monadscan.com/address/0xE1fe1Ea6677Ea56eEFD381045AAcf86D541C3776) | read on chain 2026-11-18 |
| MonadRouter v1 (replaced) | [0x77eB1B6aab832f3aD11A216Dfcb8613fdA15A088](https://monadscan.com/address/0x77eB1B6aab832f3aD11A216Dfcb8613fdA15A088) | `alphastructures/contracts/digester/MonadRouter.sol` |
| Keeper wallet | 0xEE51d642304f8F0b272Fc79cf851CE76ee24c3A7 | `custody/deployments/exit-pool-143.json` |
| ExitBidPool USDC | [0xEA93Cb7Af4bcdAfF8312BEe55dF369970070C4a9](https://monadscan.com/address/0xEA93Cb7Af4bcdAfF8312BEe55dF369970070C4a9) | `alphastructures/contracts/exit-pool/ExitBidPool.sol` |
| ExitBidPool WMON | [0xB03b966811eBd2E481a77d2ce118f8fA2c5fD716](https://monadscan.com/address/0xB03b966811eBd2E481a77d2ce118f8fA2c5fD716) | same |
| Uniswap v4 PoolManager | [0x188d586Ddcf52439676Ca21A244753fA19F9Ea8e](https://monadscan.com/address/0x188d586Ddcf52439676Ca21A244753fA19F9Ea8e) | |

**The Euler cluster (second cluster, 2026-11-09)**, `ag-euler/contracts/shmon-cluster-monad/deployed-143.env`

| Contract | Address |
|---|---|
| Oracle router | [0x99f7105CAC565Ac830cf2d66527FBb06dD322C32](https://monadscan.com/address/0x99f7105CAC565Ac830cf2d66527FBb06dD322C32) |
| shMON vault | [0xD81D3E243760eD23Ac3DEf2b08d4989bA2790Dfe](https://monadscan.com/address/0xD81D3E243760eD23Ac3DEf2b08d4989bA2790Dfe) |
| USDC vault | [0x5aB09A3EDbb0937Db454f54e6CF04Dd982c40948](https://monadscan.com/address/0x5aB09A3EDbb0937Db454f54e6CF04Dd982c40948) |
| WMON vault | [0xE4522663752AC47516e39aD11d3780a116850eaf](https://monadscan.com/address/0xE4522663752AC47516e39aD11d3780a116850eaf) |
| USDT0 vault | [0xD6645190976d456907c9807d08E4E4E220c96a3E](https://monadscan.com/address/0xD6645190976d456907c9807d08E4E4E220c96a3E) |
| ushMON for the retired usdt0 desks (in the working-tree `deployed-143.env` and `alphastructures/deploy/configs/retired/*.json:307`, not yet committed in ag-euler) | 0x8DB5BAA62968F8Ff971889F07C52e6BD7835Ad16, 0xE5c2612F36dC773D7d85D034F9c8E9171cE2Ef73 |
| SVR adapters: shMON/USD, WMON/USD, USDC/USD, USDT0/USD, shMON/WMON | 0x2B435c1D99A8D1667838d7d9a9d1636849E3eAB6, 0xe6a6243E10C3D01b723bC806Da0226425dc0fB9d, 0x74594f3CAc8B43DAF148c8ff5323C40440F18284, 0xBD48e8B62d39C2d3337A342Fd70Ef8ACD173519F, 0x0A75454cD9c15068C4bdB57ec0436D10B0906c6C |
| Rate curves: USDC/USDT0, WMON | 0xe743F06a8A2Dcc9565926a9b11513e957e1897c6, 0xa359026aae6c26Ba90B3D3AB78Fc483Da09DBa8a |
| Governor (deployer) | 0x501107fe590c8F9b81c00b81867fD19e0d9c0253 |
| AlphaGrowth Euler Safe (fee receiver, governor after handover) | 0x4f894Bfc9481110278C356adE1473eBe2127Fd3C |
| Ethereum Vault Connector | [0x7a9324E8f270413fa2E458f5831226d99C7477CD](https://monadscan.com/address/0x7a9324E8f270413fa2E458f5831226d99C7477CD) |

**EulerSwap v2 on Monad**, `ag-euler/contracts/eulerswap-mm-monad/deployed-143.env`: factory
[0xDD13DCECd0Da21158507385867d24ec56BF80484](https://monadscan.com/address/0xDD13DCECd0Da21158507385867d24ec56BF80484), periphery
[0xA4cBd6e277B7a531fF8525877a17bD31Cf28619B](https://monadscan.com/address/0xA4cBd6e277B7a531fF8525877a17bD31Cf28619B), implementation
0xdEDc0388113450eb380817a8770c853C660Caf6d, fee config 0x53fBE13F8852cc9AcB5750375112346EC76532d7, management
0xA25142Fc5d24675C1A72f418a3239782F85E4533. The retired pool on the first cluster: 0x9aF1E49D878A5721eC1FdDd76b2237Ff585Ee8a8.

**The first cluster (handed to the AlphaGrowth Safe 2026-11-09, no longer used)**: router 0x7F0a…2D06, WMON vault
0x4EF28f0DFb1DD3220388A751841c31F589e5dbE8, ushMON 0x10f5ef37b3b2d3A90CB8AAADB2605CdC0C81f911; and the older setup on
AlphaGrowth's eWMON-14 0xfE26b4EE9e7000e06B7Cb2fc614A4526e845e702 with ushMON 0x59f7f897322D5FdEFCa38beB78137559eD985F80
and 0xc0CA1086131046766956bBD030fe9595Cc8204a1 (`ag-euler/contracts/eulerswap-mm-monad/deployed-143.env`).

**Tokens and outside protocols**: shMON (shMonad, Fastlane) [0x1B68626dCa36c7fE922fD2d55E4f631d962dE19c](https://monadscan.com/address/0x1B68626dCa36c7fE922fD2d55E4f631d962dE19c);
WMON 0x3bd359C1119dA7Da1D913D1C4D2B7c461115433A; USDC 0x754704Bc059F8C67012fEd69BC8A327a5aafb603; USDT0
0xe7cd86e13AC4309349F30B3435a9d337750fC82D; Neverland pool [0x80F00661b13CC5F6ccd3885bE7b4C9c67545D585](https://monadscan.com/address/0x80F00661b13CC5F6ccd3885bE7b4C9c67545D585)
with aTokens shMON 0xC64d73Bb8748C6fA7487ace2D0d945B6fBb2EcDe, USDC 0x38648958836eA88b368b4ac23b86Ad44B0fe7508, USDT0
0x39F901c32b2E0d25AE8DEaa1ee115C748f8f6bDf.

## Files cited, by component

- Vault system: `alphastructures/AGENTS.md`, `CLAUDE.md`, `docs/Alpha_Structures_System_Overview.md`,
  `docs/Alpha_Structures_Architecture.md`, `docs/Alpha_Structures_Threat_Model.md`,
  `docs/Alpha_Structures_Production_Server_Runbook.md`, `docs/Alpha_Structures_Rebalancing_Policy.md`,
  `contracts/core/WithdrawalHandler.sol`, `deploy/configs/production/*.json`, `deploy/deployments/production/*.json`.
- Exit desk and digester: `contracts/adapters/venue/ShMonadExitAdapter.sol`, `contracts/digester/MonadRouter.sol`,
  `contracts/exit-pool/ExitBidPool.sol`, `docs/shmon-exit-desk-plan.md`, `docs/Alpha_Structures_Digester.md`,
  `services/rebalancingBot/src/planner/exitDesk.ts`, `services/rebalancingBot/src/lenders.ts`,
  `packages/shared/src/chain/exitDesk.ts`, `custody/release-mm-143.ts`, `custody/release-ml-143.ts`,
  `custody/release-ush2-143.ts`, `custody/deployments/exit-pool-143.json`.
- Tests: `contracts/test/NeverlandMarketAdapter/ShMonadExit*.fork.test.ts`,
  `services/rebalancingBot/test/sim/multi/final.ts`, `services/rebalancingBot/test/sim/multi/harness/*`,
  `docs/testbook.md`, `docs/audits/2026_11_15_Unstaking_shMON_Vault_Audit/report.md`.
- Research data: `services/rebalancingBot/test/sim/{instantExits,instantExitHistory,shmonadHistory,unstakeTiming,backfill,replay}.ts`,
  `exitMm.sim.ts`, with outputs under this repo's `evidence/data/`.
- Euler cluster and EulerSwap: `ag-euler/contracts/shmon-cluster-monad/deploy.sh`, `deployed-143.env`,
  `ag-euler/contracts/eulerswap-mm-monad/deploy-mm.sh`, `deployed-143.env`, `src/exitmm/UnstakingShMonVault.sol` (copies
  under `sources/ag-euler/`); EulerSwap itself at upstream `a8493f8`: `src/EulerSwap.sol`, `src/EulerSwapFactory.sol`,
  `src/EulerSwapManagement.sol`, `src/EulerSwapPeriphery.sol`, `src/UniswapHook.sol`, `src/libraries/FundsLib.sol`,
  `src/libraries/QuoteLib.sol`, `src/libraries/SwapLib.sol`, `src/interfaces/*.sol`.
- ushMON: `ushMON/src/UnstakingShMonVault.sol`, `test/UnstakingShMonVault.t.sol`, `test/UnstakeStandIn.sol`,
  `script/Deploy.s.sol`, `README.md`, issues 1 to 3.
