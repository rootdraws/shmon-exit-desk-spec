# 2. Alpha Structures: the vault system

Repo: [alphagrowth/alphastructures](https://github.com/alphagrowth/alphastructures) at `bd9a894`. The system's own
guide is `AGENTS.md`; the design docs are under `docs/`.

## The strategy in one loop

"Each vault supplies its collateral asset to a lending market, borrows a stablecoin against it, buys more collateral
with the loan, and holds a Hyperliquid perp short that sets the vault's exposure to a fixed resting delta (0 or 1; …)."
(`docs/Alpha_Structures_Architecture.md:5`.) The loop repeats until the vault's loan-to-value reaches its target; there
is no fixed loop count (`Architecture.md:324`). Net profit is funding received on the short less the borrow cost
(`Architecture.md:314-324`).

- **Book shape.** The short equals the collateral exposure less `d` times equity, so the book rests at `d` dollars of
  delta per dollar of equity (`CLAUDE.md:55`). `d` is 1 on the `-hl` vaults and 0 on the `-d0` vaults, held on chain in
  `StrategyControllerSettings` and changeable only by the admin Safe (`CLAUDE.md:34-37`).
- **Target LTV.** The lowest of the liquidation threshold times one minus the worst recorded 24-hour fall, 95% of the
  threshold, and a code clamp under the tripwires (`services/rebalancingBot/src/policy/worstFallPolicy.ts`). The shMON
  vaults use a 34.48% worst fall measured on Binance futures MONUSDT (production configs, `runtime.worstFall`).
- **Tripwires.** Target 45%, controlled unwind at 55%, panic unwind at 66.5% LTV (`risk` block of each production config).
- **Hedge.** Hyperliquid, margin ratio 2857 bps (3.5x) on the shMON vaults; no trading key exists, every order is a
  CoreWriter call from a Safe through its Roles module (`docs/Alpha_Structures_Threat_Model.md:166`).

## Two lenders

The shMON vaults borrow from Neverland, an Aave v3 fork on Monad, and from the Euler cluster the team deployed
(`CLAUDE.md:32`, `Architecture.md:10-11,29`). Each lender has its own LTV lines scaled to its liquidation threshold.
The bot sizes a borrow by the lender's room before its rate kink: free cash, capped so utilization stays at or under the
kink (`services/rebalancingBot/src/lenders.ts:128-166`). A **stable desk** moves USDC debt to USDT0 when Neverland's USDC
is past its kink (`Architecture.md:10-11`). The cluster is described in
[06-euler-cluster-and-neverland.md](06-euler-cluster-and-neverland.md).

## NAV and the share price

The NAV oracle sums market collateral less debt at every lender, controller balances, the stable desk's net position,
the exit desk's holdings (idle tokens, pending unstake, open orders, and its Euler account: parked shMON less the WMON
loan), venue equity and venue-wallet balances, and publishes an asset-denominated share price with `setSharePrice`
(`docs/Alpha_Structures_System_Overview.md:127-136`). "The published share price is measured, never forecast"
(`System_Overview.md:138`). NAV posts every 30 minutes, or every 2 hours on an empty vault (`CLAUDE.md`, idle vaults).

## Withdrawals

Every redemption request joins a batch. A batch settles at the lower of the request-time and fulfilment-time share
price and pays pro rata by shares; shares redeem no sooner than one hour after the receiver's last deposit
(`System_Overview.md:77`). Every production config sets the batch window to 300 seconds plus the time the bot needs to
unwind (`System_Overview.md:140`). Since WithdrawalHandler v1.9.0 a batch settles 0.3% under its price-sized amount and
the difference stays with the holders who remain (`contracts/core/WithdrawalHandler.sol:34-35`, deduction at line 283,
`setExitFeeBps` at 523-527, set to 30 bps by the admin Safe in `custody/release-mm-143.ts:41,137`).

## The two production vaults

Configs: `deploy/configs/production/shmon-neverland-usdc-hl.json` and `shmon-neverland-usdc-hl-d0.json`. Manifests:
`deploy/deployments/production/*.json`. Both run on Monad (chain 143) with the same eight adapters in their configs: `neverland-market`,
`euler-market`, `shmonad-stake`, `across-bridge`, `uniswap-swap`, `curve-swap`, `stable-desk`, `shmonad-exit` (the
manifests also carry a `kyberswap` adapter proxy).

| Contract | shmon-neverland-usdc-hl (delta one) | shmon-neverland-usdc-hl-d0 (delta neutral) |
|---|---|---|
| Deployed | 2026-10-08, git 9040364 | 2026-10-31, git 17e8b65 |
| Vault (ERC-4626 shares) | [0xeEe3dAb9fc5d3833aE219F87A1Fbb68F3d4431D3](https://monadscan.com/address/0xeEe3dAb9fc5d3833aE219F87A1Fbb68F3d4431D3) | [0x187bEF1d746350B22e0Ab1FAfA2A96a6F4aF272C](https://monadscan.com/address/0x187bEF1d746350B22e0Ab1FAfA2A96a6F4aF272C) |
| StrategyController | 0xc27A2eA394c1499FA6261bd12f38D813C2DecB51 | 0x13B7aF96a7f1F7E0A4E228CcC0e437389492F5Ae |
| StrategyControllerSettings | 0xdE30DFdC5107D52c1Dec101db4afDC6a7372adEC | 0xC62D354c3B8fbBEEA9Bee2D35Da38e015770F85a |
| WithdrawalHandler | 0xFb78583f6D8A9F6c2cCae6111e2817AC9824162a | 0x4B821aFd90eF4F5a35Dec5e4AeeA7C00c7d90Af2 |
| Exit desk (`shmonad-exit` proxy) | [0x02Df7fb3b4535361EE10C391e3bDDAEe9001c770](https://monadscan.com/address/0x02Df7fb3b4535361EE10C391e3bDDAEe9001c770) | [0xF460C4C68704Da32Ba3cefC2feEcaA3C3f3d6CdE](https://monadscan.com/address/0xF460C4C68704Da32Ba3cefC2feEcaA3C3f3d6CdE) |
| Exit desk implementation | 0xBE243F5e4215720080929eeCfe77047D2Fd2a410 (v1.7.0, upgraded 2026-11-16, read on chain; v1.6.0 was 0x623E3EC3E218FcA770eF4bb5Ce5c1399F86Ba467) | same |
| Neverland adapter | 0x56251dbe…61C5 | 0xF79E5fA8…DC7D |
| Euler adapter | 0xa4a912E0…384d | 0x071b7277…5ABB |
| Stable desk | 0xc19aa853…599a | 0x2dCDEB8B…28f1 |
| Executor key | 0xC95F60fd…71D3 | 0xF3206EfC…3669 |

Full addresses for the abbreviated rows are in the manifests. Both vaults are empty at the time of writing
(`evidence/live-reads.md`).

## Roles

- **Admin.** `DEFAULT_ADMIN_ROLE` on every production vault is the admin Safe
  `0xC94dd8e928D681bd85BeB94a8729709d189cCF9D`, a 1-of-1 Safe owned by the `custody-admin` keystore on the operator's
  machine (`Threat_Model.md:181-186`). It upgrades contracts, moves the desk's Euler account, opens the EulerSwap pool.
- **Executor.** One key per vault, drives the bot's actions. "No executor-callable function sends funds to an arbitrary
  address" (`Threat_Model.md:149-164`).
- **Oracle.** One key per vault, posts the share price.
- **Guardian.** `pause`, `unpause` and `halt()` through a freeze module on the admin Safe (`Threat_Model.md:171-173`).
- **Keeper.** `0xEE51d642304f8F0b272Fc79cf851CE76ee24c3A7` fills digester orders; it pays gas and never holds vault money.

## Where it runs

One server, `3.211.84.65` (`docs/Alpha_Structures_Production_Server_Runbook.md:14`), running one bot container per
vault, one NAV oracle (`oracle-hyperliquid`), `monitor`, `funding-feed`, `api`, `www-user`, `caddy`, `research-refresh`,
`rpc-meter`, `digester-keeper` and `mongodb` (`Runbook:47-59`). Production is built on the server from
`/opt/alphastructures/src`, never from a developer machine (`CLAUDE.md`).
