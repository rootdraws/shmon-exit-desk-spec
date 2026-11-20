# The shMON vaults and their exit desk

A specification of Alpha Structures' shMON vaults on Monad, and of how a leaver's shMON turns back into stablecoin.
That covers the exit desk, the unstaking shMON vault (ushMON), the digester pool, and the EulerSwap pool that buys
shMON from anyone at shMonad's rate less 0.30%.

Checked page by page against the code and the chain on 2026-11-20. Claims cite the code or a dated file in
[`evidence/`](evidence/).

## Reading order

| Page | What it covers |
|---|---|
| [01-overview.md](01-overview.md) | What the product is, and why leaving shMON is the hard part |
| [02-operations.md](02-operations.md) | How a vault runs: its settings, the bot's rules, the keys and the two live vaults |
| [03-exit-desk.md](03-exit-desk.md) | What the exit desk does: the unstake, the digester, the WMON loan and the emergency sale |
| [04-ushmon.md](04-ushmon.md) | The unstaking shMON vault: how it works, its security review and its tests |
| [05-eulerswap.md](05-eulerswap.md) | The pool that buys anyone's shMON, and what capital it needs |
| [06-euler-cluster-and-neverland.md](06-euler-cluster-and-neverland.md) | The lenders: our Euler cluster and Neverland |
| [07-market-data.md](07-market-data.md) | How much shMON leaves, at what cost, and how much each route can carry |
| [08-testing.md](08-testing.md) | What was tested, the results, the logs and how to rerun them |
| [09-current-state-and-next.md](09-current-state-and-next.md) | What is live, what shipped, open decisions and known risks |
| [10-references.md](10-references.md) | Every repo, contract address and file cited |
| [11-ltv-study.md](11-ltv-study.md) | How much the WMON vault lends against ushMON, and why |
| [12-revenue-flows.md](12-revenue-flows.md) | What makes money, how much, and who gets it, with a [calculator](calculator/revenue-calculator.html) |

## The repos

| Repo | What it holds | Version used | Access |
|---|---|---|---|
| [alphagrowth/alphastructures](https://github.com/alphagrowth/alphastructures) | The vaults, the exit desk, the bot, the oracle, the keeper, the tests and the docs | branch `shmon-release-2026-11-18` at `a539a19` | private |
| [rootdraws/ushMON](https://github.com/rootdraws/ushMON) | The unstaking shMON vault and its tests | `b3ba1bf` | private |
| [rootdraws/shmon-exit-desk-spec](https://github.com/rootdraws/shmon-exit-desk-spec) | This spec, its evidence, and copies of our Euler deploy scripts under [`sources/ag-euler/`](sources/ag-euler/) | this repo | private |

The system builds on Euler's, OpenZeppelin's and Uniswap's open-source contracts, listed in
[10-references.md](10-references.md).

## How to verify

```sh
# ushMON's tests; the two fork tests skip without MONAD_RPC_URL
git clone --recurse-submodules https://github.com/rootdraws/ushMON && cd ushMON && MONAD_RPC_URL=<rpc> forge test -vv

# the emergency sale fork test
cd alphastructures/contracts && FORK_MONAD=true MONAD_RPC_URL=<rpc> MONAD_FORK_BLOCK=123554000 \
  npx hardhat test test/NeverlandMarketAdapter/ShMonadExitPanic.fork.test.ts

# a live read, for example the exit desk's version
cast call 0x02Df7fb3b4535361EE10C391e3bDDAEe9001c770 'VERSION()(uint256)' -r https://rpc.monad.xyz
```

The recorded outputs are in [`evidence/`](evidence/):

- **Tests:**
  - `bot-tests-2026-11-20.txt`, `forge-test-v4-all.txt`, `hardhat-fork-panic.txt` and `hardhat-fork-desk-2026-11-19.txt`.
  - The five-stage fork runs, under `harness/`.
- **Releases:** `release-pause-2026-11-20.txt` and `ltv-lines-2026-11-20.txt`, with their transaction hashes. Earlier
  releases are under `release-mainnet/` and `release-ush3/`.
- **Audit:** `audit-2026-11-15.md`, and the eleven ushMON issues under `issues/`, all closed.
- **Data:** the research data under `data/`, and the chain reads in `live-reads.md`.

## For another Claude

Clone the two code repos at the versions above, read this spec in order, then the files it cites. The system's own
guides are `alphastructures/AGENTS.md` and `alphastructures/docs/*.md`. The Euler cluster's is the header of
`sources/ag-euler/contracts/shmon-cluster-monad/deploy.sh`, and the vault's is `ushMON/README.md`.
