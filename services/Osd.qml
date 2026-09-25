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

  // which of the design's two displays is drawn: the box dropping out of the
  // system tab, or a tab of its own between the clock and the toggles.
  readonly property bool dropped: root.shown && Theme.osdStyle !== "notch"
  readonly property bool notched: root.shown && Theme.osdStyle === "notch"

  // what either of them says. they live here rather than in the box, so the two
  // styles cannot come to disagree about a muted glyph or a running clock.
  readonly property bool listening: root.voice && Voxtype.listening

  readonly property bool volume: !root.voice && root.kind === "volume"
  readonly property bool muted: root.volume && Audio.muted

  readonly property int value: {
    if (!root.volume) return Backlight.percent
    return root.muted ? 0 : Math.round(Audio.volume * 100)
  }

  // the glyph and the bar are the same colour, so a muted sound reads as one
  // statement rather than a grey icon over a blue bar. a listening microphone is
  // the recording dot's red, which is what the strip already says "recording" in.
  readonly property color fill: {
    if (root.listening) return Theme.osdFillListening
    return root.muted ? Theme.osdFillMuted : Theme.osdFill
  }

  readonly property string glyph: {
    if (root.voice) return "mic"
    if (!root.volume) return Backlight.levelGlyph(Backlight.level)

    // the real level and the mute flag rather than the zeroed reading above: the
    // shared ladder is the one that decides what muted looks like.
    return Audio.levelGlyph(Audio.volume, root.muted)
  }

  readonly property string title: {
    if (root.voice) return root.listening ? "Listening" : "Transcribing…"
    if (!root.volume) return "Brightness"
    return root.muted ? "Muted" : "Volume"
  }

  // a muted sound has no level to report, so it says so rather than printing the
  // nothing it is playing at.
  readonly property string reading: {
    if (root.voice) return root.elapsed
    return root.muted ? "—" : `${root.value}%`
  }

  // how long the recording has run, ticking while it does and stopping where it
  // stopped while it is transcribed. `now` only moves while there is a clock to
  // show, so a display for the volume keys wakes nothing.
  property real now: Date.now()

  readonly property int seconds: Math.max(0, Math.floor(((Voxtype.until || root.now) - Voxtype.since) / 1000))
  readonly property string elapsed: `${Math.floor(root.seconds / 60)}:${String(root.seconds % 60).padStart(2, "0")}`

  Timer {
    interval: Theme.osdVoiceTick
    repeat: true
    triggeredOnStart: true
    running: root.listening

    onTriggered: root.now = Date.now()
  }

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
