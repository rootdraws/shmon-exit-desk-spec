title:	[Medium] No tests in the repo, and the stand-in behaves differently from live shMonad
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
number:	4
--
## Summary

The repo has no tests. `test/` holds only `UnstakeStandIn.sol`, which differs from the live shMonad in ways the vault depends on:

| | Stand-in | Live shMonad |
|---|---|---|
| `requestUnstake` | pulls shMON with `transferFrom` | burns from `msg.sender` |
| `completeUnstake` with nothing matured | returns silently | reverts |
| Closed state, share-rate check | none | either can revert both calls |
| Wait | fixed | two extra epochs for large requests |

So this repo has never exercised the unstake path the deployed vaults use.

## Suggested fix

- Add a fork test suite against the live shMonad. `deposit`, `startUnstake`, `pendingMon` and `totalAssets` run on an anvil fork as they are. Maturity can be simulated by writing shMonad's epoch, as the reproduction in #1 does.
- Remove the constructor's [`approve(unstaker, max)`](https://github.com/rootdraws/ushMON/blob/a7f478847134a5ff5afdb672ddd97398b3eae713/src/UnstakingShMonVault.sol#L63). Only the stand-in needs it.

