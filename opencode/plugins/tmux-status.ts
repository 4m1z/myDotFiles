// tmux-status — opencode V2 plugin reporting session status to tmux.
//
// The tmux-opencode-session-manager keeps one tmux session per project
// directory on a dedicated tmux server socket (default "opencode-popup").
// This plugin stamps that tmux session with @opencode_state /
// @opencode_state_at / @opencode_detail so the picker can show whether each
// session is working / waiting / idle without scraping pane contents.
//
// Why this exists (V2 note): plugins run inside the background opencode
// service, NOT inside the tmux pane, so $TMUX/$TMUX_PANE are unavailable.
// Instead we map the event's project directory to the tmux session name with
// the same hash the launcher uses:  oc_<cksum-of-dir>.
//
// No imports on purpose: a plain default export with `id` + `setup()` loads
// in V2 without needing "@opencode/plugin" to resolve (same pattern as
// rtk.ts in this directory).
import { spawnSync } from "node:child_process"

type State = "working" | "waiting" | "idle"

function optsOf(ctx: any): { socket: string; prefix: string } {
  const o = (ctx?.options ?? {}) as Record<string, unknown>
  return {
    socket: typeof o.socket === "string" && o.socket ? o.socket : "opencode-popup",
    prefix: typeof o.prefix === "string" && o.prefix ? o.prefix : "oc_",
  }
}

// Same naming as scripts/helpers.sh session_hash():
//   printf '%s' "$dir" | cksum | cut -d' ' -f1
function tmuxSessionFor(prefix: string, dir: string): string | undefined {
  try {
    const r = spawnSync("cksum", [], { input: dir, encoding: "utf-8", timeout: 2000 })
    if (r.status !== 0) return undefined
    const hash = String(r.stdout ?? "").trim().split(/\s+/)[0]
    if (!hash) return undefined
    return `${prefix}${hash}`
  } catch {
    return undefined
  }
}

function stamp(socket: string, session: string, state: State, detail: string): void {
  const clean = String(detail ?? "").replace(/[\t\r\n]+/g, " ").slice(0, 80)
  try {
    spawnSync("tmux", ["-L", socket, "set-option", "-t", session, "@opencode_state", state], { timeout: 2000 })
    spawnSync("tmux", ["-L", socket, "set-option", "-t", session, "@opencode_state_at", String(Math.floor(Date.now() / 1000))], { timeout: 2000 })
    if (clean) {
      spawnSync("tmux", ["-L", socket, "set-option", "-t", session, "@opencode_detail", clean], { timeout: 2000 })
    }
  } catch {
    // tmux socket/session may not exist (yet) — picker falls back to the API.
  }
}

async function directoryOf(ctx: any, event: any): Promise<string | undefined> {
  const loc = event?.location?.directory ?? event?.data?.directory
  if (typeof loc === "string" && loc) return loc
  const sessionID = event?.data?.sessionID ?? event?.sessionID
  if (typeof sessionID === "string" && sessionID && ctx?.session?.get) {
    try {
      const info = await ctx.session.get({ sessionID })
      const dir = info?.location?.directory ?? info?.data?.location?.directory
      if (typeof dir === "string" && dir) return dir
    } catch {
      // session may be gone; ignore
    }
  }
  // Last resort: the directory this plugin instance loaded for.
  const fallback = ctx?.location?.directory
  return typeof fallback === "string" && fallback ? fallback : undefined
}

function describe(event: any): string {
  const d = event?.data ?? {}
  const bits: string[] = []
  if (typeof d.tool === "string") bits.push(d.tool)
  if (typeof d.action === "string") bits.push(d.action)
  if (typeof d.status === "string") bits.push(d.status)
  else if (d?.status?.type) bits.push(String(d.status.type))
  if (typeof d.title === "string") bits.push(d.title)
  if (typeof d.message === "string") bits.push(d.message)
  return bits.join(" ").slice(0, 80)
}

const WORKING = new Set([
  "session.status", // data.status.type === "busy" (checked below)
  "session.execution.started",
  "session.step.started",
  "session.tool.called",
  "session.text.started",
  "session.reasoning.started",
  "session.shell.started",
  "session.compaction.started",
  "command.executed",
])

const IDLE = new Set([
  "session.idle",
  "session.execution.succeeded",
  "session.execution.failed",
  "session.execution.interrupted",
])

export default {
  id: "tmux-status",
  async setup(ctx: any) {
    const { socket, prefix } = optsOf(ctx)

    const set = async (event: any, state: State, detail: string) => {
      const dir = await directoryOf(ctx, event)
      if (!dir) return
      const session = tmuxSessionFor(prefix, dir)
      if (!session) return
      stamp(socket, session, state, detail || state)
    };

    // Synchronous hooks: instant signal, no event-stream delay.
    try {
      await ctx.tool.hook("execute.before", (event: any) => {
        void set(event, "working", `tool ${String(event?.tool ?? "?")}`)
      })
    } catch {
      // older server without tool hooks — events below still cover status
    }
    try {
      await ctx.session.hook("prompt", (event: any) => {
        void set(event, "working", "prompt sent")
      })
    } catch {
      // ignore
    }

    // Event stream: authoritative idle/waiting transitions.
    const controller = new AbortController()
    void (async () => {
      try {
        for await (const event of ctx.event.subscribe({ signal: controller.signal })) {
          try {
            const type = String(event?.type ?? "")
            if (type === "permission.asked") {
              await set(event, "waiting", `permission ${describe(event) || "approval needed"}`)
            } else if (type === "permission.replied" || type === "form.replied") {
              await set(event, "working", "approved — resuming")
            } else if (type === "form.created") {
              await set(event, "waiting", describe(event) || "input needed")
            } else if (type === "session.status") {
              const st = (event as any)?.data?.status?.type
              if (st === "busy") await set(event, "working", describe(event) || "working")
              else if (st === "idle") await set(event, "idle", "done — your move")
              // "retry" keeps previous state; a start/idle event follows shortly
            } else if (type === "session.created") {
              await set(event, "idle", "ready")
            } else if (IDLE.has(type)) {
              await set(event, "idle", type === "session.idle" ? "done — your move" : describe(event) || "done")
            } else if (WORKING.has(type)) {
              await set(event, "working", describe(event) || "working")
            }
          } catch {
            // one bad event must not kill the loop
          }
        }
      } catch {
        // aborted on unload
      }
    })()

    return () => controller.abort()
  },
}
