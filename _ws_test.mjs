import WebSocket from "ws";
import { readFileSync } from "fs";

const TOKEN = readFileSync("/tmp/raiko-auth-token.txt", "utf8").trim();
const URL = "wss://raiko.olive-dev.com/ws";

const cases = [
  { label: "no token            ", url: URL, opts: {} },
  { label: "wrong token (header)", url: URL, opts: { headers: { "X-Raiko-Token": "wrong" } } },
  { label: "OLD token raiko-dev ", url: URL, opts: { headers: { "X-Raiko-Token": "raiko-dev" } } },
  { label: "wrong token (query) ", url: `${URL}?token=wrong`, opts: {} },
  { label: "RIGHT token (header)", url: URL, opts: { headers: { "X-Raiko-Token": TOKEN } } },
  { label: "RIGHT token (query) ", url: `${URL}?token=${encodeURIComponent(TOKEN)}`, opts: {} },
];

function probe({ label, url, opts }) {
  return new Promise((resolve) => {
    const ws = new WebSocket(url, opts);
    let opened = false;
    const t = setTimeout(() => { try { ws.terminate(); } catch {} resolve(`${label} → TIMEOUT`); }, 4000);
    ws.on("open",  () => { opened = true; ws.close(1000); });
    ws.on("close", (code, reason) => {
      clearTimeout(t);
      const r = reason?.toString?.() || "";
      resolve(`${label} → ${opened ? "OPEN(101) then " : ""}close=${code}${r ? ` reason="${r}"` : ""}`);
    });
    ws.on("error", () => {}); // close fires next
  });
}

for (const c of cases) {
  console.log(await probe(c));
}
