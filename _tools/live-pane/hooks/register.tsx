import { atom, read, update } from 'claude-code'
import type { Register } from 'claude-code'

import type { LiveEvent, LiveItem, LiveView } from '../types'

// The live pane (future-tbd 5c): what _tools/live.py records, beside the chat. live.json holds what runs now
// (agents and script steps, dead processes pruned by live.py), live.log one line per start, end, note and tool call.
const PANE = 'live'
const TITLE = 'Live runs'
const LIVE = '_meta/usage/live.json'
const LOG = '_meta/usage/live.log'
const TAIL = 32768
const view = atom({ plugin: 'live-pane', key: 'view' } as const, { items: [], events: [], readAt: '' } as LiveView, {
  shape: 'view-1',
})

const clock = (ts: string) => {
  const d = new Date(ts)
  return isNaN(d.getTime()) ? '--:--' : d.toTimeString().slice(0, 8)
}

const items = (text: string, at: number): LiveItem[] => {
  let cur: Record<string, any> = {}
  try {
    cur = JSON.parse(text)
  } catch {
    return []
  }
  return Object.values(cur)
    .map((r: any) => ({
      name: String(r.agent ?? '?'),
      kind: String(r.kind ?? 'agent'),
      tag: String(r.tag ?? ''),
      note: String(r.note ?? ''),
      mins: Math.floor((at - new Date(r.start).getTime()) / 60000),
      start: String(r.start ?? ''),
    }))
    .filter(r => r.mins >= 0 && r.mins < 12 * 60)
    .sort((a, b) => a.start.localeCompare(b.start))
    .map(({ start, ...r }) => r)
}

const events = (text: string): LiveEvent[] =>
  text
    .split('\n')
    .slice(1) // the first line of a tail may be cut
    .flatMap(l => {
      try {
        const r = JSON.parse(l)
        return [{ ts: String(r.ts ?? ''), kind: String(r.kind ?? ''), name: String(r.name ?? '?'),
                  tag: String(r.tag ?? ''), text: String(r.text ?? ''), ok: r.ok !== false }]
      } catch {
        return []
      }
    })

export const register: Register = on => {
  on('session.start', async ($, e, next) => {
    await $.command.register({ name: 'live', description: 'Open the live pane: headless agents and script steps running now' })
    void $.ui.open({ id: PANE, title: TITLE })
    $.clock.every(2000, async () => {
      let liveText = '{}'
      let logText = ''
      try {
        liveText = await $.fs.read(LIVE)
      } catch {}
      try {
        const { size } = await $.fs.stat(LOG)
        const offset = Math.max(0, size - TAIL)
        logText = await $.fs.read(LOG, { offset, length: size - offset })
        if (offset === 0) logText = '\n' + logText
      } catch {}
      const fresh: LiveView = { items: items(liveText, Date.now()), events: events(logText).slice(-60), readAt: new Date().toISOString() }
      const old = await read($, view)
      if (JSON.stringify({ ...old, readAt: '' }) !== JSON.stringify({ ...fresh, readAt: '' })) {
        await update($, view, () => fresh)   // redraws the pane only when something changed
      }
    })
    return next(e)
  })

  on('command.run', { command: 'live' }, async $ => {
    await $.ui.open({ id: PANE, title: TITLE })
    return { text: 'Live pane opened.' }
  })

  on('ui.render', { component: 'Pane', requestId: PANE }, async ($, e) => {
    const { Box, Text } = $.ui.resolve(e)
    const v = await read($, view)
    const rows = Math.max(4, (e.viewport?.rows ?? 30) - 4)
    const width = Math.max(20, (e.viewport?.columns ?? 50) - 2)
    const cut = (s: string) => (s.length > width ? s.slice(0, width - 1) + '…' : s)
    const tags = [...new Set(v.items.map(i => i.tag))]
    const room = Math.max(2, rows - v.items.length - tags.length - 3)
    return (
      <Box flexDirection="column">
        <Text bold>Running now</Text>
        {v.items.length === 0 && <Text dimColor>nothing running</Text>}
        {tags.map(tag => (
          <Box flexDirection="column">
            <Text dimColor>{cut('▶ ' + (tag || 'no loop'))}</Text>
            {v.items
              .filter(i => i.tag === tag)
              .map(i => (
                <Text>{cut(`  ${i.name} ${i.mins}m${i.note ? ' · ' + i.note : ''}`)}</Text>
              ))}
          </Box>
        ))}
        <Text> </Text>
        <Text bold>Last events</Text>
        {v.events.length === 0 && <Text dimColor>none yet (python -I _tools/watch.py follows the same log)</Text>}
        {v.events.slice(-room).map(ev => (
          <Text dimColor={ev.kind === 'tool'}>
            {cut(`${clock(ev.ts)} ${ev.kind === 'end' ? (ev.ok ? '✓' : '✗') : ev.kind === 'start' ? '▶' : ev.kind === 'tool' ? '·' : '…'} ${ev.name} ${ev.text}`)}
          </Text>
        ))}
      </Box>
    )
  })
}
