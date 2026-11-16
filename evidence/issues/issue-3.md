title:	[Medium] Native MON sent to the vault outside completeUnstake is frozen
state:	OPEN
author:	FSoaresDev (Fábio Soares)
labels:	
comments:	0
assignees:	
projects:	
milestone:	
issue-type:	
parent:	
sub-issues:	
sub-issues-completed:	
blocked-by:	
blocking:	
number:	3
--

## Summary

`receive()` accepts MON from anyone. `completeUnstake` wraps only the change in balance across shMonad's payment, and `totalAssets` does not count native MON. Any other MON that reaches the vault is never counted and can never be moved.

- **Severity:** Medium. Reachability 3, preconditions 1, impact 1. Total 5.

## Location

- [`receive()`](https://github.com/rootdraws/ushMON/blob/a7f478847134a5ff5afdb672ddd97398b3eae713/src/UnstakingShMonVault.sol#L66)
- [`completeUnstake` wraps `address(this).balance - before` only](https://github.com/rootdraws/ushMON/blob/a7f478847134a5ff5afdb672ddd97398b3eae713/src/UnstakingShMonVault.sol#L106-L112)
- [`totalAssets`](https://github.com/rootdraws/ushMON/blob/a7f478847134a5ff5afdb672ddd97398b3eae713/src/UnstakingShMonVault.sol#L78-L81)

## Reproduction

Run on a local anvil fork of Monad.

1. Send 10 MON to the vault. `totalAssets` does not change.
2. A matured request is completed. The 10 MON stay native.
3. Every holder exits. The 10 MON are still there.

A third party can also make shMonad pay its *own* MON to the vault: `redeem`/`withdraw` on shMonad with `receiver = vault`. In a run, 49.79 MON was stuck this way.

## Impact

- Only the sender's MON is lost.
- The vault's own unstaked MON is paid only inside its `completeUnstake`. No named shMonad entry point pays the vault's request by another path (run against each one).

## Suggested fix

- In `completeUnstake`, wrap all of `address(this).balance`, not just the change. Stray MON then becomes a donation to holders, as a WMON transfer already is.
- Restricting `receive()` to the unstaker does **not** close this, because the shMonad-routed payments arrive from shMonad.

