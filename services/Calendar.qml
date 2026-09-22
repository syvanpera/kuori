pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import qs.theme

// what is on the calendar, read from the file scripts/kuori-calendar writes. the
// fetcher runs on its own timer and does the talking to google; this side only
// reads, so the panel opening costs a file read at most, and a token never lives
// in the shell.
Singleton {
  id: root

  readonly property string home: Quickshell.env("HOME") ?? ""

  // the fetcher writes here, and cachePath would not do: that is
  // ~/.cache/quickshell/by-shell/<id>/, a directory named after this shell's
  // instance that a unit outside it has no way to compute.
  readonly property string file: `${Quickshell.env("XDG_CACHE_HOME") ?? `${root.home}/.cache`}/kuori/calendar.json`

  // a file has been read. until one has, the panel has nothing to say about any
  // day and should say so rather than "no events".
  property bool ready: false

  property date fetched: new Date(0)

  // the months the file covers, as "yyyy-MM-dd" for the first and last day.
  property string from: ""
  property string to: ""

  // calendar id -> { name, color, account }
  property var calendars: ({})

  // the same calendars in the file's order, which is what the legend lists and
  // the order a day's dots come in.
  property var list: []

  // "yyyy-MM-dd" -> the events touching that local day, in the file's order:
  // all-day first, then by start. built once per load so a cell costs a lookup.
  property var byDay: ({})

  // the panel raises this while it is open. the file is re-read the moment
  // somebody is looking, the fetcher is run if what it holds is stale, and
  // neither happens while nobody is.
  property bool watching: false

  onWatchingChanged: {
    if (!root.watching) return

    // the read is synchronous (blockLoading), so the staleness test below sees
    // what the timer last wrote rather than what this shell last read.
    state.reload()

    if (root.ready && Date.now() - root.fetched.getTime() < Theme.calSyncStale) return

    poke.running = true
  }

  function key(day: date): string {
    return Qt.formatDate(day, "yyyy-MM-dd")
  }

  function eventsOn(day: date): var {
    return root.byDay[root.key(day)] ?? []
  }

  // whether the fetcher's window reaches the month holding this day.
  function inWindow(day: date): bool {
    if (!root.ready) return false

    const month = Qt.formatDate(day, "yyyy-MM")

    return month >= root.from.slice(0, 7) && month <= root.to.slice(0, 7)
  }

  function colorOf(calendar: string): color {
    return root.calendars[calendar]?.color ?? Theme.accent
  }

  // the calendars with something on a day, in legend order: one dot each.
  function calendarsOn(day: date): var {
    const events = root.eventsOn(day)

    return root.list.filter(cal => events.some(ev => ev.calendar === cal.id))
  }

  // a bare "2026-09-23" must not go through the Date constructor: that reads it
  // as utc midnight, which east of greenwich is still the day before.
  function localDate(iso: string): date {
    const [y, m, d] = iso.split("-").map(Number)

    return new Date(y, m - 1, d)
  }

  FileView {
    id: state

    path: root.file

    // not watchChanges: the fetcher replaces the file by rename, and the watch
    // follows the old inode -- proved by rewriting, deleting and recreating the
    // file under an open panel, none of which reloaded it. so the reads are
    // explicit: at startup, on every open, and after each run of the fetcher.
    blockLoading: true

    // a machine that has never synced has no file, and onLoadFailed already says
    // so once.
    printErrors: false

    onLoaded: {
      const data = JSON.parse(state.text() || "{}")

      const cals = {}
      for (const cal of data.calendars ?? []) cals[cal.id] = cal

      const days = {}
      // no ??= : qt's javascript stops at ??
      const add = (k, ev) => (days[k] = days[k] ?? []).push(ev)

      for (const ev of data.events ?? []) {
        if (!ev.allDay) {
          add(root.key(new Date(ev.start)), ev)
          continue
        }

        // google's all-day end is exclusive, so a one-day event ends tomorrow.
        const last = root.localDate(ev.end)
        for (let d = root.localDate(ev.start); d < last; d.setDate(d.getDate() + 1)) add(root.key(d), ev)
      }

      root.calendars = cals
      root.list = data.calendars ?? []
      root.byDay = days
      root.from = data.from ?? ""
      root.to = data.to ?? ""
      root.fetched = new Date(data.fetched ?? 0)
      root.ready = true

      console.info(`calendar: ${(data.events ?? []).length} events from ${Object.keys(cals).length} calendars, fetched ${data.fetched}`)
    }

    // a file that has gone is a file that has gone: keeping the last read would
    // have the panel say "no events" about days it no longer knows anything about.
    onLoadFailed: {
      root.ready = false
      root.byDay = ({})
      root.calendars = ({})
      root.list = []

      console.info(`calendar: nothing at ${root.file} yet`)
    }
  }

  // systemctl start on a oneshot returns when the run is over, so reloading on
  // exit reads what it just wrote -- whether or not the watch above noticed the
  // rename. the unit not existing yet is a non-zero exit and nothing else.
  Process {
    id: poke

    command: ["systemctl", "--user", "start", "kuori-calendar.service"]

    onExited: exitCode => {
      if (exitCode !== 0) console.warn(`calendar: kuori-calendar.service did not run, exit ${exitCode}`)

      state.reload()
    }
  }
}
