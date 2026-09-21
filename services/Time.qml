pragma Singleton
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

  SystemClock {
    id: clock

    // nothing here shows seconds, and waking once a minute instead of once a
    // second is the difference between a shell that idles and one that does not.
    precision: SystemClock.Minutes
  }
}
