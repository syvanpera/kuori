pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
import qs.services
import qs.theme

// screenshots and screen recordings.
//
// the screenshot half is grimblast, which already knows how to select a region,
// find the active window, copy and save at once, and where the file belongs -- it
// reads ~/.config/user-dirs.dirs itself, so a capture lands wherever every other
// tool on the machine would put it. its --notify goes through notify-send, which
// comes back to this shell's own notification server.
//
// the recording half is wf-recorder, which knows none of that and is told
// everything: the geometry, the output, the file and the audio device.
Singleton {
  id: root

  property string mode: "shot"
  property string target: "region"

  // the design's defaults: desktop sound on, microphone off.
  property bool sounds: true
  property bool mic: false

  readonly property bool recording: recorder.running

  // the button says "Captured!" for a moment after a shot, which is the only
  // feedback a screenshot gives from inside the panel.
  property bool flashing: false

  readonly property var targets: [
    { id: "region", label: "Region", shot: "area" },
    { id: "app", label: "App", shot: "active" },
    { id: "monitor", label: "Monitor", shot: "output" }
  ]

  readonly property string home: Quickshell.env("HOME") ?? ""

  // where recordings go. grimblast answers this question for itself; wf-recorder
  // has to be told, so the same file is read here.
  property string videos: `${root.home}/Videos`

  // the recording being written, so the notification afterwards can name it.
  property string file: ""

  function fire(): void {
    // stopping is immediate: there is nothing to get out of the way of.
    if (root.recording) {
      root.stop()
      return
    }

    // the panel is in the picture otherwise, and slurp cannot have the pointer
    // while the notch is holding a focus grab.
    Notches.close()
    settle.restart()
  }

  // what a keybind does: say what you want, then do it, rather than inheriting
  // whatever the panel was last left showing.
  function shortcut(mode: string, target: string): void {
    root.mode = mode
    root.target = target
    root.fire()
  }

  function stop(): void {
    // SIGINT, not kill: it is what makes wf-recorder finalise the file instead of
    // leaving an unplayable one.
    recorder.signal(2)
  }

  function flash(): void {
    root.flashing = true
    flasher.restart()
  }

  function shoot(): void {
    const how = root.targets.find(t => t.id === root.target)?.shot ?? "area"

    // no --notify: grimblast would announce itself as ".grimblast-wrapped", which
    // is the nix wrapper's filename. it prints the path it saved to instead, so
    // the notification below is ours and says kuori.
    shot.command = ["grimblast", "copysave", how]
    shot.running = true
  }

  // the monitor's name for a whole-screen recording, and its geometry for the
  // window one: wf-recorder takes hyprland's layout coordinates, which is the same
  // space `at` and `size` are already in.
  // Qt's formatter, not toISOString: that one is UTC, and a recording named three
  // hours before it happened is a file you cannot find again.
  function stamp(): string {
    return Qt.formatDateTime(new Date(), "yyyy-MM-dd_HH-mm-ss")
  }

  // a region has to be drawn before anything can be recorded, and slurp is a
  // process of its own: the recording starts in its onExited, not here.
  function record(): void {
    if (root.target === "region") {
      picker.running = true
      return
    }

    if (root.target === "app") {
      const window = Hyprland.activeToplevel?.lastIpcObject ?? null

      // hyprland reports a window in the same layout coordinates wf-recorder
      // takes, so this needs no conversion -- unlike anything measured in pixels.
      root.launch(window ? `${window.at[0]},${window.at[1]} ${window.size[0]}x${window.size[1]}` : "")
      return
    }

    root.launch("")
  }

  function launch(geometry: string): void {
    const file = `${root.videos}/recording-${root.stamp()}.mp4`
    const argv = ["wf-recorder", "-f", file]

    // software encoding, deliberately. the iris xe has a render node but no usable
    // VAAPI driver installed -- `-c h264_vaapi -d /dev/dri/renderD128` answers
    // "Failed to initialise VAAPI connection" and wf-recorder then **exits**
    // rather than falling back, so asking for hardware would mean no recording at
    // all. installing intel-media-driver is what would make the hardware path
    // available; until then libx264 is the one that works.

    if (geometry.length > 0) argv.push("-g", geometry)
    else if (root.target === "monitor") {
      const name = Hyprland.focusedMonitor?.name ?? ""

      if (name.length > 0) argv.push("-o", name)
    }

    const device = root.audioDevice()

    if (device.length > 0) argv.push(`--audio=${device}`)

    root.file = file
    recorder.command = argv
    recorder.running = true
  }

  // one device, because wf-recorder takes one. both switches together needs a
  // source that does not exist until something makes one; until that is built,
  // the desktop wins and the notification says so rather than silently dropping
  // half of what was asked for.
  function audioDevice(): string {
    if (root.sounds && root.mic) return `${Audio.sink?.name ?? ""}.monitor`
    if (root.sounds) return `${Audio.sink?.name ?? ""}.monitor`
    if (root.mic) return Audio.source?.name ?? ""

    return ""
  }

  // through notify-send rather than into the history directly: this shell is the
  // notification server, so the message comes back through the same door every
  // other application's does, and gets a toast and a history entry for free.
  //
  // an icon path is passed as the notification's image, which is how a screenshot
  // gets to be its own thumbnail.
  function notify(summary: string, body: string, image: string): void {
    const argv = ["notify-send", "-a", "kuori"]

    if (image.length > 0) argv.push("-i", image)

    announce.command = argv.concat([summary, body])
    announce.running = true
  }

  function shorten(path: string): string {
    return path.replace(root.home, "~")
  }

  Timer {
    id: settle

    interval: Theme.capSettle

    onTriggered: {
      if (root.mode === "rec") root.record()
      else root.shoot()
    }
  }

  Timer {
    id: flasher

    interval: Theme.capFlash

    onTriggered: root.flashing = false
  }

  // the recordings directory, from the same file grimblast reads. the line looks
  // like XDG_VIDEOS_DIR="$HOME/Videos", so the variable has to be expanded here.
  FileView {
    id: dirs

    path: `${Quickshell.env("XDG_CONFIG_HOME") ?? `${root.home}/.config`}/user-dirs.dirs`
    watchChanges: true
    printErrors: false

    onLoaded: {
      const match = /^XDG_VIDEOS_DIR="(.*)"$/m.exec(dirs.text())

      if (match) root.videos = match[1].replace("$HOME", root.home)
    }
  }

  Process {
    id: shot

    // the path it saved to, which is the last thing it prints.
    stdout: StdioCollector { id: saved }

    stderr: StdioCollector { id: complaint }

    onExited: exitCode => {
      // 1 is what a cancelled selection exits with, and cancelling is the ordinary
      // way out of slurp -- announcing it would be telling someone what they just
      // did on purpose. the reason is on stderr either way.
      if (exitCode === 1) {
        console.log(`capture: nothing saved -- ${complaint.text.trim()}`)
        return
      }

      // and 2 is the lock: a second capture while one is still selecting.
      if (exitCode === 2) {
        root.notify("Capture already running", "Finish or cancel the one in progress", "")
        return
      }

      if (exitCode !== 0) {
        root.notify("Screenshot failed", complaint.text.trim() || `grimblast exited ${exitCode}`, "")
        return
      }

      const file = saved.text.trim().split("\n").pop()

      root.flash()
      root.notify("Screenshot saved", root.shorten(file), file)
    }
  }

  Process {
    id: recorder

    onStarted: {
      const where = root.videos.replace(root.home, "~")

      root.notify("Recording", root.sounds && root.mic
        ? `Desktop audio only — the microphone is not mixed in yet. Saving to ${where}`
        : `Saving to ${where}`, "")
    }

    onExited: exitCode => {
      if (exitCode === 0) root.notify("Recording saved", root.shorten(root.file), "")
      else root.notify("Recording failed", `wf-recorder exited ${exitCode}`, "")
    }
  }

  // slurp writes "x,y WxH" on stdout, which is exactly what wf-recorder's -g
  // wants. a cancelled selection exits non-zero and records nothing.
  Process {
    id: picker

    command: ["slurp"]

    stdout: StdioCollector { id: region }

    onExited: exitCode => {
      if (exitCode !== 0) {
        console.log("capture: region selection cancelled")
        return
      }

      root.launch(region.text.trim())
    }
  }

  Process {
    id: announce
  }
}
