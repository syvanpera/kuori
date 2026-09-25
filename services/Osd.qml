pragma Singleton
import QtQuick
import Quickshell
import qs.theme

// what the on-screen display is showing, if anything. the volume and brightness
// keys are hyprland's binds and run wpctl and brightnessctl, so nothing tells this
// shell a key was pressed -- it watches the two values instead and shows whichever
// one moved. that also means the display answers a change made from anywhere: a
// terminal, another tool, the keys on the keyboard.
Singleton {
  id: root

  // "volume", "brightness", or "" for nothing on screen.
  property string kind: ""

  // voice typing, which is not a change that comes and goes but a state that
  // lasts: the box stays up for as long as voxtype is listening or transcribing,
  // with no hold, and wins over a volume or brightness change made meanwhile. it
  // stands aside for the system panel like the others, having the same corner.
  readonly property bool voice: Voxtype.active && Notches.open !== "system"

  readonly property bool shown: root.kind !== "" || root.voice

  // the value each service last reported. a service starts with nothing -- no sink
  // yet, no backlight probed yet -- and its first real reading is a change like any
  // other, which would throw the display up at login. -1 is "never seen one".
  property real lastVolume: -1
  property real lastBrightness: -1

  function show(what: string): void {
    // not while the system panel is open: the panel is showing these very sliders,
    // and a box over them says nothing the panel is not already saying.
    if (Notches.open === "system") return

    root.kind = what
    hold.restart()
  }

  // the panel opening while it is up takes it away for the same reason.
  onShownChanged: if (!root.shown) hold.stop()

  Connections {
    target: Notches

    function onOpenChanged(): void {
      if (Notches.open === "system") root.kind = ""
    }
  }

  Timer {
    id: hold

    interval: Theme.osdHold

    onTriggered: root.kind = ""
  }

  Connections {
    target: Audio

    function onVolumeChanged(): void {
      const level = Audio.volume

      if (root.lastVolume < 0) {
        root.lastVolume = level
        return
      }

      root.lastVolume = level
      root.show("volume")
    }

    // muting is a volume change as far as the display is concerned: same box, same
    // bar, and the bar reads zero.
    function onMutedChanged(): void {
      if (root.lastVolume < 0) return

      root.show("volume")
    }
  }

  Connections {
    target: Backlight

    function onPercentChanged(): void {
      const level = Backlight.percent

      if (root.lastBrightness < 0) {
        root.lastBrightness = level
        return
      }

      root.lastBrightness = level
      root.show("brightness")
    }
  }
}
