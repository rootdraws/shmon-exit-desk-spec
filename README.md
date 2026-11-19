# The shMON vaults, their exit desk, ushMON and the public shMON buyer

A product specification of Alpha Structures' shMON vaults on Monad and the machinery that turns a leaver's shMON back
into stablecoin: the exit desk, the unstaking shMON vault (ushMON), the digester pool, and the EulerSwap pool that buys
shMON from anyone at shMonad's rate less 0.3%.

Written 2026-11-16, and checked page by page against the code and the chain on 2026-11-19 at the commits named in
[10-references.md](10-references.md). Every claim cites a file
and line at that commit, or an evidence file in [`evidence/`](evidence/) with the date it was read. Where two sources
disagree, the spec says so and says which one was checked on chain.

## Reading order

| File | What it answers |
|---|---|
| [01-overview.md](01-overview.md) | What the product is, who it serves, why leaving shMON is the hard part, and the state today |
| [02-operations.md](02-operations.md) | How a strategy vault works: settings, the bot's rules, the keys, the two production vaults |
| [03-exit-desk.md](03-exit-desk.md) | Why the exit desk exists and what it does: the unstake, resting orders, the digester, the WMON route, the emergency sale |
| [04-ushmon.md](04-ushmon.md) | The unstaking shMON vault: what it holds, who may deposit, v1 to v4, the audit, the tests |
| [05-eulerswap.md](05-eulerswap.md) | How EulerSwap works, the desk's pool, and what capital it needs |
| [06-euler-cluster-and-neverland.md](06-euler-cluster-and-neverland.md) | The lenders: our Euler cluster on Monad and Neverland |
| [07-market-data.md](07-market-data.md) | How much shMON turns into MON and how, fees, pool depth, lending room, digestion rate |
| [08-testing.md](08-testing.md) | What was tested, how, and the results, with logs and rerun commands |
| [09-current-state-and-next.md](09-current-state-and-next.md) | What is live, what is in flight, open decisions, known risks |
| [10-references.md](10-references.md) | Every repo, commit, contract address and file cited |
| [11-ltv-study.md](11-ltv-study.md) | How much the WMON vault may lend against ushMON: the oracle, its divergence, the rates, the fork simulation, the recommendation (issue 6) |
| [12-revenue-flows.md](12-revenue-flows.md) | What makes money, how much at a given TVL, and where each fee goes |

## The repos

| Repo | What it holds | Commit used | Access |
|---|---|---|---|
| [alphagrowth/alphastructures](https://github.com/alphagrowth/alphastructures) | The vault system: contracts, bot, oracle, keeper, docs, fork harness | branch `shmon-release-2026-11-18` at `0572c2a` (2026-11-19) | private |
| [KyrilVlasenko/ag-euler](https://github.com/KyrilVlasenko/ag-euler) | The Euler cluster on Monad, the EulerSwap v2 deployment, the deploy scripts | local working tree on 2026-11-19 (last commit `6ecd9ad`, 2026-11-12, with uncommitted edits since); the remote is behind it, so the cited files are copied under [`sources/ag-euler/`](sources/ag-euler/) | private |
| [rootdraws/ushMON](https://github.com/rootdraws/ushMON) | The unstaking shMON vault, its tests, its issues | `b3ba1bf` (v4, live 2026-11-18) | public |
| [rootdraws/shmon-exit-desk-spec](https://github.com/rootdraws/shmon-exit-desk-spec) | This spec and its evidence | this repo | private |

Upstream code the system is built on: [euler-xyz/ethereum-vault-connector](https://github.com/euler-xyz/ethereum-vault-connector),
[euler-xyz/euler-vault-kit](https://github.com/euler-xyz/euler-vault-kit), [euler-xyz/euler-price-oracle](https://github.com/euler-xyz/euler-price-oracle),
[euler-xyz/euler-swap](https://github.com/euler-xyz/euler-swap) at `a8493f8` (EulerSwap v2, BUSL-1.1; the deployed copy matches it byte for byte), [OpenZeppelin/openzeppelin-contracts](https://github.com/OpenZeppelin/openzeppelin-contracts) 5.2.0,
[OpenZeppelin/uniswap-hooks](https://github.com/OpenZeppelin/uniswap-hooks) (the LimitOrderHook), [Uniswap/v4-core](https://github.com/Uniswap/v4-core),
[Uniswap/v4-periphery](https://github.com/Uniswap/v4-periphery), [foundry-rs/forge-std](https://github.com/foundry-rs/forge-std).
shMonad is Fastlane's liquid staking token on Monad, contract `0x1B68626dCa36c7fE922fD2d55E4f631d962dE19c`.

## How to verify

```sh
# the vault and its tests (public; the two fork tests skip without MONAD_RPC_URL)
git clone --recurse-submodules https://github.com/rootdraws/ushMON && cd ushMON && MONAD_RPC_URL=<rpc> forge test -vv

# the emergency sale fork test (needs the alphastructures repo and a Monad RPC)
cd alphastructures/contracts && FORK_MONAD=true MONAD_RPC_URL=<rpc> MONAD_FORK_BLOCK=123554000 \
  npx hardhat test test/NeverlandMarketAdapter/ShMonadExitPanic.fork.test.ts

# the live state the spec quotes; evidence/live-reads.md names each read's block
cast call 0x02Df7fb3b4535361EE10C391e3bDDAEe9001c770 'VERSION()(uint256)' -r https://rpc.monad.xyz
```

The recorded outputs, 2026-11-16 to 2026-11-19, are in [`evidence/`](evidence/):

- **Tests:** `forge-test-v4-all.txt`, `hardhat-fork-panic.txt`, `hardhat-fork-desk-2026-11-19.txt`,
  `bot-emergency-sale-tests.txt`, and the five-stage harness runs under `harness/`.
- **Releases:** the fork rehearsals in `rehearsal-fork*.log` and `release-ush3/rehearsal-ush3.log`, and the mainnet
  logs under `release-mainnet/` and `release-ush3/`.
- **Audit:** the report, and the eleven GitHub issues on the vault under `issues/`, all closed.
- **Data:** the research data under `data/`, and the chain reads in `live-reads.md`.

## For another Claude

Clone the three repos at the commits above, read this spec in order, then the files it cites. The system's own guides
are `alphastructures/AGENTS.md` and `alphastructures/docs/*.md`; the Euler cluster's is
`sources/ag-euler/contracts/shmon-cluster-monad/deploy.sh` here (its header comment); the vault's is `ushMON/README.md`.
