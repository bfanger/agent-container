import type { ExtensionAPI } from "@mariozechner/pi-coding-agent";

export default function (pi: ExtensionAPI) {
  pi.on("input", async (event, ctx) => {
    if (event.text === ":q" || event.text === "quit" || event.text === "exit") {
      ctx.shutdown();
      return { action: "handled" };
    }

    return { action: "continue" };
  });
}
