# The shMON vaults, their exit desk, ushMON and the public shMON buyer

A product specification of Alpha Structures' shMON vaults on Monad and the machinery that turns a leaver's shMON back
into stablecoin: the exit desk, the unstaking shMON vault (ushMON), the digester pool, and the EulerSwap pool that buys
shMON from anyone at shMonad's rate less 0.3%.

Written 2026-11-16 from the code at the commits named in [10-references.md](10-references.md). Every claim cites a file
and line at that commit, or an evidence file in [`evidence/`](evidence/) with the date it was read. Where two sources
disagree, the spec says so and says which one was checked on chain.

## Reading order

| File | What it answers |
|---|---|
| [01-overview.md](01-overview.md) | What the product is, who it serves, why leaving shMON is the hard part, and the state today |
| [02-alpha-structures.md](02-alpha-structures.md) | How a strategy vault works: lenders, hedge, NAV, withdrawals, the two production vaults |
| [03-exit-desk.md](03-exit-desk.md) | Why the exit desk exists and what it does: the unstake, resting orders, the digester, the WMON route |
| [04-ushmon.md](04-ushmon.md) | The unstaking shMON vault: what it holds, who may deposit, v1 to v2, the audit, the tests |
| [05-eulerswap.md](05-eulerswap.md) | How EulerSwap works, the desk's pool, and what capital it needs |
| [06-euler-cluster-and-neverland.md](06-euler-cluster-and-neverland.md) | The lenders: our Euler cluster on Monad and Neverland |
| [07-market-data.md](07-market-data.md) | How much shMON turns into MON and how, fees, pool depth, lending room, digestion rate |
| [08-testing.md](08-testing.md) | What was tested, how, and the results, with logs and rerun commands |
| [09-current-state-and-next.md](09-current-state-and-next.md) | What is live, what is in flight, open decisions, known risks |
| [10-references.md](10-references.md) | Every repo, commit, contract address and file cited |

## The repos

| Repo | What it holds | Commit used | Access |
|---|---|---|---|
| [alphagrowth/alphastructures](https://github.com/alphagrowth/alphastructures) | The vault system: contracts, bot, oracle, keeper, docs, fork harness | `bd9a894` (master, 2026-11-16) | private |
| [KyrilVlasenko/ag-euler](https://github.com/KyrilVlasenko/ag-euler) | The Euler cluster on Monad, the EulerSwap v2 deployment, the deploy scripts | `6ecd9ad` (2026-11-12) | private |
| [rootdraws/ushMON](https://github.com/rootdraws/ushMON) | The unstaking shMON vault, its tests, its issues | `a7f4788` (v1); v2 in the working tree, see [04-ushmon.md](04-ushmon.md) | public |
| [rootdraws/shmon-exit-desk-spec](https://github.com/rootdraws/shmon-exit-desk-spec) | This spec and its evidence | this repo | private |

Upstream code the system is built on: [euler-xyz/ethereum-vault-connector](https://github.com/euler-xyz/ethereum-vault-connector),
[euler-xyz/euler-vault-kit](https://github.com/euler-xyz/euler-vault-kit), [euler-xyz/euler-price-oracle](https://github.com/euler-xyz/euler-price-oracle),
[euler-xyz/euler-swap](https://github.com/euler-xyz/euler-swap) (EulerSwap v2, BUSL-1.1), [OpenZeppelin/openzeppelin-contracts](https://github.com/OpenZeppelin/openzeppelin-contracts) 5.2.0,
[OpenZeppelin/uniswap-hooks](https://github.com/OpenZeppelin/uniswap-hooks) (the LimitOrderHook), [Uniswap/v4-core](https://github.com/Uniswap/v4-core),
[Uniswap/v4-periphery](https://github.com/Uniswap/v4-periphery), [foundry-rs/forge-std](https://github.com/foundry-rs/forge-std).
shMonad is Fastlane's liquid staking token on Monad, contract `0x1B68626dCa36c7fE922fD2d55E4f631d962dE19c`.

## How to verify

```sh
# the vault and its unit tests (public)
git clone --recurse-submodules https://github.com/rootdraws/ushMON && cd ushMON && forge test -vv

# the fork cycle test (needs the alphastructures repo and a Monad RPC)
cd alphastructures/contracts && FORK_MONAD=true MONAD_RPC_URL=<rpc> \
  npx hardhat test test/NeverlandMarketAdapter/ShMonadExitUsh2.fork.test.ts

# the live state the spec quotes, at the block named in evidence/live-reads.md
cast call 0x02Df7fb3b4535361EE10C391e3bDDAEe9001c770 'VERSION()(uint256)' -r https://rpc.monad.xyz
```

The outputs recorded on 2026-11-16 are in [`evidence/`](evidence/): `forge-test.txt`, `hardhat-fork-ush2.txt`, the
five-stage harness runs under `harness/`, the fork rehearsal of the release in `rehearsal-fork.log`, the audit report,
the eleven GitHub issues open on the vault, the research data under `data/`, and `live-reads.md`.

## For another Claude

Clone the three repos at the commits above, read this spec in order, then the files it cites. The system's own guides
are `alphastructures/AGENTS.md` and `alphastructures/docs/*.md`; the Euler cluster's is
`ag-euler/contracts/shmon-cluster-monad/deploy.sh` (its header comment); the vault's is `ushMON/README.md`.
