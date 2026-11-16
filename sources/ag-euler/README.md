# Copies from ag-euler (local working tree, 2026-11-16)

The GitHub remote of `KyrilVlasenko/ag-euler` is behind the local tree the spec was written from: the cluster project
`contracts/shmon-cluster-monad` and the EulerSwap deployment `contracts/eulerswap-mm-monad` are not on the remote's
`main`. These copies are the team's own files the spec cites, taken from the local tree at commit `6ecd9ad` plus the
uncommitted v2 vault (`contracts/eulerswap-mm-monad/src/exitmm/UnstakingShMonVault.sol`) and the uncommitted
`deployed-143.env` lines. The EulerSwap source is not copied: the deployed copy matches upstream
[euler-xyz/euler-swap](https://github.com/euler-xyz/euler-swap) at `a8493f8` byte for byte, and the spec cites that.
Line numbers in the spec refer to these files. `lib/` (EVC, EVK, OpenZeppelin, Uniswap v4, forge-std) is not copied;
the upstream repos are linked in `10-references.md`.
