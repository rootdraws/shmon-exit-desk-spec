/**
 * How far Chainlink's daily "SHMON / MON Exchange Rate" feed sits from shMonad's own rate (ushMON issue 6 study,
 * 2026-11-16). Walks the proxy's last N rounds, finds each round's block by timestamp, reads shMonad's
 * convertToAssets(1e18) at that block and just before the next round, and reports the divergence in basis points
 * (positive = the feed reads under shMonad). Also shMonad's rate once a day for the yield.
 *   MONAD_RPC_URL=<rpc> npx tsx test/sim/shmonFeedDivergence.ts [rounds=30]   -> OUT_DIR/feed-divergence-30d.{json,md}, shmon-yield-30d.{json,md}
 */
import fs from "fs";
import path from "path";
import { ethers } from "ethers";

const RPC = process.env.MONAD_RPC_URL;
if (!RPC) throw new Error("MONAD_RPC_URL is not set");
const OUT = process.env.OUT_DIR ?? "/Users/root1/shmon-exit-desk-spec/evidence/ltv-study";
const N = Number(process.argv[2] ?? "30");
const PROXY = "0x2dC0b316e3d4e673C7F9A809e80a3e60b26d7774";
const SHMON = "0x1B68626dCa36c7fE922fD2d55E4f631d962dE19c";
const PHASE = 1n << 64n;

async function main() {
  const provider = new ethers.JsonRpcProvider(RPC, 143, { staticNetwork: true });
  const feed = new ethers.Contract(PROXY, [
    "function latestRound() view returns (uint256)",
    "function getRoundData(uint80) view returns (uint80,int256,uint256,uint256,uint80)",
    "function description() view returns (string)",
    "function decimals() view returns (uint8)",
    "function aggregator() view returns (address)",
  ], provider);
  const shmon = new ethers.Contract(SHMON, ["function convertToAssets(uint256) view returns (uint256)"], provider);
  const tip = await provider.getBlock("latest");
  const back = await provider.getBlock(tip!.number - 200_000);
  const secPerBlock = (tip!.timestamp - back!.timestamp) / 200_000;
  // block at or just after a timestamp: estimate, then binary search
  const cache = new Map<number, number>();
  const ts = async (b: number) => { if (!cache.has(b)) cache.set(b, (await provider.getBlock(b))!.timestamp); return cache.get(b)!; };
  async function blockAt(t: number): Promise<number> {
    let lo = Math.max(1, tip!.number - Math.ceil((tip!.timestamp - t) / secPerBlock) - 5000);
    let hi = Math.min(tip!.number, tip!.number - Math.floor((tip!.timestamp - t) / secPerBlock) + 5000);
    while ((await ts(lo)) > t) lo = Math.max(1, lo - 20000);
    while ((await ts(hi)) < t) hi = Math.min(tip!.number, hi + 20000);
    while (hi - lo > 1) { const mid = (lo + hi) >> 1; if ((await ts(mid)) >= t) hi = mid; else lo = mid; }
    return hi;
  }
  const latest: bigint = await feed.latestRound();
  const last = Number(latest - PHASE);
  const rows: any[] = [];
  for (let n = Math.max(1, last - N); n <= last; n++) {
    const [, answer, , updatedAt] = await feed.getRoundData(PHASE + BigInt(n));
    rows.push({ round: n, answer: BigInt(answer), updatedAt: Number(updatedAt) });
  }
  const out: any[] = [];
  for (let i = 0; i < rows.length; i++) {
    const r = rows[i];
    const b = await blockAt(r.updatedAt);
    const atPublish: bigint = await shmon.convertToAssets(10n ** 18n, { blockTag: b });
    let beforeNext: bigint | null = null, bNext: number | null = null;
    if (i + 1 < rows.length) { bNext = (await blockAt(rows[i + 1].updatedAt)) - 1; beforeNext = await shmon.convertToAssets(10n ** 18n, { blockTag: bNext }); }
    const bps = (x: bigint) => Number((x - r.answer) * 1_000_000n / x) / 100;
    out.push({ round: r.round, updatedAt: r.updatedAt, iso: new Date(r.updatedAt * 1000).toISOString(), block: b, feed: r.answer.toString(),
      shmonAtPublish: atPublish.toString(), bpsAtPublish: bps(atPublish),
      shmonBeforeNext: beforeNext?.toString() ?? null, bpsBeforeNext: beforeNext ? bps(beforeNext) : null,
      secondsSincePrev: i > 0 ? r.updatedAt - rows[i - 1].updatedAt : null });
    process.stderr.write(`round ${r.round} block ${b} feed ${r.answer} shmon ${atPublish} (${bps(atPublish).toFixed(2)} bps)\n`);
  }
  const q = (xs: number[], p: number) => { const s = [...xs].sort((a, b) => a - b); return s[Math.min(s.length - 1, Math.floor(p * (s.length - 1)))]; };
  const atP = out.map((o) => o.bpsAtPublish), bN = out.filter((o) => o.bpsBeforeNext !== null).map((o) => o.bpsBeforeNext as number);
  const gaps = out.filter((o) => o.secondsSincePrev).map((o) => o.secondsSincePrev as number);
  const summary = {
    readAt: new Date().toISOString(), tipBlock: tip!.number, secPerBlock, rounds: out.length,
    feed: { proxy: PROXY, description: await feed.description(), decimals: Number(await feed.decimals()), aggregator: await feed.aggregator() },
    divergenceBpsAtPublish: { min: Math.min(...atP), median: q(atP, 0.5), p99: q(atP, 0.99), max: Math.max(...atP) },
    divergenceBpsJustBeforeNextRound: { min: Math.min(...bN), median: q(bN, 0.5), p99: q(bN, 0.99), max: Math.max(...bN) },
    cadenceSeconds: { min: Math.min(...gaps), median: q(gaps, 0.5), max: Math.max(...gaps) },
  };
  fs.writeFileSync(path.join(OUT, `feed-divergence-${N}d.json`), JSON.stringify({ summary, rows: out }, null, 2) + "\n");
  // yield from shMonad's rate at the first and last round blocks, and per day
  const first = out[0], lastRow = out[out.length - 1];
  const days = (lastRow.updatedAt - first.updatedAt) / 86400;
  const growth = Number(BigInt(lastRow.shmonAtPublish) * 10n ** 18n / BigInt(first.shmonAtPublish)) / 1e18;
  const daily = Math.pow(growth, 1 / days) - 1;
  const yieldRows = out.map((o, i) => ({ iso: o.iso, block: o.block, rate: o.shmonAtPublish, dailyBps: i > 0 ? Number(BigInt(o.shmonAtPublish) * 1_000_000n / BigInt(out[i - 1].shmonAtPublish) - 1_000_000n) / 100 : null }));
  const ysum = { days, growthBps: (growth - 1) * 1e4, dailyBps: daily * 1e4, apr: daily * 365 * 100, apy: (Math.pow(1 + daily, 365) - 1) * 100 };
  fs.writeFileSync(path.join(OUT, `shmon-yield-${N}d.json`), JSON.stringify({ summary: ysum, rows: yieldRows }, null, 2) + "\n");
  const md = [
    `# Chainlink SHMON / MON feed vs shMonad's rate, last ${out.length} rounds (read ${summary.readAt}, tip block ${tip!.number})`, "",
    `Feed: proxy ${PROXY} "${summary.feed.description}", ${summary.feed.decimals} decimals, aggregator ${summary.feed.aggregator}. Divergence in bps = (shMonad − feed) / shMonad × 1e4; positive means the feed reads under shMonad.`, "",
    `| | min | median | p99 | max |`, `|---|---|---|---|---|`,
    `| at the round's publish block | ${atP.length ? summary.divergenceBpsAtPublish.min.toFixed(2) : ""} | ${summary.divergenceBpsAtPublish.median.toFixed(2)} | ${summary.divergenceBpsAtPublish.p99.toFixed(2)} | ${summary.divergenceBpsAtPublish.max.toFixed(2)} |`,
    `| just before the next round (the stalest the feed gets) | ${summary.divergenceBpsJustBeforeNextRound.min.toFixed(2)} | ${summary.divergenceBpsJustBeforeNextRound.median.toFixed(2)} | ${summary.divergenceBpsJustBeforeNextRound.p99.toFixed(2)} | ${summary.divergenceBpsJustBeforeNextRound.max.toFixed(2)} |`, "",
    `Cadence between rounds: min ${summary.cadenceSeconds.min} s, median ${summary.cadenceSeconds.median} s, max ${summary.cadenceSeconds.max} s.`, "",
    `shMON yield over the window: ${days.toFixed(2)} days, ${ysum.growthBps.toFixed(1)} bps, ${ysum.dailyBps.toFixed(2)} bps a day, ${ysum.apr.toFixed(2)}% APR, ${ysum.apy.toFixed(2)}% APY.`, "",
    `| round | published (UTC) | block | feed | shMonad at publish | bps | shMonad before next | bps | s since prev |`, `|---|---|---|---|---|---|---|---|---|`,
    ...out.map((o) => `| ${o.round} | ${o.iso.slice(0, 16)} | ${o.block} | ${o.feed} | ${o.shmonAtPublish} | ${o.bpsAtPublish.toFixed(2)} | ${o.shmonBeforeNext ?? ""} | ${o.bpsBeforeNext?.toFixed(2) ?? ""} | ${o.secondsSincePrev ?? ""} |`),
  ].join("\n") + "\n";
  fs.writeFileSync(path.join(OUT, `feed-divergence-${N}d.md`), md);
  console.log(JSON.stringify({ summary, yield: ysum }, null, 2));
}
main().catch((e) => { console.error(e); process.exit(1); });
