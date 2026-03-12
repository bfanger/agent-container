import type {
  ExtensionAPI,
  ReadToolCallEvent,
  ToolCallEvent,
} from "@mariozechner/pi-coding-agent";

/**
 * Prevent reading images when the model doesn't support vision
 */
export default function (pi: ExtensionAPI) {
  pi.on("tool_call", async (event, ctx) => {
    if (!isReadToolCallEvent(event) || ctx.model?.input.includes("image")) {
      return;
    }
    if (/\.(jpg|jpeg|png|gif|webp)$/i.test(event.input.path)) {
      return {
        block: true,
        reason: `vision is disabled, unable to describe the image`,
      };
    }
  });
}

function isReadToolCallEvent(event: ToolCallEvent): event is ReadToolCallEvent {
  return event.toolName === "read";
}
