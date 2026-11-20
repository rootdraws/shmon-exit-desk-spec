# 8. Testing

Each result below has its log under `evidence/` and a command to rerun it.

| Test | Result | Log |
|---|---|---|
| Bot unit tests | 1,348 passed, 0 failed, 2026-11-20 | `evidence/bot-tests-2026-11-20.txt` |
| ushMON unit and fork tests | 28 passed, 0 failed | `evidence/forge-test-v4-all.txt` |
| Emergency sale, on a Monad fork | 8 passing | `evidence/hardhat-fork-panic.txt` |
| Exit desk, on a Monad fork | 7 files, 50 passing | `evidence/hardhat-fork-desk-2026-11-19.txt` |
| Five-stage fork run with the real bot | passed on both vaults | `evidence/harness/` |
| LTV simulation, on a Monad fork | 24 passing | `evidence/ltv-study/` |
| Releases, rehearsed on a fork before mainnet | all read back OK | `evidence/release-pause-2026-11-20.txt`, `evidence/ltv-lines-2026-11-20.txt` |

## Bot unit tests

The whole rebalancing bot suite passes: 1,348 tests, none failing. Among them, 30 cover the emergency sale:

- Market sales start at 65.0% and stop at 55.0%.
- Leftover WMON sells before any new shMON turns into WMON.
- At 66% the desk cancels its resting orders, sells their WMON and repays with their USDC.
- One transaction borrows WMON and sells it into the pool that pays more, round after round.
- A WMON sale fills 1.9% under the oracle and is refused at 2.1%.
- The instant redemption and Curve are used at 1.4% under and skipped at 1.6%.
- A sale too small to lower the loan is refused.
- With nothing to sell, the bot does nothing more, so the short is never half-closed.

```sh
cd alphastructures/services/rebalancingBot && npx tsx --test test/*.test.ts test/policy/*.test.ts \
  test/planner/*.test.ts test/transit/*.test.ts test/loop/*.test.ts
```

## ushMON tests

All 28 pass on the live version. See [04-ushmon.md](04-ushmon.md) for what they cover.

```sh
cd ushMON && MONAD_RPC_URL=<rpc> forge test
```

## Contract tests on a Monad fork

**The emergency sale, 8 passing.** The test upgrades the Delta One controller and desk, then pauses the vault:

1. Both contracts upgrade.
2. While paused, the desk still parks, unstakes, borrows, sells WMON and places orders.
3. While paused, the desk cannot buy WMON or sell shMON into bids.
4. A full halt stops everything.
5. A WMON sale may fill 2% under the oracle only at a 65% loan or more.
6. Borrowing and selling WMON runs in one controller call, and the USDC comes home.
7. The same call can instead send the WMON home to sell on Uniswap v3.
8. That call is refused below the price floor, works only for the controller, and stops at a full halt.

**The exit desk, 50 passing across seven files:**

- Unstaking, orders, price checks against the oracle and roles: 7.
- Uniswap v4, Hanji and digester orders: 14.
- One order per price tick: 4.
- Both desks on one ushMON: 5.
- Moving the Euler account, then parking, borrowing and repaying: 5.
- The settle fixes from the audit: 5.
- The public buyer and a matured unstake: 10.

The last three files need the chain as it stood before the move to the current ushMON, block 123,378,188.

```sh
cd alphastructures/contracts && FORK_MONAD=true MONAD_RPC_URL=<rpc> MONAD_FORK_BLOCK=<block> \
  npx hardhat test test/NeverlandMarketAdapter/<file>
```

## The five-stage fork run

This test runs the real bot, oracle, monitor and keeper on a copy of Monad, with both lenders and both desks:

1. The exit desk gets its Euler account.
2. A $300k deposit grows the book, buying MON only through the desk's resting orders.
3. Neverland's USDC runs past its kink, and the stable desk moves the debt to USDT0.
4. MON and shMON fall 35%, and neither lender may liquidate.
5. Half the shares leave, and the bot pays them.

No market swap may run at any stage. Both vaults passed on the current ushMON: Delta One as run `ush4-hl` and Delta
Neutral as `ushv4b-d0`, on 2026-11-18.

A fork cannot finish shMonad's day-long unstake. The finished unstake is covered by the public buyer test above and by
`services/rebalancingBot/test/exitDeskEuler.test.ts`.

```sh
cd alphastructures/services/rebalancingBot/test/sim/multi/harness
./launch-try.sh fresh-try.sh RUN=<name> PORT=<port> BASE=shmon-desk-hl      # Delta One
./launch-try.sh fresh-try.sh RUN=<name> PORT=<port> BASE=shmon-desk-hl-d0   # Delta Neutral
```

## The LTV simulation

24 cases on a Monad fork, all passing. Twelve hold a loan for 30 hours at six LTV pairs, and interest matches the rate
curve within 0.01%. Twelve drop the price feed and run a real liquidation. See [11-ltv-study.md](11-ltv-study.md).

## Releases

Every release runs first on a fork of Monad, then on mainnet, and reads each change back.

- **The pause release:** Vault 1.12.0 and controller 1.16.0 on both vaults, with storage layouts checked first.
- **The loan lines:** the 60% unwind line, Euler's matching line, and the 55% margin borrow line.
- **The share price limit:** a fork post of a 34.48% MON fall passed in one step on Delta Neutral. The same post without
  the dollar price was refused.

Live versions, read 2026-11-20: Vault 1.12.0, controller 1.16.0, settings 1.16.0, withdrawal handler 1.11.0, exit desk
1.10.0, ushMON v4.

```sh
anvil --fork-url <rpc> --port 8700 --chain-id 143
cd alphastructures && RPC=http://127.0.0.1:8700 FORK=1 npx tsx custody/release-pause-143.ts
```
