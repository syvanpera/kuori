pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

// the screen's backlight. quickshell has no module for it, so this is sysfs for
// reading and brightnessctl for writing.
//
// the sysfs file is root-owned and this user is not in the video group, so a
// direct write is not possible; brightnessctl gets there through logind's
// SetBrightness for the active session, which needs no privileges at all.
Singleton {
  id: root

  // raised while the system panel is open. the level is only polled then: nothing
  // reports a backlight change, so noticing the function keys means asking.
  property bool watching: false

  property string device: ""
  property real max: 0
  property real raw: 0

  readonly property bool known: root.max > 0
  readonly property real level: root.known ? root.raw / root.max : 0
  readonly property int percent: Math.round(root.level * 100)

  // the raw value waiting to be written, or -1 for none. a drag fires
  // continuously and every write is a process, so requests are coalesced: the
  // newest wins and only one brightnessctl runs at a time. brightnessctl returns
  // in a few milliseconds, so this throttles itself without a timer.
  property int requested: -1

  function set(level: real): void {
    if (!root.known) return

    const value = Math.round(Math.max(0, Math.min(1, level)) * root.max)

    // shown at once, so the slider follows the pointer rather than the disk.
    root.raw = value
    root.requested = value

    root.flush()
  }

  function flush(): void {
    if (root.requested < 0 || write.running) return

    write.command = ["brightnessctl", "-q", "set", `${root.requested}`]
    root.requested = -1
    write.running = true
  }

  onWatchingChanged: if (root.watching && root.device === "") probe.running = true

  // one brightnessctl to learn which device this is and how far it goes. after
  // that the level comes from sysfs, which costs nothing to read.
  Process {
    id: probe

    command: ["brightnessctl", "-m"]

    stdout: StdioCollector {
      id: probeOut

      onStreamFinished: {
        // "intel_backlight,backlight,78193,81%,96000"
        const fields = probeOut.text.trim().split("\n")[0]?.split(",") ?? []
        if (fields.length < 5) return

        root.device = fields[0]
        root.raw = parseFloat(fields[2]) || 0
        root.max = parseFloat(fields[4]) || 0
      }
    }
  }

  Process {
    id: write

    // whatever arrived while the last one was running goes next.
    onExited: root.flush()
  }

  Timer {
    interval: 2000
    repeat: true
    running: root.watching && root.device !== ""

    // not while a write is in flight: the file would answer with the value we
    // have already moved on from and the slider would jump back under the hand.
    onTriggered: if (!write.running && root.requested < 0) level.reload()
  }

  // the requested level rather than actual_brightness: it is what brightnessctl
  // writes, so the two never disagree by a rounding step.
  FileView {
    id: level

    path: root.device ? `/sys/class/backlight/${root.device}/brightness` : ""
    printErrors: false

    onLoaded: root.raw = parseFloat(level.text()) || 0
  }
}
