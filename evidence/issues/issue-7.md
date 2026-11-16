title:	[Low] A 1-wei withdrawal makes an exact-balance startUnstake revert
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
number:	7
--
## Summary

`startUnstake(shmonAmount)` passes the amount straight to shMonad, which reverts if it exceeds the vault's balance. Any holder can front-run with `withdraw(1)`, so an unstake of the full balance reverts. Confirmed on a fork against the live shMonad.

With the fix in #1, only a holder of seized shares can do this.

## Location

[`startUnstake`](https://github.com/rootdraws/ushMON/blob/a7f478847134a5ff5afdb672ddd97398b3eae713/src/UnstakingShMonVault.sol#L99-L103)

## Suggested fix

Clamp `shmonAmount` to the vault's shMON balance, or treat `type(uint256).max` as "everything".

