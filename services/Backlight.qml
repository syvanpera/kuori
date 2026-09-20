pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

// the screen's backlight. quickshell has no module for it, so this is sysfs both
// ways: acpilight's udev rule gives the brightness file to the video group and
// this user is in it, so the shell writes the file itself and needs no helper.
//
// it went through brightnessctl and logind before that, which cost a process per
// step of a drag and all the machinery to keep those from piling up. one line of
// nix took the lot away.
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

  function set(level: real): void {
    if (!root.known) return

    const value = Math.round(Math.max(0, Math.min(1, level)) * root.max)

    // shown before it is written, so the slider follows the pointer rather than
    // the disk -- though with a blocking write of five bytes there is not much in
    // it either way.
    root.raw = value
    brightness.setText(`${value}`)
  }

  // brightnessctl only to find out which backlight this is and how far it goes:
  // the file has to be named before it can be read, and nothing in Quickshell.Io
  // lists a directory. it is not in the way of a single write.
  onWatchingChanged: if (root.watching && root.device === "") probe.running = true

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

  Timer {
    interval: 2000
    repeat: true
    running: root.watching && root.device !== ""

    onTriggered: brightness.reload()
  }

  FileView {
    id: brightness

    path: root.device ? `/sys/class/backlight/${root.device}/brightness` : ""

    // an atomic write is a write to a temporary followed by a rename, and you
    // cannot rename anything over a sysfs attribute. it has to go in place.
    atomicWrites: false

    // five bytes to a kernel attribute, so blocking costs nothing and the write
    // has landed before the poll below could ask about it.
    blockWrites: true

    onLoaded: root.raw = parseFloat(brightness.text()) || 0
  }
}
