title:	[Low] Operator is a single immutable address with no rotation
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
number:	5
--
## Summary

`operator` is immutable and is the only address that can call `startUnstake`. It cannot be rotated.

- **Key lost:** no new unstake can start, so the vault can no longer produce WMON.
- **Key stolen:** the holder can keep sending all the shMON into the unstake. shMON redemptions revert until maturity, and the assets earn nothing while pending. It cannot take funds.

## Location

- [`operator`](https://github.com/rootdraws/ushMON/blob/a7f478847134a5ff5afdb672ddd97398b3eae713/src/UnstakingShMonVault.sol#L47)
- [`startUnstake`](https://github.com/rootdraws/ushMON/blob/a7f478847134a5ff5afdb672ddd97398b3eae713/src/UnstakingShMonVault.sol#L99-L103)

## Suggested fix

Make the operator a two-step transferable role, or deploy with a multisig as operator.

