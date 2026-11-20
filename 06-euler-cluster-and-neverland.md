# 6. The lenders: our Euler cluster and Neverland

The vaults borrow from two lenders. Neverland is an outside lender, and the Euler cluster is our own.[^cluster]

![shMON Euler cluster: the price router, four lending vaults, the stable desks, ushMON and the exit desks, read on chain 2026-11-20](figures/euler-clusters.svg)

- **Cluster:** a set of Euler lending vaults that share one price router.
- **Green:** the WMON loan to the exit desks.
- **LTV pairs:** the most the vault lends against a collateral, then where it liquidates, in percent.

## The Euler cluster

Our deployer key `0x501107fe590c8F9b81c00b81867fD19e0d9c0253` governs every vault and the router. Fees go to the
AlphaGrowth Safe `0x4f894Bfc9481110278C356adE1473eBe2127Fd3C`, which governance can also be handed to.

| Vault | Address | Lends? | Caps (supply / borrow) | Rate | Lends against |
|---|---|---|---|---|---|
| shMON (eshMON-6) | [0xD81D3E243760eD23Ac3DEf2b08d4989bA2790Dfe](https://monadscan.com/address/0xD81D3E243760eD23Ac3DEf2b08d4989bA2790Dfe) | no | 200M shMON (about $4.9M) | | |
| USDC (eUSDC-26) | [0x5aB09A3EDbb0937Db454f54e6CF04Dd982c40948](https://monadscan.com/address/0x5aB09A3EDbb0937Db454f54e6CF04Dd982c40948) | yes | 5M / 4.5M | 8.5% at 80% use, 9.6% at 90% | shMON 79/80, WMON 79/80, USDT0 95/96 |
| USDT0 (eUSDT0-15) | [0xD6645190976d456907c9807d08E4E4E220c96a3E](https://monadscan.com/address/0xD6645190976d456907c9807d08E4E4E220c96a3E) | yes | 5M / 4.5M | the same as USDC | shMON 79/80, USDC 95/96 |
| WMON (eWMON-16) | [0xE4522663752AC47516e39aD11d3780a116850eaf](https://monadscan.com/address/0xE4522663752AC47516e39aD11d3780a116850eaf) | yes | 727M / 654M (about $10M) | 20% idle, 30% at 90% use, 50% at full use | shMON 97/98, ushMON 93/95, USDC 79/80 |

Every vault keeps 10% of the interest as a fee and allows a liquidation discount of up to 15%.

- **Prices.** One Euler router, `0x99f7105CAC565Ac830cf2d66527FBb06dD322C32`, prices every vault with Chainlink SVR
  feeds: shMON/MON once a day, and MON/USD, USDC/USD and USDT0/USD. The router prices ushMON as the shMON behind it.
- **The stable desks.** Each vault has a stable desk, `0xc19a…599a` for Delta One and `0x2dCD…28f1` for Delta Neutral.
  Each runs an EulerSwap pool on the USDC and USDT0 vaults. When one stablecoin borrows cheaper, the vault borrows it,
  sells it through the pool at one blip better than Curve, and repays the dearer debt.
- **ushMON and the exit desks.** The WMON vault lends to both exit desks against their ushMON. See
  [04-ushmon.md](04-ushmon.md) and [05-eulerswap.md](05-eulerswap.md).

## Neverland

Neverland is an Aave v3 fork on Monad, at pool `0x80F00661b13CC5F6ccd3885bE7b4C9c67545D585`.[^neverland]

- The vaults supply shMON and borrow USDC or USDT0.
- Neverland lends up to 65% against shMON and liquidates at 70%.
- Its USDC and USDT0 rates jump past 90% use. The bot borrows only the room left under that kink.
- When one stablecoin runs past its kink or borrows dearer, the stable desk moves the vault's debt to the other.

[^cluster]: Sources: [`sources/ag-euler/contracts/shmon-cluster-monad/deploy.sh`](sources/ag-euler/contracts/shmon-cluster-monad/deploy.sh) and [`deployed-143.env`](sources/ag-euler/contracts/shmon-cluster-monad/deployed-143.env). Built with the Euler Vault Kit factory `0xba4D…3f1E`, the router factory `0xdDA3…A902` and the Ethereum Vault Connector `0x7a9324E8f270413fa2E458f5831226d99C7477CD`. Governor, caps, fees, liquidation discount, fee receiver, oracle and every lending line read on chain 2026-11-20 (`governorAdmin`, `caps`, `interestFee`, `maxLiquidationDiscount`, `feeReceiver`, `oracle`, `LTVFull`). USDC rate curve `0xe743…97c6` (`ag-euler/safe-payloads/monad-shmon-usdc-caps-rate.json:7`); WMON rate curve `0xa359…Ba8a` (`deploy.sh:49`). Stable desk: `alphastructures/contracts/adapters/venue/StableDeskAdapter.sol`.
[^neverland]: `alphastructures/deploy/configs/production/shmon-neverland-usdc-hl.json:54-83`; shMON lines from `getConfiguration(shMON)`, 6500/7000; the room before the kink, `services/rebalancingBot/src/lenders.ts:128-166`.
