# 4. ushMON, the unstaking shMON vault

Repo: [rootdraws/ushMON](https://github.com/rootdraws/ushMON) (public). Source
[`src/UnstakingShMonVault.sol`](https://github.com/rootdraws/ushMON/blob/a7f478847134a5ff5afdb672ddd97398b3eae713/src/UnstakingShMonVault.sol)
at `a7f4788` is v1, the code live on Monad. v2 is in the working tree on 2026-11-16 and ships as new vaults; see
[09-current-state-and-next.md](09-current-state-and-next.md). The same file is vendored at
`ag-euler/contracts/eulerswap-mm-monad/src/exitmm/UnstakingShMonVault.sol`, whose build artifact every deploy script reads.

## What it is

An ERC-4626 vault whose shares (ushMON) are denominated in shMON. "An operator sends the vault's shMON into shMonad's
slow unstake (20 to 28 hours) and completes it; the MON that comes back is held as WMON. A holder redeems ushMON for WMON
at shMonad's redemption rate with `redeemForWmon`, inside the same Euler EVC batch that repays a WMON loan. The vault
runs the EVC account status checks that Euler's collateral vaults run, so a WMON vault can accept ushMON as collateral
and liquidate it." (`README.md`.) Root's brief, quoted in the NatSpec: "Custom vault for shMON, which does
rehypothecation into slow redemption" (2026-11-05).

Assets are counted in shMON units: shMON held + (MON pending in the unstake + WMON held) / shMonad's rate
(`totalAssets`, line 81). The operator is immutable and is the exit desk; one ushMON per desk.

## Functions (v2 working tree; v1 lines differ by the added overrides)

| Function | Who | What |
|---|---|---|
| `startUnstake(shmon)` 135 | operator | sends shMON into shMonad's unstake, emits `UnstakeStarted` |
| `completeUnstake()` 143 | anyone | completes matured requests, wraps the vault's MON into WMON, emits `UnstakeCompleted` |
| `redeemForWmon(shares, receiver, owner)` 152 | holder or approved | burns shares, pays their WMON value at `rate()`, reverts `InsufficientWmon` if short, then the EVC account check |
| `deposit` / `mint` (OpenZeppelin) | v1: anyone; v2: receiver must be the operator | shMON in, shares out |
| `withdraw` / `redeem` 176, 181 | holder | shMON out, then the EVC account check |
| `transfer` / `transferFrom` 164, 170 | holder | plus the EVC account check, so a controller can veto |
| `maxDeposit`, `maxMint` 99, 103 (v2) | view | `type(uint256).max` for the operator, 0 for anyone else |
| `maxWithdraw`, `maxRedeem` 109, 114 (v2) | view | 0 with a controller enabled, else the claim bounded by the shMON held |
| `maxRedeemForWmon(owner)` 121 (v2, new) | view | 0 with a controller, else the shares the WMON held can pay |
| `rate()` 77, `pendingMon()` 130, `totalAssets()` 81, `permit2Address()` 72 | view | |

## v1 to v2: the three issues

Fábio Soares audited v1 on 2026-11-15 (`evidence/audit-2026-11-15.md`: "No High. 1 Medium, 3 Low, 4 informational")
and filed three issues on 2026-11-16 (`evidence/issues/`):

| Issue | Finding | Fix in v2 |
|---|---|---|
| [#1](https://github.com/rootdraws/ushMON/issues/1) High | Once an unstake matures, anyone can `completeUnstake`, deposit shMON and `redeemForWmon` in one transaction, taking the vault's WMON at par ahead of the desk's settle. The desk's loan then runs another day. Cheap to repeat. | Shares are minted only when the receiver is the operator (`maxDeposit`/`maxMint` return 0 otherwise). The desk's EulerSwap pool deposits with the desk as receiver and reads `maxDeposit(desk)` for its quote limit, so it keeps working. Shares stay transferable, so a liquidation still seizes them. |
| [#2](https://github.com/rootdraws/ushMON/issues/2) High | `maxWithdraw`/`maxRedeem` report the full claim while the shMON sits in the unstake or the owner has a loan, and the exit then reverts. Routers and liquidation bots that size from them hit reverts. | Both return 0 with a controller enabled (Euler's own rule, `euler-vault-kit/src/EVault/modules/Vault.sol:234-248`), else the claim bounded by the shMON actually held. `maxRedeemForWmon` added for the WMON exit. |
| [#3](https://github.com/rootdraws/ushMON/issues/3) Medium | MON that reaches the vault outside `completeUnstake` (a direct send, or shMonad paying the vault as receiver) is never counted and never moves. | `completeUnstake` wraps the vault's whole MON balance, so strays become a donation to holders. |

The audit's other findings stand as accepted: M1 a shMonad freeze strands the collateral until shMonad reopens; L2 a
chunk above shMonad's no-delay allowance waits two more epochs (the bot should split it); L3 a liquidator receives a
share that pays out a day later.

## Tests (v2, `test/UnstakingShMonVault.t.sol`, output in `evidence/forge-test.txt`)

Ten unit tests against a mock shMON with a settable rate, a mock WMON, the real Ethereum Vault Connector from `lib/`, a
mock controller and the fork stand-in for shMonad's unstake: non-operator deposit and mint revert; a pool-style deposit
from another caller with the operator as receiver succeeds; the three-call attack of issue 1 stops at the deposit; the
max views are 0 while shMON is in the unstake and equal the claim when held; the max views are 0 with a controller;
`redeemForWmon(maxRedeemForWmon)` pays and five shares more reverts, at three rates; stray MON is wrapped and counted;
the full cycle deposit, unstake, wait, complete, redeem for WMON; `startUnstake` by a non-operator reverts. All ten pass.

```sh
git clone --recurse-submodules https://github.com/rootdraws/ushMON && cd ushMON && forge test -vv
```

The fork cycle test that drives v2 through the live desk, the pool and a matured unstake is in
[08-testing.md](08-testing.md).

## Deployed vaults

| ushMON | Cluster | Operator (exit desk) | Version | Note |
|---|---|---|---|---|
| [0xa44220Ee57Cb879bd842a24696Df06e398601d8F](https://monadscan.com/address/0xa44220Ee57Cb879bd842a24696Df06e398601d8F) | second (live) | 0x02Df…c770 (usdc-hl) | v1 | the desk's collateral today, empty |
| [0x066E1eb375369A00e324cF18Eb014B9AB0507690](https://monadscan.com/address/0x066E1eb375369A00e324cF18Eb014B9AB0507690) | second (live) | 0xF460…6CdE (usdc-hl-d0) | v1 | the desk's collateral today, empty |
| 0x8DB5BAA62968F8Ff971889F07C52e6BD7835Ad16, 0xE5c2612F36dC773D7d85D034F9c8E9171cE2Ef73 | second | the retired usdt0 desks | v1 | unused |
| 0x59f7f897322D5FdEFCa38beB78137559eD985F80, 0xc0CA1086131046766956bBD030fe9595Cc8204a1 | first (handed over, rejected) | usdc-hl, usdt0-hl desks | v1 | listed in the ushMON README; retired with desk v1.5.0 |

Operators are from the production and retired configs (`params.unstakeVault`) and the live EVC collateral reads
(`evidence/live-reads.md`). The ushMON README still lists only the first-cluster pair and says "Not yet audited"; it is
updated with the v2 release. Each vault is approved on the cluster by two governor calls: the router resolves it to shMON
(`govSetResolvedVault`) and the WMON vault lends 97% against it with a 98% liquidation threshold (`setLTV`), both in
`ag-euler/contracts/shmon-cluster-monad/deploy.sh:187-188`.
