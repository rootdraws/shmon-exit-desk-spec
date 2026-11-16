title:	[High] maxWithdraw / maxRedeem report exits that revert (shMON in the unstake, or an indebted owner)
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
number:	2
--

## Summary

The vault does not override `maxWithdraw`/`maxRedeem`, so OpenZeppelin's balance-based versions apply. They report the owner's full claim in two cases where the exit then reverts:

- the operator has sent the vault's shMON into the unstake, which is the vault's normal state;
- the owner has debt on a controller.

EIP-4626 requires both functions to return a limited value when the owner cannot exit.

- **Severity:** High by the rubric. Reachability 2, preconditions 2, impact 2: a stalled exit, no loss. Total 6.

## Location

- `maxWithdraw` and `maxRedeem` are inherited from lib/openzeppelin-contracts (v5.2.0) `contracts/token/ERC20/extensions/ERC4626.sol` (lines 141 and 146).
- [`withdraw` / `redeem`](https://github.com/rootdraws/ushMON/blob/a7f478847134a5ff5afdb672ddd97398b3eae713/src/UnstakingShMonVault.sol#L140-L148) can only pay the shMON the vault holds.

## Reproduction

Run on a local anvil fork of Monad.

**Case 1: the shMON is in the unstake.**
1. A holder deposits 1,209.64 shMON.
2. The operator calls `startUnstake` for every shMON in the vault. The vault now holds 0 shMON and 0 WMON.
3. `maxWithdraw(holder)` returns over 1,000 shMON, and `maxRedeem(holder)` returns all its shares.
4. `withdraw(1 wei)`, `redeem(1e6 shares)` and `redeemForWmon(1e6 shares)` all revert.

**Case 2: the owner has debt.**
1. A holder borrows 9,600 WMON against 10k MON of ushMON.
2. `maxRedeem` returns all its shares.
3. `redeem(maxRedeem)` reverts with `E_AccountLiquidity`, while the vault holds all the shMON.

**Liquidation.**
1. With the shMON feed mocked 2.5% lower, a liquidation seizes 1,209.64 ushMON. It does not read `max*` or `preview*`.
2. The liquidator's `redeem` and `redeemForWmon` then revert until the next maturity.

## Impact

- Integrators, routers and liquidation bots that size exits with `max*` hit reverts.
- A liquidator cannot exit seized ushMON until a request matures, which weakens the incentive to liquidate at a 98% liquidation LTV.
- `previewRedeem` is conformant: EIP-4626 says previews ignore limits.

## Suggested fix

- Override `maxWithdraw` and `maxRedeem` to the lesser of the owner's claim and the shMON held.
- Return 0 when the owner has a controller enabled, as EVK collateral vaults do.
- Add a `maxRedeemForWmon(owner)` view.
- With the fix for issue 1 (only the operator receives new shares), only the liquidator case remains.

