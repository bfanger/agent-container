import type { ExtensionAPI } from "@earendil-works/pi-coding-agent";

const quitPrompts = ["q", ":q", "quit", "exit"];

export default function (pi: ExtensionAPI) {
  pi.on("input", async (event, ctx) => {
    if (quitPrompts.includes(event.text)) {
      ctx.shutdown();
      return { action: "handled" };
    }
    return { action: "continue" };
  });
}
