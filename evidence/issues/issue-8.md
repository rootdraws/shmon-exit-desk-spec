title:	[Low] completeUnstake reverts when nothing is matured, so a settle batch can be griefed
state:	OPEN
author:	ardey26 (Andre de Jesus)
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
number:	8
--
## Summary

The NatSpec says `completeUnstake` "completes every matured unstake". On the live shMonad the underlying call reverts when no request is matured (`CompletionEpochNotReached`) or none exists (`NoUnstakeRequestFound`), so the vault's call reverts too.

`completeUnstake` is permissionless. If a settle batch includes it as a step, anyone who calls it first makes the whole batch revert.

## Location

[`completeUnstake`](https://github.com/rootdraws/ushMON/blob/a7f478847134a5ff5afdb672ddd97398b3eae713/src/UnstakingShMonVault.sol#L105-L112)

## Suggested fix

Wrap the shMonad call in `try/catch` and return 0 when there is nothing to complete.

