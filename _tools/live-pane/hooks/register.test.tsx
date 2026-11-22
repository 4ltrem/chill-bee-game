import { expect, test } from 'claude-code/testing'

const PANE = {
  plugin: 'live-pane',
  component: 'Pane',
  requestId: 'live',
  props: {
    title: 'Live runs',
    isFocused: false,
    bodyColumns: 50,
    placement: 'dock',
    scroll: { offset: 0, bodyRows: 30 },
    view: {},
  },
} as const

test('an empty pane says nothing runs, on every surface', async $ => {
  for (const surface of ['terminal', 'desktop', 'vscode', 'mobile'] as const) {
    const ui = await $.ui.mount({ ...PANE, surface })
    expect((await ui.find({ type: 'Text', text: /nothing running/ }))?.text).toBe('nothing running')
    expect((await ui.find({ type: 'Text', text: /Last events/ }))?.text).toBe('Last events')
    await ui.unmount()
  }
})
