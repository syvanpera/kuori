pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
import qs.theme

// the display: what the monitor is, whether the night light is on and how warm,
// and whether the machine is being kept awake.
//
// hyprsunset owns the colour temperature. it runs as a user unit from login with
// -i, the identity matrix, so it is there to be talked to without having changed
// anything, and hyprctl is how it is talked to.
Singleton {
  id: root

  readonly property var monitor: Hyprland.focusedMonitor ?? Hyprland.monitors.values[0] ?? null

  // "2560×1600 · 240 Hz", the design's summary line. the refresh rate arrives as
  // 240.00301 and nobody wants to read that.
  readonly property string summary: {
    if (!root.monitor) return ""

    const hz = Math.round(root.monitor.lastIpcObject?.refreshRate ?? 0)

    return `${root.monitor.width}×${root.monitor.height}${hz > 0 ? ` · ${hz} Hz` : ""}`
  }

  property bool night: false
  property int temperature: Theme.dispTempDefault

  // the slider's side of the temperature: where it sits on the 2500K..6500K track.
  readonly property real temperatureFraction: (root.temperature - Theme.dispTempMin) / (Theme.dispTempMax - Theme.dispTempMin)

  // an idle inhibitor has to hang off a surface, so the flag lives here and
  // windows/FrameWindow.qml holds the inhibitor itself.
  property bool awake: false

  // who else is keeping it awake: applications that asked over d-bus, as
  // [{ app, reason }]. kuori-screensaver owns org.freedesktop.ScreenSaver for
  // them, since the idle timer only hears the wayland protocol and quickshell
  // cannot export the object those callers look for.
  property var heldBy: []

  // what the inhibitor follows and the toggles tab's glyph lights for. awake is
  // still only the switch: an application letting go must not leave it thrown.
  readonly property bool inhibited: root.awake || (Theme.appInhibit && root.heldBy.length > 0)

  // hyprsunset cannot be asked whether it is applying anything: after `identity`
  // it still reports the last temperature it was given. so this is the only record
  // of whether the night light is on, and it has to survive a restart of the shell
  // -- an orange screen with a switch that says Off would be worse than either.
  //
  // the idle inhibitor deliberately does not persist: it is invisible, and one
  // restored silently after a restart is a flat battery nobody can explain.
  FileView {
    id: state

    // not watched: this shell is the only writer, and a watch would answer its own
    // save by applying the same thing again.
    path: Quickshell.statePath("display.json")

    // a machine that has never touched these switches has no file, and saying so
    // at every startup is noise rather than news. onLoadFailed is the report.
    printErrors: false

    onLoaded: {
      // a hand-edited file that no longer parses is a machine with no saved
      // state, not a reason to skip applying the defaults.
      let saved = {}

      try {
        saved = JSON.parse(state.text() || "{}")
      } catch (e) {
        console.warn(`display: ignoring unreadable ${state.path}: ${e}`)
      }

      root.temperature = saved.temperature ?? Theme.dispTempDefault
      root.night = saved.night === true

      // whatever was saved is what the daemon should be doing, and at startup it
      // is doing neither.
      root.apply()
    }

    // a fresh machine has no file, which is not an error worth printing.
    onLoadFailed: root.apply()
  }

  function save(): void {
    state.setText(JSON.stringify({ night: root.night, temperature: root.temperature }))
  }

  // hyprctl rather than Hyprland.dispatch: hyprsunset listens on a socket of its
  // own, and a dispatcher would only be asking hyprland to run this same command.
  function apply(): void {
    Quickshell.execDetached(root.night
      ? ["hyprctl", "hyprsunset", "temperature", `${root.temperature}`]
      : ["hyprctl", "hyprsunset", "identity"])
  }

  function setNight(on: bool): void {
    root.night = on
    root.apply()
    root.save()
  }

  // a drag moves this every frame, so the daemon and the state file get the value
  // it settles on rather than every value it passed through: one process and one
  // write per drag instead of one of each per frame. the reading on screen still
  // follows the knob, because that reads the property and not the daemon.
  function setTemperature(kelvin: int): void {
    root.temperature = Math.round(Math.max(Theme.dispTempMin, Math.min(Theme.dispTempMax, kelvin)))

    settle.restart()
  }

  function setTemperatureFraction(fraction: real): void {
    root.setTemperature(Theme.dispTempMin + fraction * (Theme.dispTempMax - Theme.dispTempMin))
  }

  function setAwake(on: bool): void {
    root.awake = on
  }

  // runs whether or not Theme.appInhibit honours it, so a caller always gets an
  // answer rather than a failed call in the portal's log.
  Helper {
    script: "kuori-screensaver"
    name: "screensaver"

    onEvent: message => {
      if (message.type === "held") root.heldBy = message.by
    }

    // whatever it held went with it: a restarted helper starts with no cookies.
    onExited: root.heldBy = []
  }

  Timer {
    id: settle

    interval: Theme.dispSettle

    onTriggered: {
      if (root.night) root.apply()

      root.save()
    }
  }
}
