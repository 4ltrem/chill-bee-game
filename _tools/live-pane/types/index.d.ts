export type LiveItem = { name: string; kind: string; tag: string; mins: number; note: string }
export type LiveEvent = { ts: string; kind: string; name: string; tag: string; text: string; ok: boolean }
export type LiveView = { items: LiveItem[]; events: LiveEvent[]; readAt: string }

declare module 'claude-code' {
  interface PluginState {
    'live-pane': { view: Shaped<LiveView> }
  }
}
