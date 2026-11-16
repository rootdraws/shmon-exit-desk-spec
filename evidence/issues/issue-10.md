title:	[Low] totalAssets reads raw balances, so a transfer to the vault moves the share price
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
number:	10
--
## Summary

`totalAssets` uses `balanceOf` for shMON and WMON. Sending either token to the vault raises the share price in one step: a 10% donation raised it 10% in a run. Euler's `ERC4626EVC`, which this vault follows, tracks `_totalAssets` in storage instead.

No profitable use was found. The donor loses the donation pro rata, and the 1e6 virtual amount blunts first-deposit inflation. It matters if the WMON vault's oracle prices ushMON through `convertToAssets`.

## Location

[`totalAssets`](https://github.com/rootdraws/ushMON/blob/a7f478847134a5ff5afdb672ddd97398b3eae713/src/UnstakingShMonVault.sol#L78-L81)

## Suggested fix

Track the shMON and WMON held in storage, updated on deposit, withdraw, `startUnstake`, `completeUnstake` and `redeemForWmon`.

