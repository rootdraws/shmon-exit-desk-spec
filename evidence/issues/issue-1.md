title:	[High] Anyone can swap shMON for the vault's matured WMON at par, so the desk's settle repays nothing
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
number:	1
--

## Summary

Once an unstake request matures, any address can call `completeUnstake()`, deposit shMON, and call `redeemForWmon`. All three fit in one transaction. The caller takes the vault's WMON at shMonad's rate, with no fee and no wait. The desk's settle that follows finds no WMON, so its WMON loan stays open for another unstake cycle. The caller can repeat this at every maturity.

- **Severity:** High. Reachability 3 (any address), preconditions 2 (a matured request not yet settled), impact 2 (a stalled settle). Total 7.
- **Commit:** `a7f4788`. The same code runs at every deployed copy.

## Location

- [`redeemForWmon`](https://github.com/rootdraws/ushMON/blob/a7f478847134a5ff5afdb672ddd97398b3eae713/src/UnstakingShMonVault.sol#L116-L124) pays any share its full WMON value, first come first served.
- [`completeUnstake`](https://github.com/rootdraws/ushMON/blob/a7f478847134a5ff5afdb672ddd97398b3eae713/src/UnstakingShMonVault.sol#L106-L112) can be called by anyone.
- `deposit`/`mint` are inherited unrestricted from lib/openzeppelin-contracts (v5.2.0) `contracts/token/ERC20/extensions/ERC4626.sol` (`maxDeposit` returns `type(uint256).max`).

## Reproduction

Run on a local anvil fork of Monad at block 122775206, against the live shMonad. Maturity was simulated by writing shMonad's epoch field (storage slot `0x12`, low 64 bits).

1. The operator deposits 1,209.64 shMON and calls `startUnstake` for all of it (1,999.84 MON pending).
2. The request matures.
3. In one transaction, an address with no role:
   1. calls `completeUnstake()`, which wraps 1,999.84 MON to WMON;
   2. deposits 1,209.64 shMON;
   3. calls `redeemForWmon`.

| | Value |
|---|---|
| WMON the caller received | 1,999.842 |
| WMON left in the vault | 0.000345 |
| shMonad's own instant exit for the same shMON | 1,991.587 MON |
| Caller's gain (shMonad's 0.41% instant-exit fee, avoided) | 8.25 MON |
| Operator's claim, before → after | 1209.641032290076237900 → …902 shMON (unchanged) |

After the swap:
- the operator's `redeemForWmon(half its shares)` reverts `InsufficientWmon`;
- with its WMON loan open, the operator cannot `withdraw` its shMON either: the WMON vault's account status check reverts `E_AccountLiquidity`;
- if the operator settles before the caller, only 4 wei are left, and the caller's `redeemForWmon` reverts.

shMonad's `crank()` is public, so a caller can also turn the epoch inside the same transaction. This was read in shMonad's code, not run: `crank` reverts on anvil.

## Impact

- Holder claims do not fall: the swap is exact at the rate.
- **What is lost is liquidity and time.** The operator's collateral turns back into shMON, which needs another unstake period, and its loan keeps accruing.
- **Griefing is cheap.** Without any wish to exit, the round trip MON → shMON → ushMON → WMON costs about 0.008%.
- **Path to liquidation.** Suppose the swap repeats every cycle and the loan is never repaid from other funds. Then a loan at 96–97% of collateral reaches the 98% liquidation line in about 3 to 6 weeks, assuming roughly 18% a year interest and no yield on the collateral. This is arithmetic, not run.
- **Exposure today: none.** Every deployed copy holds 0 shares (block 122792053), and the WMON vaults have no lender funds.

## Suggested fix

**Recommended: mint shares only to the operator.** Make `maxDeposit`/`maxMint` return 0 when `receiver != operator`, and make `_deposit` revert in that case.
- Shares stay transferable, so a liquidation can still seize them.
- Gate on the receiver rather than the caller, so that a market-maker pool depositing for the operator keeps working.

Alternatives:
- Make `completeUnstake` operator-only. A liquidator holding seized ushMON then depends on the operator.
- Charge a fee on `redeemForWmon` of at least shMonad's instant-exit fee.

**Does not work:** capping `redeemForWmon` at the holder's pro-rata share of the WMON. A deposit 10× the operator's stake takes 90.9% of the WMON, and 100× takes 99.0% (run). The rest comes back as shMON in the same transaction.

The vault is immutable, so the fix ships as a new vault, with the desks migrated to it.

