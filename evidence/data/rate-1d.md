Flow per pair, 1 days of swaps on every venue (USD):

| Pair, direction | Typical hour | Slow hour (10th pct) | Busy hour (90th pct) | Per day |
| --- | --- | --- | --- | --- |
| MON->USDC | $45,340 | $26,974 | $183,581 | $1,923,676 |
| USDC->MON | $48,135 | $21,883 | $163,463 | $1,762,141 |
| shMON->MON | $6 | $0 | $43 | $345 |
| MON->shMON | $7 | $0 | $47 | $313 |
| shMON->USDC | $0 | $0 | $0 | $6 |
| USDC->shMON | $0 | $0 | $1 | $3 |

Time for the digester to work through an inventory, replayed from every 3-hour start in the window:

| Side | Inventory | Share of passing flow we fill | Typical | Slow (90th pct) | Slowest | Never finished |
| --- | --- | --- | --- | --- | --- | --- |
| sell MON | $10,000 | 25% | 1.2 h | 1.4 h | 1.4 h | 0 of 6 |
| sell MON | $10,000 | 10% | 2.5 h | 4.2 h | 4.2 h | 0 of 6 |
| sell MON | $50,000 | 25% | 5.6 h | 6.4 h | 6.4 h | 0 of 6 |
| sell MON | $50,000 | 10% | 10.0 h | 12.6 h | 12.6 h | 0 of 6 |
| sell MON | $200,000 | 25% | 13.4 h | 17.9 h | 17.9 h | 0 of 6 |
| sell MON | $200,000 | 10% | - | - | - | 6 of 6 |
| buy MON | $10,000 | 25% | 1.2 h | 1.3 h | 1.3 h | 0 of 6 |
| buy MON | $10,000 | 10% | 2.8 h | 3.6 h | 3.6 h | 0 of 6 |
| buy MON | $50,000 | 25% | 5.1 h | 6.0 h | 6.0 h | 0 of 6 |
| buy MON | $50,000 | 10% | 10.5 h | 12.5 h | 12.5 h | 0 of 6 |
| buy MON | $200,000 | 25% | 13.2 h | 17.9 h | 17.9 h | 0 of 6 |
| buy MON | $200,000 | 10% | 23.7 h | 23.7 h | 23.7 h | 5 of 6 |
