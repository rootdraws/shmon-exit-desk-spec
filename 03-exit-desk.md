# 3. The exit desk

Contract: `alphastructures/contracts/adapters/venue/ShMonadExitAdapter.sol` at `bd9a894`, a UUPS proxy per vault,
`VERSION = 1_06_00` (line 285), live on both production desks (`evidence/live-reads.md`). Bot: `services/rebalancingBot/src/planner/exitDesk.ts`.

## Why it exists

A leaver's shMON must become stablecoin to repay the vault's loan and pay the leaver. shMonad's instant exit costs
0.41% to 0.73% (30 days of hourly reads, `evidence/data/shmonad-30d.md`); its slow unstake is free but takes about a
day (`evidence/data/unstake-timing-30d.md`); DEX pairs for shMON carry about $2,700 a day of flow
(`evidence/data/rate-30d.md`, 30 days of swaps to 2026-11-05, computed 2026-11-07). The instruction behind the desk (2026-11-03, quoted in `docs/shmon-exit-desk-plan.md:5-8`)
was to build withdrawals on the one-day unstake and to sell with resting orders one tick above the price instead of
taking a market. The withdrawal batch stays five minutes; the desk carries the day (`shmon-exit-desk-plan.md:46-47`).

## What it does

"The vault's slow exit desk on Monad: shMON goes through shMonad's traditional unstake (about a day, no fee), and MON is
sold (or bought) with resting orders one tick step beyond the price" (contract NatSpec, lines 255-258). It is reached
through the controller's existing venue-margin path; funds leave it only to the controller, to shMonad's unstake, or
into a resting order (`shmon-exit-desk-plan.md:36-43`).

**The digester.** "Each vault's exit desk rests small limit orders in our own Uniswap v4 pool, one tick off the market.
Our keeper watches the other Monad pools. When one of them trades past one of our orders by more than both pools' fees,
the keeper fills our order and trades it straight back into that pool, inside a single Uniswap v4 PoolManager unlock.
That needs no capital, and the gain goes to the vault whose order was filled." (`docs/Alpha_Structures_Digester.md:3-7`.)

| Digester piece | Address | Note |
|---|---|---|
| Hook | [0x94Df2bffA788BBd918179f4CCB5A22DbAD7e1040](https://monadscan.com/address/0x94Df2bffA788BBd918179f4CCB5A22DbAD7e1040) | OpenZeppelin `LimitOrderHook` (uniswap-hooks 1.3.0), CREATE2 |
| Pool | poolId `0x3957bb3c02c319231713c06853de9bfc8e7d1aaa276873cd65fc028efc0b1314` | WMON/USDC, fee 100, tick spacing 1, PoolManager `0x188d586Ddcf52439676Ca21A244753fA19F9Ea8e` |
| Router | [0x77eB1B6aab832f3aD11A216Dfcb8613fdA15A088](https://monadscan.com/address/0x77eB1B6aab832f3aD11A216Dfcb8613fdA15A088) | `contracts/digester/MonadRouter.sol`, owner-only |
| Keeper wallet | 0xEE51d642304f8F0b272Fc79cf851CE76ee24c3A7 | container `digester-keeper`, min gain $0.01 |
| Exit bid pools | 0xEA93Cb7Af4bcdAfF8312BEe55dF369970070C4a9 (USDC), 0xB03b966811eBd2E481a77d2ce118f8fA2c5fD716 (WMON) | `contracts/exit-pool/ExitBidPool.sol`, bids for shMON at a 30 bps discount, deployed 2026-11-12 |

The ladder is five rungs one tick apart, sells at +1 to +5 ticks and buys at −2 to −6, re-laddered after 20 ticks off
for 3 minutes; the keeper simulates sizes 1, ½, ¼, ⅛, 1/16 (`Digester.md:30-56`). `Digester.md:26` lists two other exit
bid pool addresses (`0xF950…2E6A`, `0x1e55…c4CF`); the deployment record `custody/deployments/exit-pool-143.json` and
the production configs carry the two above, which this spec takes as current.

**The chunked WMON route (desk v1.4.0, 2026-11-06).** "The WMON a desk sells can also come from a loan against shMON it
parks on the Euler cluster, chunk by chunk" (`Digester.md:37-38`). The desk parks shMON in the vault's ushMON, which is
its Euler collateral, borrows WMON from the cluster's WMON vault at up to 97% of value, sells the WMON through the
digester for USDC that goes home to repay, and when the unstake matures a day later redeems ushMON for the WMON that came
back and repays the WMON loan in one Euler batch (`settleEulerUnstake`, lines 835-853). Leftover WMON is restaked as
shMON and sent home (`restakeWmon`, 856).

**The public buyer (also v1.4.0).** The desk owns an EulerSwap pool that buys shMON at shMonad's live rate less
`MM_DISCOUNT_BPS = 30` (line 287) and is that pool's pricing hook (`getFee`, 883; `afterSwap`, 892). See
[05-eulerswap.md](05-eulerswap.md).

**The priority rule (v1.7.0, deployed 2026-11-16).** While the vault has a withdrawal batch that is not yet
paid, the pool quotes nothing, so the desk's borrowing room serves the vault's own leavers first. The desk reads the
withdrawal handler's current and last-processed batch ids (`leaversWaiting()`); a seller's router sees no quote from
this pool and moves on to shMonad's instant exit. Root, 2026-11-16: "build the priority rule into the desk".

## The contract, by group (line numbers at `bd9a894`)

| Group | Functions | Who |
|---|---|---|
| Setup | `initialize` 417, `initializeV1_1` 436, `initializeV1_4` 455, `initializeV1_5` 470, `moveEulerAccount` 478 (reverts `MarketMakerBusy` with any debt or parked shares), `setPool` 1065, `setV4Pool` 1070, `setHanjiBook` 1075, `rescueTokens` 1088, `_authorizeUpgrade` 1371 (VERSION must rise) | admin Safe |
| Funds in and out | `deposit` 549 (controller only), `returnToController` 1054 | controller, executor |
| shMonad unstake | `requestUnstake` 561, `completeUnstake` 568 | executor |
| Resting orders | v3 `placeOrder` 583 / `closeOrder` 599; v4 `placeV4Order` 639 / `closeV4Order` 665; Hanji `placeHanjiOrder` 941 / `claimHanjiOrder` 967; digester `placeLimitOrder` 998 / `withdrawLimitOrder` 1028 / `cancelLimitOrder` 1038 | executor, all checked against the oracle |
| Selling shMON into bids | `sellShmonV4` 722, floor at the oracle less the swap limit | executor |
| Euler account | `parkShmon(shmon, unstake)` 757, `borrowWmon` 764, `repayWmon` 770, `settleEulerUnstake` 835, `restakeWmon` 856, view `getEulerPosition` 907 | executor |
| Digester with own funds | `sellMonV4` 778, `buyMonV4` 806 (v1.6.0, audit H5) | executor |
| EulerSwap pool | `deployMmPool` 865 (admin; requires `supplyVault0 == unstakeVault`, `eulerAccount == swapHook == this`), `getFee` 883, `afterSwap` 892 (pool only) | admin, pool |
| Halts | `whenNotHalted` 519 freezes every executor function; `whenNotPaused` 524 freezes the ones that trade or borrow and leaves the ones that bring funds home (516-518) | guardian |

Version history (lines 275-284): v1.1.0 Uniswap v4 and Hanji venues; v1.1.1 a second placement adds to a listing;
v1.4.0 the Euler account and the EulerSwap pool; v1.5.0 the account moves to the 2026-11-09 cluster and the pool on the
old pair is retired; v1.6.0 `settleEulerUnstake` skips a reverting `completeUnstake` and settles every share the WMON
held can pay (audit 2026-11-10 H2, H3, H10), plus `buyMonV4`; v1.7.0 the pool yields to the vault's leavers (implementation
0xBE243F5e4215720080929eeCfe77047D2Fd2a410, both desks upgraded 2026-11-16). The docs under `docs/` still describe v1.5.0 as live; the chain says v1.7.0 on both
desks (`evidence/live-reads.md`).

## What the bot decides each tick (`deskEulerStep`, planner lines 172-230, working tree of 2026-11-16, not yet on the server)

1. Something matured, or WMON above $10 sits in ushMON, and there is a loan or parked shares: `settleEulerUnstake`.
2. No loan and WMON above $10 on the desk: `restakeWmon`.
3. A withdrawal batch is open and the desk holds shMON: `parkShmon(all, all)`, the exit chunk.
4. Otherwise compute the loan's unbacked part (debt less pending MON and WMON held). Stop under $10.
5. shMON already in ushMON (the pool's buys) backs it first: `parkShmon(0, min(held, need))`. Added 2026-11-16 for the
   public buyer; uncommitted at the time of writing.
6. shMON on the desk: `parkShmon(min(shmon, need), same)`.
7. No batch open and idle shMON at the controller: `deposit` it to the desk.

Every step is gated by `DESK_DUST_USD = 10` (planner line 23): the bot leaves anything under $10 alone.
