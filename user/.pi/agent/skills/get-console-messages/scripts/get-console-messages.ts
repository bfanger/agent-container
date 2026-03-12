#!/usr/bin/env node
import { chromium } from "playwright";

type ConsoleMessage = {
  type: string;
  text: string;
  location?: string;
};

const url = process.argv[2];

if (!url) {
  console.error("Usage: node browser.ts <url>");
  process.exit(1);
}

try {
  new URL(url);
  const messages = await browse(url);
  console.log(JSON.stringify(messages, null, 2));
} catch (error) {
  console.error(
    JSON.stringify(
      { error: error instanceof Error ? error.message : "Unknown error" },
      null,
      2,
    ),
  );
  process.exit(1);
}

async function browse(url: string): Promise<ConsoleMessage[]> {
  const browser = await chromium.launch({ headless: true });
  const page = await browser.newPage();

  const messages: ConsoleMessage[] = [];

  page.on("console", (msg) => {
    messages.push({
      type: msg.type(),
      text: msg.text(),
      location: msg.location().url,
    });
  });

  page.on("pageerror", (error) => {
    messages.push({
      type: "error",
      text: `Page error: ${error.message}`,
    });
  });

  try {
    await page.goto(url);
    await page.waitForLoadState("networkidle");
  } finally {
    await browser.close();
  }

  return messages;
}
