title:	[Medium] 98% liquidation LTV leaves about 2% for an exit that takes a day or more
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
number:	6
--
## Summary

The README lists ushMON as collateral on the WMON vault at 97% borrow and 98% liquidation LTV. A liquidator who seizes ushMON has about 2% of margin, but:

- only the operator can start an unstake;
- the unstake takes 20 to 28 hours (README), and shMonad adds two epochs when a request exceeds `getMaxUnstakeRequestAmountWithoutDelay()`;
- shMonad's `requestUnstake` and `completeUnstake` revert while shMonad is closed, and `totalAssets` keeps counting the pending MON at face value.

In a stress event a liquidation may not be worth doing, and the shortfall falls on WMON lenders.

**Not verified:** the WMON vault's oracle and liquidation settings are outside this repo. Related: #2.

## Suggested fix

Size the LTVs for the worst-case exit time and shMonad's instant-exit fee, or give a holder of seized shares a way to start an unstake.

