// tmux-status — opencode V2 plugin reporting session status to tmux.
//
// The tmux-opencode-session-manager keeps one tmux session per project
// directory on a dedicated tmux server socket (default "opencode-popup").
// This plugin stamps that tmux session with @opencode_state /
// @opencode_state_at / @opencode_detail so the picker and the persistent
// status-line indicators can show whether each session is working / waiting /
// done / error / idle without scraping pane contents.
//
// Why this exists (V2 note): plugins run inside the background opencode
// service, NOT inside the tmux pane, so $TMUX/$TMUX_PANE are unavailable.
// Instead we map the event's project directory to the tmux session name with
// the same hash the launcher uses:  oc_<cksum-of-dir>.
//
// State model (shared with scripts/statusline.sh, scripts/reconcile.sh,
// scripts/picker.sh, scripts/ack.sh):
//   working  agent is actively running (animated spinner in tmux)
//   waiting  needs input: permission request or open question (attention)
//   done     turn finished, unacknowledged (stays until ack.sh runs on open)
//   error    run failed / session errored (stays until next task starts)
//   idle     no work outstanding, acknowledged (dim, distinct from done)
// Never infer completion from silence: only explicit idle/error events (or
// the reconcile daemon's outcome-based promotion) produce done/error.
//
// No imports on purpose: a plain default export with `id` + `setup()` loads
// in V2 without needing "@opencode/plugin" to resolve (same pattern as
// rtk.ts in this directory).
import { spawnSync } from "node:child_process"

type State = "working" | "waiting" | "done" | "error" | "idle"

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

// Normalize the many envelope shapes opencode V2 can deliver:
//   - legacy/V1-style:          { type, data/sessionID/... }
//   - V2 global event:          { directory, payload: { type, properties } }
//   - V2 direct event:          { type, properties: { sessionID, ... } }
// Returns { type, props, sessionID, directory } with best-effort extraction.
function normalize(event: any): { type: string; props: any; sessionID?: string; directory?: string } {
  const e = event ?? {}
  if (e.payload && typeof e.payload.type === "string") {
    const props = e.payload.properties ?? e.payload.data ?? {}
    return {
      type: e.payload.type,
      props,
      sessionID: props.sessionID ?? e.sessionID,
      directory: typeof e.directory === "string" ? e.directory : undefined,
    }
  }
  const props = e.properties ?? e.data ?? {}
  const type = typeof e.type === "string" ? e.type : ""
  return {
    type,
    props,
    sessionID: props.sessionID ?? e.sessionID ?? e.data?.sessionID,
    directory: e.directory ?? e.location?.directory,
  }
}

async function directoryOf(ctx: any, norm: { sessionID?: string; directory?: string }): Promise<string | undefined> {
  if (norm.directory) return norm.directory
  const sessionID = norm.sessionID
  if (typeof sessionID === "string" && sessionID) {
    // Preferred: resolve the owning project directory from the session.
    try {
      if (ctx?.session?.get) {
        const info = await ctx.session.get({ sessionID })
        const dir = info?.location?.directory ?? info?.data?.location?.directory
        if (typeof dir === "string" && dir) return dir
      }
    } catch {
      // session may be gone; ignore
    }
    try {
      if (ctx?.client?.session?.get) {
        const info = await ctx.client.session.get(sessionID)
        const dir = (info as any)?.data?.location?.directory ?? (info as any)?.location?.directory
        if (typeof dir === "string" && dir) return dir
      }
    } catch {
      // ignore
    }
  }
  // Last resort: the directory this plugin instance loaded for.
  const fallback = ctx?.directory ?? ctx?.project?.worktree ?? ctx?.location?.directory
  return typeof fallback === "string" && fallback ? fallback : undefined
}

function shortProps(props: any): string {
  const bits: string[] = []
  if (typeof props?.permission === "string") bits.push(props.permission)
  if (typeof props?.tool === "string") bits.push(props.tool)
  else if (typeof props?.tool?.name === "string") bits.push(props.tool.name)
  if (typeof props?.status === "string") bits.push(props.status)
  else if (props?.status?.type) bits.push(String(props.status.type))
  if (typeof props?.error === "string") bits.push(props.error)
  else if (props?.error?.message) bits.push(String(props.error.message))
  if (typeof props?.finish === "string") bits.push(props.finish)
  const qs = props?.questions
  if (Array.isArray(qs) && qs.length && typeof qs[0]?.header === "string") bits.push(qs[0].header)
  else if (Array.isArray(qs) && qs.length && typeof qs[0]?.question === "string") bits.push(String(qs[0].question).slice(0, 40))
  return bits.join(" ").slice(0, 80)
}

// Legacy (pre-V2-service) event names some servers still emit. Kept as a
// fallback so status keeps working across opencode versions; the V2 names
// above are authoritative on v2.0.x.
const LEGACY_WORKING = new Set([
  "session.execution.started",
  "session.step.started",
  "session.tool.called",
  "session.text.started",
  "session.reasoning.started",
  "session.shell.started",
  "session.compaction.started",
  "session.prompted",
  "command.executed",
  "session.next.prompted",
])

const LEGACY_IDLE = new Set([
  "session.execution.succeeded",
  "session.execution.interrupted",
])

export default {
  id: "tmux-status",
  async setup(ctx: any) {
    const { socket, prefix } = optsOf(ctx)

    const set = async (rawEvent: any, state: State, detail: string) => {
      const norm = normalize(rawEvent)
      const dir = await directoryOf(ctx, norm)
      if (!dir) return
      const session = tmuxSessionFor(prefix, dir)
      if (!session) return
      stamp(socket, session, state, detail || state)
    };

    // Synchronous hooks: instant signal, no event-stream delay.
    try {
      await ctx.tool.hook("execute.before", (event: any) => {
        const tool = event?.tool ?? normalize(event).props?.tool
        void set(event, "working", `tool ${String(tool ?? "?")}`)
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

    const onEvent = async (rawEvent: any) => {
      try {
        const { type, props } = normalize(rawEvent)
        // Input requests outrank everything: a blocked run keeps reporting
        // "running" server-side, so waiting must win over working.
        if (type === "permission.asked") {
          await set(rawEvent, "waiting", `permission ${shortProps(props) || "approval needed"}`)
        } else if (type === "question.asked") {
          await set(rawEvent, "waiting", shortProps(props) || "input needed")
        } else if (
          type === "permission.replied" ||
          type === "question.replied" ||
          type === "question.rejected"
        ) {
          await set(rawEvent, "working", "approved — resuming")
        } else if (type === "session.error" || type === "session.next.step.failed") {
          await set(rawEvent, "error", shortProps(props) || "run failed")
        } else if (type === "session.idle") {
          // Authoritative turn end. `done` (not `idle`) so completion stays
          // visible until the user returns (ack.sh demotes done -> idle).
          await set(rawEvent, "done", "done — your move")
        } else if (type === "session.status") {
          const st = props?.status?.type ?? (rawEvent as any)?.data?.status?.type
          if (st === "busy") await set(rawEvent, "working", shortProps(props) || "working")
          else if (st === "idle") await set(rawEvent, "done", "done — your move")
          // "retry" keeps previous state; a start/idle event follows shortly
        } else if (type === "session.created") {
          await set(rawEvent, "idle", "ready")
        } else if (type === "session.next.step.started") {
          const agent = typeof props?.agent === "string" && props.agent ? ` ${props.agent}` : ""
          await set(rawEvent, "working", `step${agent}`.trim() || "working")
        } else if (
          type === "session.next.text.started" ||
          type === "session.next.tool.called" ||
          type === "session.next.shell.started" ||
          type === "session.next.reasoning.started"
        ) {
          await set(rawEvent, "working", shortProps(props) || "working")
        } else if (LEGACY_WORKING.has(type)) {
          await set(rawEvent, "working", shortProps(props) || "working")
        } else if (LEGACY_IDLE.has(type)) {
          await set(rawEvent, "done", shortProps(props) || "done")
        }
        // NOTE: session.next.step.ended is deliberately NOT a completion
        // signal — steps end between tool calls while the run continues.
        // Completion comes from session.idle / session.status idle.
      } catch {
        // one bad event must not kill the loop
      }
    }

    // Event stream. V2 exposes typed per-event subscriptions; older servers
    // expose a single async-iterable subscribe(). Try per-type first (precise,
    // version-proof), fall back to the shared stream.
    const wanted = [
      "permission.asked",
      "permission.replied",
      "question.asked",
      "question.replied",
      "question.rejected",
      "session.error",
      "session.next.step.failed",
      "session.idle",
      "session.status",
      "session.created",
      "session.next.step.started",
      "session.next.text.started",
      "session.next.tool.called",
      "session.next.shell.started",
      "session.next.reasoning.started",
    ]
    const controllers: AbortController[] = []
    let perTypeOk = false
    try {
      for (const t of wanted) {
        const c = new AbortController()
        const stream = ctx.event.subscribe(t, { signal: c.signal })
        if (stream && typeof stream[Symbol.asyncIterator] === "function") {
          perTypeOk = true
          controllers.push(c)
          void (async () => {
            try {
              for await (const ev of stream) await onEvent(ev)
            } catch {
              // aborted on unload
            }
          })()
        } else {
          c.abort()
        }
      }
    } catch {
      for (const c of controllers) c.abort()
      controllers.length = 0
      perTypeOk = false
    }
    if (!perTypeOk) {
      const controller = new AbortController()
      controllers.push(controller)
      void (async () => {
        try {
          for await (const event of ctx.event.subscribe({ signal: controller.signal })) {
            await onEvent(event)
          }
        } catch {
          // aborted on unload
        }
      })()
    }

    return () => {
      for (const c of controllers) c.abort()
    }
  },
}
