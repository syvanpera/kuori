pragma Singleton
import QtQuick
import Quickshell

// one clock for the shell. the tab shows the time and the panel it opens onto
// shows the same time, the date and which day is today, and two SystemClocks
// ticking a second apart would eventually disagree about all three.
Singleton {
  id: root

  readonly property alias date: clock.date

  // "now", "4 min", "2 h", "3 d". it takes the clock as an argument so that a
  // binding on it re-runs this: a function call creates no dependency of its own,
  // which is the trap DesktopEntries already taught us.
  function ago(at: double, now: var): string {
    const seconds = Math.max(0, (now.getTime() - at) / 1000)

    if (seconds < 45) return "now"
    if (seconds < 5400) return `${Math.round(seconds / 60)} min`
    if (seconds < 86400) return `${Math.round(seconds / 3600)} h`

    return `${Math.round(seconds / 86400)} d`
  }

  // iso weeks belong to the year holding their thursday, which is the whole reason
  // this is not just "days since january the first over seven".
  function isoWeek(day: date): int {
    const d = new Date(day.getFullYear(), day.getMonth(), day.getDate())

    d.setDate(d.getDate() + 4 - ((d.getDay() + 6) % 7 + 1))

    const start = new Date(d.getFullYear(), 0, 1)

    return Math.ceil(((d - start) / 86400000 + 1) / 7)
  }

  // a month as the calendar draws it: one entry per week, its iso number and seven
  // day numbers, with nulls for the days that belong to the neighbouring months.
  function monthWeeks(year: int, month: int): var {
    // getDay() counts from sunday and the design's grid starts on monday.
    const lead = (new Date(year, month, 1).getDay() + 6) % 7

    // day zero of the next month is the last day of this one.
    const length = new Date(year, month + 1, 0).getDate()

    const days = []
    for (let i = 0; i < lead; i++) days.push(null)
    for (let day = 1; day <= length; day++) days.push(day)
    while (days.length % 7) days.push(null)

    const out = []
    for (let w = 0; w * 7 < days.length; w++) {
      const row = days.slice(w * 7, w * 7 + 7)
      const first = row.find(day => day !== null)

      out.push({ week: first ? root.isoWeek(new Date(year, month, first)) : 0, days: row })
    }

    return out
  }

  SystemClock {
    id: clock

    // nothing here shows seconds, and waking once a minute instead of once a
    // second is the difference between a shell that idles and one that does not.
    precision: SystemClock.Minutes
  }
}
