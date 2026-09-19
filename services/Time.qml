pragma Singleton
import Quickshell

// one clock for the shell. the tab shows the time and the panel it opens onto
// shows the same time, the date and which day is today, and two SystemClocks
// ticking a second apart would eventually disagree about all three.
Singleton {
  id: root

  readonly property alias date: clock.date

  SystemClock {
    id: clock

    // nothing here shows seconds, and waking once a minute instead of once a
    // second is the difference between a shell that idles and one that does not.
    precision: SystemClock.Minutes
  }
}
