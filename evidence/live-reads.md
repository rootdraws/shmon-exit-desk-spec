# Live reads from Monad, 2026-11-16

Read with `cast call ... -r https://rpc.monad.xyz`. The first block of reads is pinned at block **122821118**
(19:22Z); the Neverland reads ran at block **122821632** (19:24Z) because the public RPC refused pinned historical calls
for those contracts.

## shMonad (`0x1B68626dCa36c7fE922fD2d55E4f631d962dE19c`), block 122821118

| Read | Raw | Meaning |
|---|---|---|
| `getCurrentLiquidity()` | 3923397637904068570734167 | 3,923,398 MON payable at once |
| `getTargetLiquidity()` | 6577623553940831597975256 | 6,577,624 MON target |
| `getCurrentUnstakeFeeRateRay()` | 4085235361632309790000000 | 0.4085% instant-exit fee |
| `convertToAssets(1e18)` | 1653331897405858488 | 1.6533 MON per shMON |
| `totalAssets()` | 329864882771041299167662454 | 329,864,883 MON staked through shMonad |

## The Euler cluster (ag-euler `contracts/shmon-cluster-monad/deployed-143.env`), block 122821118

| Vault | Address | cash | totalBorrows | caps (supply, borrow) | governorAdmin |
|---|---|---|---|---|---|
| shMON | 0xD81D3E243760eD23Ac3DEf2b08d4989bA2790Dfe | 0 | 0 | 12826, 1 | 0x501107fe590c8F9b81c00b81867fD19e0d9c0253 |
| USDC | 0x5aB09A3EDbb0937Db454f54e6CF04Dd982c40948 | 0 | 0 | 23053, 20749 | same |
| WMON | 0xE4522663752AC47516e39aD11d3780a116850eaf | 0 | 0 | 7450, 6682 | same |
| USDT0 | 0xD6645190976d456907c9807d08E4E4E220c96a3E | 0 | 0 | 23053, 20749 | same |

No vault on the cluster holds any deposit or loan. The caps decode to 36M USDC supply / 32.4M borrow, 116M WMON supply /
104M borrow, 36M USDT0 supply / 32.4M borrow (`deploy.sh:52-59`).

## Neverland (pool `0x80F00661b13CC5F6ccd3885bE7b4C9c67545D585`), block 122821632

Method: the bot's `lenders.ts:150-166` formula, room before the kink = aToken totalSupply × optimal usage − variable debt.

| Reserve | aToken | Variable debt token | Supplied | Borrowed | Utilization | Kink | Room before kink |
|---|---|---|---|---|---|---|---|
| USDC `0x7547…b603` | 0x38648958836eA88b368b4ac23b86Ad44B0fe7508 | 0xb26FB5e35f6527d6f878F7784EA71774595B249C | 3,241,762 | 2,592,410 | 80.0% | 90% | 325,176 USDC |
| USDT0 `0xe7cd…C82D` | 0x39F901c32b2E0d25AE8DEaa1ee115C748f8f6bDf | 0xa2d753458946612376ce6e5704Ab1cc79153d272 | 2,334,856 | 1,998,819 | 85.6% | 90% | 102,551 USDT0 |

Raw: USDC cash 649935918882, aToken supply 3241762411556, debt 2592410467688; USDT0 cash 336482670169, supply
2334855707407, debt 1998818659727; `getOptimalUsageRatio` = 900000000000000000000000000 on the strategy
`0x8E5Cf92853d3214C761bF239Af03caB24A071893`. From `getReserveData` at block 122821118: USDC variable borrow rate
5.33% and supply rate 2.98%; USDT0 variable borrow rate 5.71% and supply rate 3.42% (ray values 53303259486920133910292484,
29832993455264383202223363, 57060968788609527339610549, 34187518670494041614419419). Neverland's shMON aToken
`0xC64d73Bb8748C6fA7487ace2D0d945B6fBb2EcDe` totalSupply 29,543,124 shMON.

## The exit desks, block 122821118

| Desk | Address | VERSION | getEulerPosition | EVC collateral | EVC controller |
|---|---|---|---|---|---|
| usdc-hl | 0x02Df7fb3b4535361EE10C391e3bDDAEe9001c770 | 10600 (v1.6.0) | 0 shMON, 0 debt, pool 0x0 | 0xa44220Ee57Cb879bd842a24696Df06e398601d8F | 0xE4522663752AC47516e39aD11d3780a116850eaf |
| usdc-hl-d0 | 0xF460C4C68704Da32Ba3cefC2feEcaA3C3f3d6CdE | 10600 (v1.6.0) | 0 shMON, 0 debt, pool 0x0 | 0x066E1eb375369A00e324cF18Eb014B9AB0507690 | 0xE4522663752AC47516e39aD11d3780a116850eaf |

## The ushMON vaults in use (v1), block 122821118

| ushMON | totalAssets | totalSupply | maxDeposit(0x…01) |
|---|---|---|---|
| 0xa44220Ee57Cb879bd842a24696Df06e398601d8F | 0 | 0 | 2^256−1 (open deposit, v1) |
| 0x066E1eb375369A00e324cF18Eb014B9AB0507690 | 0 | 0 | 2^256−1 (open deposit, v1) |

## The strategy vaults, block 122821118

| Vault | Address | totalSupply | totalAssets |
|---|---|---|---|
| shmon-neverland-usdc-hl | 0xeEe3dAb9fc5d3833aE219F87A1Fbb68F3d4431D3 | 0 | 0 |
| shmon-neverland-usdc-hl-d0 | 0x187bEF1d746350B22e0Ab1FAfA2A96a6F4aF272C | 0 | 0 |

## Keys

Deployer / cluster governor `0x501107fe590c8F9b81c00b81867fD19e0d9c0253`: 400.533 MON (Root sent 400 MON on 2026-11-16 for the public buyer's float).

## After the release, 2026-11-17 03:00Z, block 122910315

Read with `cast call ... -b 122910315` against a Monad RPC. The release itself is in `evidence/release-mainnet/`.

| Read | Raw | Meaning |
|---|---|---|
| desk 0x02Df…c770 `VERSION()` | 10700 | exit desk v1.7.0 |
| desk 0xF460…6CdE `VERSION()` | 10700 | exit desk v1.7.0 |
| desk 0x02Df…c770 proxy implementation slot | 0xBE243F5e4215720080929eeCfe77047D2Fd2a410 | the v1.7.0 implementation |
| both desks `leaversWaiting()` | false | no unpaid withdrawal batch, so the pools quote |
| EVC `getCollaterals(0x02Df…c770)` | [0xC8f5023512c0618B754e03d675E3626a4A760092] | the usdc-hl desk's only collateral is its v2 ushMON |
| EVC `getCollaterals(0xF460…6CdE)` | [0xa2F34235e4C3c0706B2d5B9170F924446b1Df664] | the usdc-hl-d0 desk's only collateral is its v2 ushMON |
| EVC `getControllers(desk)`, both | [0xE4522663752AC47516e39aD11d3780a116850eaf] | the cluster's WMON vault is the only controller |
| ushMON 0xC8f5…0092 `totalAssets()` / `totalSupply()` | 48378465460292174847 / same | 48.378 shMON parked, every share held by the desk |
| ushMON 0xa2F3…f664 `totalAssets()` / `totalSupply()` | 48378465284963347614 / same | 48.378 shMON parked, every share held by the desk |
| ushMON `operator()`, each | its desk | |
| ushMON `maxDeposit(0x…dEaD)`, each | 0 | an outsider cannot mint (issue 1) |
| WMON vault `LTVFull(ushMON)`, each | 9300 9500 | borrow 93%, liquidation 95% |
| WMON vault `cash()` / `totalBorrows()` / `totalSupply()` | 929877902021124257818 / 0 / 929877902021124257818 | 929.88 WMON lent, nothing borrowed yet |
| pools 0x9028…A8a8 and 0x748a…28a8 `codesize` | 246 | EulerSwap's minimal proxies are deployed |
| dev key 0x5011…0253 balance | 9.961 MON | kept for gas |
| shMonad `convertToAssets(1e18)` | 1653489353626380593 | 1.6535 MON per shMON |

## After the one-vault release, 2026-11-17 18:41Z, block 123091651

Read with `cast call ... -r https://rpc2.monad.xyz`. The release itself is in `evidence/release-ush3/`.

| Read | Raw | Meaning |
|---|---|---|
| desk 0x02Df…c770 `VERSION()` | 10800 | exit desk v1.8.0 |
| desk 0xF460…6CdE `VERSION()` | 10800 | exit desk v1.8.0 |
| EVC `getCollaterals(desk)`, both | [0x37e07473F1F62CB071Db57440e242b320614A0ce] | both desks' only collateral is the one ushMON v3 |
| EVC `getControllers(desk)`, both | [0xE4522663752AC47516e39aD11d3780a116850eaf] | the cluster's WMON vault is the only controller |
| both desks `leaversWaiting()` | false | no unpaid withdrawal batch, so the pools quote |
| desk 0x02Df…c770 `getEulerPosition()` | 48378465460292174847, 0, 0xA65De145091aaa6e4540830A34Fc098dE3E668a8 | 48.378 shMON of ushMON, no loan, its pool |
| desk 0xF460…6CdE `getEulerPosition()` | 48378465284963347614, 0, 0x6e44D5d4c8a4dA51027A71789934bA33799ca8a8 | 48.378 shMON of ushMON, no loan, its pool |
| ushMON v3 `operators()` | [0x02Df7fb3b4535361EE10C391e3bDDAEe9001c770, 0xF460C4C68704Da32Ba3cefC2feEcaA3C3f3d6CdE] | both desks |
| ushMON v3 `totalAssets()` / `totalSupply()` | 96756930745255522461 / same | 96.757 shMON parked, every share held by the two desks |
| ushMON v3 `balanceOf(desk)` | 48378465460292174847 / 48378465284963347614 | each desk's own shares |
| ushMON v3 `ledgerOf(desk)`, both | [] | no unstake on either ledger |
| ushMON v3 `wmonCredit(desk)`, both; `creditTotal()`; `sharedWmon()` | 0; 0; 0 | no WMON back yet |
| router `resolvedVaults(ushMON v3)` | 0x1B68626dCa36c7fE922fD2d55E4f631d962dE19c | priced as shMON |
| WMON vault `LTVFull(ushMON v3)` | 9300 9500 | borrow 93%, liquidation 95% |
| WMON vault `cash()` / `totalBorrows()` | 929877902021124257818 / 0 | 929.88 WMON lent, nothing borrowed |
| WMON vault `caps()` | 46554 41882 | 727M WMON supply, 654M borrow (about $10M at $0.01529 per MON; set 2026-11-17) |
| USDC vault 0x5aB0…0948 `caps()` | 32012 28812 | 5M supply, 4.5M borrow (set 2026-11-17) |
| USDT0 vault 0xD664…963E `caps()` | 32012 28812 | 5M supply, 4.5M borrow (set 2026-11-17) |
| ushMON v2 0xC8f5…0092 and 0xa2F3…f664 `totalAssets()` / `totalSupply()` | 0 / 0 | emptied by `unparkShmon`, no longer used |
| shMonad `convertToAssets(1e18)` | 1653785613860073299 | 1.6538 MON per shMON |

The pools' quotes were read back by the release script at the time of the release (`evidence/release-ush3/release-ush3-mainnet.log`): each pool
quotes a fee of 2.2549% under its ceiling for shMON in (the rate less 0.30%) and refuses WMON in.

## 2026-11-18, block 123,359,143 (public RPC rpc2.monad.xyz), read for the spec's verity pass

| Read | Value |
|---|---|
| Settings `VERSION()` on 0xdE30…dEC and 0xC62D…F85a | 11600 on both |
| Settings `getPerformanceFee()` on both | 1000 bps, recipient 0xC94dd8e928D681bd85BeB94a8729709d189cCF9D |
| Executor, oracle, guardian and admin roles on both Settings | `hasRole` true for every key named in 02-alpha-structures.md |
| Admin Safe 0xC94d…9CfD on Monad and HyperEVM | owner 0xb9a8…681B, threshold 1, module 0x6c3A…3D4d |
| Hedge Safes 0x704f…C6ed and 0x213a…61C3 on HyperEVM | owner the admin Safe, threshold 1, modules 0x0253…0Cba and 0x0Aa4…9028 |
| Router v2 0xE1fe…3776 `owner()`; exit bid pools `keeper()` | 0xEE51…c3A7 on all three |
| Exit desks `VERSION()` | 10800 on both; `leaversWaiting()` false on both; WMON debt 0 on both |
| ushMON v3 0x37e0…A0ce | totalAssets 96.7569 shMON, each desk 48.3785 shares |
| WMON vault 0xE452…0eaf | cash 929.8779 WMON, borrows 0, caps raw 46554 / 41882 (727M / 654M); the deployer holds 929.8779 shares |
| WMON vault LTV against ushMON v3 / v2 pair / v1 pair / shMON | 93/95 / 0/0 / 0/0 / 97/98 |
| Router `resolvedVaults` | v3 and the shMON vault resolve to shMON; the v1 and v2 vaults resolve to nothing |
| USDC and USDT0 vaults | cash 0, borrows 0, caps raw 32012 / 28812 (5M / 4.5M); governor the deployer key |
| Strategy vaults `totalSupply()` / `totalAssets()` | 0 / 0 on both |
| Withdrawal handlers `getExitFeeBps()` | 30 on both, `VERSION()` 11100 |

## Production server, 2026-11-18 18:38Z (SSH `alphastructures-prod-deploy`)

`docker ps`, 12 containers: api, bot-shmon-neverland-usdc-hl, bot-shmon-neverland-usdc-hl-d0, caddy, funding-feed,
monad-digester, mongodb, monitor, oracle-hyperliquid, research-refresh, rpc-meter, www-user.
`env/.env.caddy`: `APP_HOST=monad.structures.gg`. Service image `staging` = `exitqueue-20261118`, built 2026-11-18 14:12:25Z.

Addresses derived from the containers' key variables (values never printed):

| Variable | Address |
|---|---|
| EXECUTOR_SHMON_NEVERLAND_USDC_HL_PRIVATE_KEY | 0xC95F60fdE77ECEBf9DED1228A939ac8eDB2671D3 |
| EXECUTOR_SHMON_NEVERLAND_USDC_HL_D0_PRIVATE_KEY | 0xF3206EfC847386E66043459832eDb74998C63669 |
| ORACLE_SHMON_NEVERLAND_USDC_HL_PRIVATE_KEY | 0x77d550f9C11AAFC69Cb7651d7B2E405BE43Eb0B9 |
| ORACLE_SHMON_NEVERLAND_USDC_HL_D0_PRIVATE_KEY | 0x2ECF679c2DF38a758F365f1EEc7CD090567FD5e7 |
| GUARDIAN_PRIVATE_KEY | 0x868736358fA307d70b359BcaB2e92e6A7ED0734C |
| MONAD_DIGESTER_KEEPER_PRIVATE_KEY (monad-digester only) | 0xEE51d642304f8F0b272Fc79cf851CE76ee24c3A7 |

`DEPLOYER_PRIVATE_KEY` absent and no Hyperliquid key in the API container.
