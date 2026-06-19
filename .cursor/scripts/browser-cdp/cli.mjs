#!/usr/bin/env node
/**
 * CDP CLI fallback when Chrome DevTools MCP is unavailable in cloud agents.
 * Attaches to the Desktop Chrome instance on port 9222 (same profile as start-chrome-debug.sh).
 */
import fs from "node:fs";
import path from "node:path";
import process from "node:process";
import puppeteer from "puppeteer-core";

const BROWSER_URL = process.env.CHROME_DEBUG_URL ?? "http://127.0.0.1:9222";
const DEFAULT_TIMEOUT_MS = Number(process.env.BROWSER_CDP_TIMEOUT_MS ?? 30_000);

let browser;
let activePage;

function usage() {
  console.log(`Usage: browser-cdp.sh <command> [options]

Commands:
  list-pages                         List open tabs
  select-page <index|url-fragment>   Focus a tab (0-based index or URL substring)
  navigate <url>                     Go to URL on the active tab
  snapshot [--limit N]               Print interactive elements (buttons, links, inputs)
  screenshot [--out PATH]            Save PNG screenshot (default: /tmp/browser-cdp.png)
  click --text TEXT                  Click element containing visible text
  click --selector CSS               Click element by CSS selector
  click --aria LABEL                 Click element by aria-label
  fill --selector CSS --value TEXT   Fill an input/textarea
  upload --selector CSS --file PATH  Upload file(s) to <input type="file">
  wait --text TEXT                   Wait until text appears
  wait --selector CSS                Wait until selector matches
  evaluate --script JS               Run JS in page context (JSON result printed)
  url                                Print active tab URL
  title                              Print active tab title

Environment:
  CHROME_DEBUG_URL     Default: http://127.0.0.1:9222
  BROWSER_CDP_TIMEOUT_MS  Default: 30000
`);
}

function parseArgs(argv) {
  const args = [...argv];
  const opts = {};
  const positional = [];

  while (args.length > 0) {
    const token = args[0];
    if (token === "--text") {
      opts.text = args[1];
      args.splice(0, 2);
    } else if (token === "--selector") {
      opts.selector = args[1];
      args.splice(0, 2);
    } else if (token === "--aria") {
      opts.aria = args[1];
      args.splice(0, 2);
    } else if (token === "--value") {
      opts.value = args[1];
      args.splice(0, 2);
    } else if (token === "--file") {
      opts.file = args[1];
      args.splice(0, 2);
    } else if (token === "--out") {
      opts.out = args[1];
      args.splice(0, 2);
    } else if (token === "--script") {
      opts.script = args[1];
      args.splice(0, 2);
    } else if (token === "--limit") {
      opts.limit = Number(args[1]);
      args.splice(0, 2);
    } else if (token === "--timeout") {
      opts.timeout = Number(args[1]);
      args.splice(0, 2);
    } else if (token.startsWith("--")) {
      throw new Error(`Unknown option: ${token}`);
    } else {
      positional.push(args.shift());
    }
  }

  return { command: positional[0], positional: positional.slice(1), opts };
}

async function getBrowser() {
  if (!browser) {
    browser = await puppeteer.connect({ browserURL: BROWSER_URL, defaultViewport: null });
  }
  return browser;
}

async function getPage() {
  const b = await getBrowser();
  if (activePage && !activePage.isClosed()) {
    return activePage;
  }

  const pages = await b.pages();
  activePage = pages.find((p) => p.url().includes("higgsfield.ai")) ?? pages[0];
  if (!activePage) {
    activePage = await b.newPage();
  }
  activePage.setDefaultTimeout(DEFAULT_TIMEOUT_MS);
  return activePage;
}

async function listPages() {
  const pages = await (await getBrowser()).pages();
  for (const [index, page] of pages.entries()) {
    const marker = activePage && page === activePage ? "*" : " ";
    console.log(`${marker} [${index}] ${page.url()}`);
  }
}

async function selectPage(target) {
  const pages = await (await getBrowser()).pages();
  let page;

  if (/^\d+$/.test(target)) {
    page = pages[Number(target)];
  } else {
    page = pages.find((p) => p.url().includes(target));
  }

  if (!page) {
    throw new Error(`No page matched: ${target}`);
  }

  activePage = page;
  await page.bringToFront();
  console.log(`selected: [${pages.indexOf(page)}] ${page.url()}`);
}

async function clickElement(opts) {
  const page = await getPage();

  if (opts.selector) {
    await page.click(opts.selector);
    console.log(`clicked selector: ${opts.selector}`);
    return;
  }

  if (opts.aria) {
    const handle = await page.waitForSelector(`[aria-label="${opts.aria.replace(/"/g, '\\"')}"]`);
    await handle.click();
    console.log(`clicked aria-label: ${opts.aria}`);
    return;
  }

  if (opts.text) {
    const clicked = await page.evaluate((text) => {
      const normalized = text.trim().toLowerCase();
      const candidates = [...document.querySelectorAll("button, a, [role='button'], label, span, div")];
      for (const el of candidates) {
        const visible = el instanceof HTMLElement && el.offsetParent !== null;
        const content = (el.textContent ?? "").trim().toLowerCase();
        if (visible && content.includes(normalized)) {
          el.click();
          return true;
        }
      }
      return false;
    }, opts.text);

    if (!clicked) {
      throw new Error(`No visible element contains text: ${opts.text}`);
    }
    console.log(`clicked text: ${opts.text}`);
    return;
  }

  throw new Error("click requires --text, --selector, or --aria");
}

async function fillField(opts) {
  if (!opts.selector || opts.value === undefined) {
    throw new Error("fill requires --selector and --value");
  }

  const page = await getPage();
  await page.waitForSelector(opts.selector);
  await page.focus(opts.selector);
  await page.click(opts.selector, { clickCount: 3 });
  await page.keyboard.type(opts.value);
  console.log(`filled ${opts.selector}`);
}

async function uploadFiles(opts) {
  if (!opts.selector || !opts.file) {
    throw new Error("upload requires --selector and --file");
  }

  const filePath = path.resolve(opts.file);
  if (!fs.existsSync(filePath)) {
    throw new Error(`File not found: ${filePath}`);
  }

  const page = await getPage();
  const input = await page.waitForSelector(opts.selector);
  await input.uploadFile(filePath);
  console.log(`uploaded ${filePath} via ${opts.selector}`);
}

async function waitFor(opts) {
  const page = await getPage();
  const timeout = opts.timeout ?? DEFAULT_TIMEOUT_MS;

  if (opts.selector) {
    await page.waitForSelector(opts.selector, { timeout });
    console.log(`found selector: ${opts.selector}`);
    return;
  }

  if (opts.text) {
    await page.waitForFunction(
      (text) => document.body?.innerText?.includes(text),
      { timeout },
      opts.text,
    );
    console.log(`found text: ${opts.text}`);
    return;
  }

  throw new Error("wait requires --text or --selector");
}

async function takeSnapshot(opts) {
  const page = await getPage();
  const limit = opts.limit ?? 80;
  const items = await page.evaluate((max) => {
    const out = [];
    const nodes = document.querySelectorAll(
      "a, button, input, textarea, select, [role='button'], [role='link'], [contenteditable='true']",
    );

    for (const el of nodes) {
      if (!(el instanceof HTMLElement) || el.offsetParent === null) {
        continue;
      }

      const tag = el.tagName.toLowerCase();
      const text = (el.textContent ?? "").trim().replace(/\s+/g, " ").slice(0, 120);
      const aria = el.getAttribute("aria-label") ?? "";
      const placeholder = el.getAttribute("placeholder") ?? "";
      const type = el.getAttribute("type") ?? "";
      const name = el.getAttribute("name") ?? "";
      const id = el.id ? `#${el.id}` : "";
      const classes = el.className && typeof el.className === "string"
        ? `.${el.className.trim().split(/\s+/).slice(0, 2).join(".")}`
        : "";

      let selector = tag;
      if (id) {
        selector = id;
      } else if (name) {
        selector = `${tag}[name="${name}"]`;
      } else if (aria) {
        selector = `${tag}[aria-label="${aria}"]`;
      } else if (placeholder) {
        selector = `${tag}[placeholder="${placeholder}"]`;
      } else if (classes) {
        selector = `${tag}${classes}`;
      }

      out.push({
        tag,
        type,
        text,
        aria,
        placeholder,
        selector,
      });

      if (out.length >= max) {
        break;
      }
    }

    return out;
  }, limit);

  console.log(`url: ${page.url()}`);
  console.log(`title: ${await page.title()}`);
  for (const [index, item] of items.entries()) {
    const bits = [
      `[${index}]`,
      item.tag,
      item.type ? `type=${item.type}` : null,
      item.text ? `text="${item.text}"` : null,
      item.aria ? `aria="${item.aria}"` : null,
      item.placeholder ? `placeholder="${item.placeholder}"` : null,
      `selector=${item.selector}`,
    ].filter(Boolean);
    console.log(bits.join(" "));
  }
}

async function takeScreenshot(opts) {
  const page = await getPage();
  const out = opts.out ?? "/tmp/browser-cdp.png";
  await page.screenshot({ path: out, fullPage: false });
  console.log(out);
}

async function evaluateScript(opts) {
  if (!opts.script) {
    throw new Error("evaluate requires --script");
  }

  const page = await getPage();
  const result = await page.evaluate((source) => {
    // eslint-disable-next-line no-eval
    return eval(source);
  }, opts.script);

  console.log(JSON.stringify(result, null, 2));
}

async function main() {
  const { command, positional, opts } = parseArgs(process.argv.slice(2));

  if (!command || command === "help" || command === "--help" || command === "-h") {
    usage();
    return;
  }

  try {
    switch (command) {
      case "list-pages":
        await listPages();
        break;
      case "select-page":
        if (!positional[0]) throw new Error("select-page requires index or URL fragment");
        await selectPage(positional[0]);
        break;
      case "navigate":
        if (!positional[0]) throw new Error("navigate requires a URL");
        await (await getPage()).goto(positional[0], { waitUntil: "domcontentloaded" });
        console.log((await getPage()).url());
        break;
      case "snapshot":
        await takeSnapshot(opts);
        break;
      case "screenshot":
        await takeScreenshot(opts);
        break;
      case "click":
        await clickElement(opts);
        break;
      case "fill":
        await fillField(opts);
        break;
      case "upload":
        await uploadFiles(opts);
        break;
      case "wait":
        await waitFor(opts);
        break;
      case "evaluate":
        await evaluateScript(opts);
        break;
      case "url":
        console.log((await getPage()).url());
        break;
      case "title":
        console.log(await (await getPage()).title());
        break;
      default:
        throw new Error(`Unknown command: ${command}`);
    }
  } finally {
    if (browser) {
      await browser.disconnect();
    }
  }
}

main().catch((error) => {
  console.error(`browser-cdp error: ${error.message}`);
  process.exit(1);
});
