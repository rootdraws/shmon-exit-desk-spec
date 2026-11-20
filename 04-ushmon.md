# 4. ushMON, the unstaking shMON vault

ushMON lets the exit desks borrow WMON against shMON that is still unstaking. One vault serves both desks.[^source]

| Live vault | Asset | Operators | Euler WMON vault |
|---|---|---|---|
| [0xa753E24B0986567EDAd75f784664Ec11336f8C5e](https://monadscan.com/address/0xa753E24B0986567EDAd75f784664Ec11336f8C5e) | shMON | both exit desks, Delta One `0x02Df…c770` and Delta Neutral `0xF460…6CdE` | lends 93% against ushMON, liquidates at 95% |

## What it is

- ushMON is an ERC-4626 vault. Its shares are counted in shMON.
- An exit desk deposits shMON and gets ushMON shares, which it uses as Euler collateral.
- The desk sends the shMON into shMonad's slow unstake, which takes 18 to 21 hours.
- When the unstake finishes, the MON comes back and the vault holds it as WMON.
- The desk redeems its shares for that WMON and repays its WMON loan, in one Euler batch.

The vault runs the same account checks as Euler's own collateral vaults. That is what lets the WMON vault lend against
ushMON and liquidate it.

Assets are counted in shMON: the shMON held, plus the MON still unstaking and the WMON held, divided by shMonad's rate.

## How both desks share it

- Each desk's unstakes and returned WMON are kept on its own ledger, so one desk never takes the other's WMON.
- Shares can move, for example when a liquidator seizes them. The WMON and pending unstakes behind those shares move
  with them, so the new holder can redeem what it took.
- WMON that reaches the vault any other way, such as a direct send, is shared by every holder in proportion to its
  shares.
- Only a desk can receive new shares or start an unstake. Anyone else's deposit is refused.

## Functions

| Function | Who calls it | What it does |
|---|---|---|
| `deposit`, `mint` | anyone, but the receiver must be a desk | shMON in, shares out |
| `startUnstake(shmon)` | a desk | Sends shMON into shMonad's unstake and records the MON owed on that desk's ledger. |
| `completeUnstake()` | anyone | Finishes the unstakes that have matured, wraps the MON as WMON, and credits each desk, oldest first. Other holders' part is set aside for them to claim. |
| `claimUnstaked(holder)` | anyone | Moves a holder's matured, set-aside WMON to its own credit. |
| `redeemForWmon(shares, receiver, owner)` | the holder, or someone it approved | Claims first, burns the shares, and pays WMON up to what the owner may redeem, at shMonad's rate. |
| `withdraw`, `redeem` | the holder | Pays out shMON the vault holds. |
| `transfer`, `transferFrom` | the holder | Moves shares, with their share of WMON and pending unstakes. Euler can block a move that would leave a loan short. |
| `wmonRedeemable(owner)`, `maxRedeemForWmon(owner)` | view | How much WMON the owner can take now. `maxRedeemForWmon` reads zero while the owner has an Euler loan open. |
| `maxDeposit`, `maxMint` | view | Unlimited for a desk, zero for anyone else. |
| `maxWithdraw`, `maxRedeem` | view | Zero while the owner has an Euler loan open, else what the shMON held covers. |
| `ledgerOf`, `wmonCredit`, `sharedWmon`, `operators`, `rate`, `totalAssets`, `pendingMon` | view | Each desk's pending unstakes and credit, the shared WMON, the desks, shMonad's rate and the vault's totals. |

## Security review

An outside audit found no high-severity issues.[^audit] Two reviewers then filed eleven issues, and each is settled:[^issues]

| Issue | Finding | How it is settled |
|---|---|---|
| [#1](https://github.com/rootdraws/ushMON/issues/1) High | Anyone could deposit shMON and take matured WMON ahead of the desk. | Only a desk can receive shares. The EulerSwap pool deposits with the desk as receiver, so it still works. |
| [#2](https://github.com/rootdraws/ushMON/issues/2) High | The max views overstated what could leave, so routers and liquidation bots hit reverts. | They return zero while a loan is open, as Euler's own vaults do, and are capped by the shMON held. |
| [#3](https://github.com/rootdraws/ushMON/issues/3) Medium | MON sent straight to the vault was never counted. | `completeUnstake` wraps every MON the vault holds, so a stray send goes to all holders. |
| [#4](https://github.com/rootdraws/ushMON/issues/4) Medium | No tests, and the test stand-in behaved differently from shMonad. | The stand-in is gone. Unit tests use a mock that behaves like shMonad, and a fork test runs the cycle against live shMonad. |
| [#5](https://github.com/rootdraws/ushMON/issues/5) Low | The operator cannot be changed. | By design. The operators are the exit desks, which are upgradeable contracts under the admin Safe. |
| [#6](https://github.com/rootdraws/ushMON/issues/6) Medium | A 98% liquidation line left too little room for a day-long exit. | The WMON vault lends at 93% and liquidates at 95%. See [11-ltv-study.md](11-ltv-study.md). |
| [#7](https://github.com/rootdraws/ushMON/issues/7) Low | A 1-wei withdrawal made an exact-size unstake revert. | `startUnstake` sends what is held, up to the amount asked. |
| [#8](https://github.com/rootdraws/ushMON/issues/8) Low | `completeUnstake` reverted with nothing matured, so a settle could be blocked. | It now does nothing in that case. |
| [#9](https://github.com/rootdraws/ushMON/issues/9) Low | shMON in the unstake earns nothing for that day. | By design. That day of lost yield is the cost of the exit. |
| [#10](https://github.com/rootdraws/ushMON/issues/10) Low | A direct transfer to the vault moves the share price. | Tested over 189 cases. A gift is counted once, mints nothing, never lowers the price and goes to holders in proportion. |
| [#11](https://github.com/rootdraws/ushMON/issues/11) Low | Redeeming for WMON emitted no event. | `RedeemedForWmon` now fires. |

Three audit findings are accepted as known risks:
- If shMonad freezes, the collateral is stuck until it reopens.
- An unstake larger than shMonad's no-delay allowance waits two more epochs, so the bot should split it.
- A liquidator that seizes shares is paid out a day later.

## Tests

The suite covers the desk-only deposit, the max views, the full deposit, unstake and redeem cycle, two desks sharing
one vault, and a liquidator redeeming the WMON behind seized shares. It also runs a 189-case donation grid and fork
tests against live shMonad. All pass.[^tests]

```sh
git clone --recurse-submodules https://github.com/rootdraws/ushMON && cd ushMON && forge test -vv
```

The fork test that runs both live desks through the vault is in [08-testing.md](08-testing.md).

## Approval

Two Euler governor calls approve the vault on the cluster. The router prices ushMON as shMON, and the WMON vault lends 93%
against it with a 95% liquidation line.[^deploy]

[^source]: [`sources/ag-euler/.../UnstakingShMonVault.sol`](sources/ag-euler/contracts/eulerswap-mm-monad/src/exitmm/UnstakingShMonVault.sol), copied from `ag-euler/contracts/eulerswap-mm-monad/src/exitmm/`; the live code matches that build byte for byte apart from constructor values and metadata. Public repo [rootdraws/ushMON](https://github.com/rootdraws/ushMON) at `b3ba1bf`. Operators read on chain with `operators()`, and the WMON vault's lines with `LTVFull`, 2026-11-20.
[^audit]: `evidence/audit-2026-11-15.md`: no high, one medium, three low, four informational.
[^issues]: Issues 1 to 3 filed by FSoaresDev and issues 4 to 11 by ardey26, on 2026-11-16 (`evidence/issues/issue-1.md` to `issue-11.md`). Donation cases: `evidence/donation-tests.txt`, `evidence/UnstakingShMonVault.donation.t.sol`.
[^tests]: `test/UnstakingShMonVault.t.sol` and `evidence/UnstakingShMonVaultV4.t.sol`; output in `evidence/forge-test-v4.txt`, rerun 2026-11-19.
[^deploy]: `ag-euler/contracts/shmon-cluster-monad/deploy.sh`: `govSetResolvedVault` and `setLTV`.
