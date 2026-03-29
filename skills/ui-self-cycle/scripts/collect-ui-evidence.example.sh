#!/usr/bin/env bash
set -euo pipefail

# Example Playwright evidence collector used by ui-self-cycle.
# It captures screenshots, console failures, failed requests, and simple DOM metadata.

PROJECT_ROOT="${PROJECT_ROOT:-$(pwd)}"
STATE_DIR="${STATE_DIR:-$PROJECT_ROOT/.ralph/ui-self-cycle}"
EVIDENCE_DIR="$STATE_DIR/evidence/run-$(date -u +%Y%m%dT%H%M%SZ)"
BASE_URL="${BASE_URL:-}"
ENTRY_PAGES="${ENTRY_PAGES:-/}"
VIEWPORTS="${VIEWPORTS:-375x812 768x1024 1440x900}"

mkdir -p "$EVIDENCE_DIR"

fail() {
  printf 'ERROR: %s\n' "$*" >&2
  exit 1
}

ensure_base_url() {
  if [[ -n "$BASE_URL" ]]; then
    return 0
  fi
  if [[ -f "$STATE_DIR/base-url.txt" ]]; then
    BASE_URL="$(cat "$STATE_DIR/base-url.txt")"
  fi
  [[ -n "$BASE_URL" ]] || fail "BASE_URL not provided and $STATE_DIR/base-url.txt missing"
}

ensure_playwright() {
  if command -v npx >/dev/null 2>&1 && npx playwright --version >/dev/null 2>&1; then
    return 0
  fi
  fail "Playwright CLI unavailable; cannot collect browser evidence"
}

ensure_base_url
ensure_playwright

TMP_SCRIPT="$EVIDENCE_DIR/collect-ui-evidence.mjs"
cat >"$TMP_SCRIPT" <<'EOF'
import { chromium } from 'playwright';
import fs from 'node:fs';
import path from 'node:path';

const baseUrl = process.env.BASE_URL;
const entryPages = (process.env.ENTRY_PAGES || '/').split(/\s+/).filter(Boolean);
const viewports = (process.env.VIEWPORTS || '375x812 768x1024 1440x900')
  .split(/\s+/)
  .filter(Boolean)
  .map(v => {
    const [w, h] = v.split('x').map(Number);
    return { width: w, height: h, label: v };
  });
const evidenceDir = process.env.EVIDENCE_DIR;

const consoleIssues = [];
const networkIssues = [];
const domFacts = [];

const browser = await chromium.launch({ headless: true });

for (const viewport of viewports) {
  const context = await browser.newContext({ viewport: { width: viewport.width, height: viewport.height } });
  const page = await context.newPage();

  page.on('console', msg => {
    if (msg.type() === 'error' || msg.type() === 'warning') {
      consoleIssues.push({ viewport: viewport.label, type: msg.type(), text: msg.text() });
    }
  });

  page.on('pageerror', err => {
    consoleIssues.push({ viewport: viewport.label, type: 'pageerror', text: String(err) });
  });

  page.on('response', response => {
    if (response.status() >= 400) {
      networkIssues.push({
        viewport: viewport.label,
        status: response.status(),
        method: response.request().method(),
        url: response.url()
      });
    }
  });

  for (const route of entryPages) {
    const url = new URL(route, baseUrl).toString();
    await page.goto(url, { waitUntil: 'networkidle', timeout: 45000 });

    const slug = route.replace(/[^a-z0-9]+/gi, '_').replace(/^_+|_+$/g, '') || 'root';
    const prefix = `${viewport.label}__${slug}`;

    await page.screenshot({ path: path.join(evidenceDir, `${prefix}.png`), fullPage: true });

    const facts = await page.evaluate(() => {
      const body = document.body;
      const active = document.activeElement;
      const overflowX = Math.max(body.scrollWidth - window.innerWidth, 0);
      const buttons = [...document.querySelectorAll('button,[role="button"],a,input,select,textarea')]
        .slice(0, 50)
        .map(el => ({
          tag: el.tagName,
          text: (el.textContent || '').trim().slice(0, 120),
          disabled: !!el.disabled,
          ariaLabel: el.getAttribute('aria-label'),
          visible: !!(el.offsetWidth || el.offsetHeight || el.getClientRects().length)
        }));
      return {
        title: document.title,
        url: location.href,
        activeTag: active ? active.tagName : null,
        activeLabel: active ? active.getAttribute('aria-label') : null,
        overflowX,
        buttons
      };
    });

    domFacts.push({ viewport: viewport.label, route, facts });
    fs.writeFileSync(path.join(evidenceDir, `${prefix}.dom.json`), JSON.stringify(facts, null, 2));
  }

  await context.close();
}

await browser.close();

fs.writeFileSync(path.join(evidenceDir, 'console-issues.json'), JSON.stringify(consoleIssues, null, 2));
fs.writeFileSync(path.join(evidenceDir, 'network-issues.json'), JSON.stringify(networkIssues, null, 2));
fs.writeFileSync(path.join(evidenceDir, 'dom-facts.json'), JSON.stringify(domFacts, null, 2));
EOF

export BASE_URL ENTRY_PAGES VIEWPORTS EVIDENCE_DIR
npx playwright test --version >/dev/null 2>&1 || true
node "$TMP_SCRIPT" || fail "Playwright evidence collection failed"

printf 'evidence_dir=%s\n' "$EVIDENCE_DIR"
printf 'console_issues=%s\n' "$EVIDENCE_DIR/console-issues.json"
printf 'network_issues=%s\n' "$EVIDENCE_DIR/network-issues.json"
printf 'dom_facts=%s\n' "$EVIDENCE_DIR/dom-facts.json"
