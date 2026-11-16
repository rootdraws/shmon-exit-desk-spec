title:	[Low] Assets in the unstake earn nothing, and every holder shares that cost
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
number:	9
--
## Summary

MON pending in the unstake and WMON held are fixed in MON, so they stop earning shMON's yield. `totalAssets` spreads that cost across all shares, not only those of the holder who is exiting.

Example (run): two holders with 1,000 shMON each, half the vault sent into the unstake, shMON's rate rises 1%. The holder who is not exiting gains 0.5%.

## Location

[`totalAssets`](https://github.com/rootdraws/ushMON/blob/a7f478847134a5ff5afdb672ddd97398b3eae713/src/UnstakingShMonVault.sol#L78-L81)

## Suggested fix

The fix in #1 (shares minted only to the operator) removes this, because there is one holder. Otherwise unstakes need per-holder accounting.

