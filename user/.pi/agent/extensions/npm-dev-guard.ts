import {
  ToolCallEvent,
  type BashToolCallEvent,
  type ExtensionAPI,
} from "@mariozechner/pi-coding-agent";

const patterns = [/\b(npm|pnpm|yarn)\s+run\s+dev\b/, /\b(pnpm|yarn)\s+dev\b/];

/**
 * Inspects tool calls and prevents running `npm run dev` via bash.
 */
export default function (pi: ExtensionAPI) {
  pi.on("tool_call", (event) => {
    if (!isBashToolCallEvent(event)) {
      return;
    }
    if (patterns.some((pattern) => pattern.test(event.input.command))) {
      return {
        block: true,
        reason:
          "starting the dev server is not needed, it's already running. If it was to verify the project, use `npm run build` instead.",
      };
    }
  });
}

function isBashToolCallEvent(event: ToolCallEvent): event is BashToolCallEvent {
  return event.toolName === "bash";
}
