title:	[Low] redeemForWmon emits no Withdraw event
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
number:	11
--
## Summary

`withdraw` and `redeem` emit ERC-4626's `Withdraw`. `redeemForWmon` burns shares and pays WMON but emits only the ERC-20 `Transfer`. Indexers that follow `Deposit` and `Withdraw` miss these redemptions.

## Location

[`redeemForWmon`](https://github.com/rootdraws/ushMON/blob/a7f478847134a5ff5afdb672ddd97398b3eae713/src/UnstakingShMonVault.sol#L116-L124)

## Suggested fix

Emit an event with the owner, receiver, shares burned and WMON paid.

