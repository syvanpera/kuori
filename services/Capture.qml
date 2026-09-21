pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
import Qt.labs.folderlistmodel
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

  // the design's only recording option, off by default. desktop sound was a
  // second switch until the design dropped it: wf-recorder takes one audio device
  // and mixing two needs a virtual source nothing here builds.
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

  readonly property string renderNode: "/dev/dri/renderD128"

  // listing one directory rather than running a process, and it answers the only
  // question worth asking: not whether the package is installed, but whether libva
  // can find a driver where it looks.
  readonly property bool accelerated: drivers.count > 0

  // where recordings go. grimblast answers this question for itself; wf-recorder
  // has to be told, so the same file is read here.
  property string videos: `${root.home}/Videos`

  // and where screenshots go, for the one target that does not go through
  // grimblast. the same order it uses: the screenshots directory, then pictures.
  property string shots: `${root.home}/Pictures`

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

  // every monitor as a box slurp can be pointed at, in layout coordinates: the
  // geometry hyprland reports is physical pixels and slurp works in logical ones.
  function monitorRects(): string {
    return Hyprland.monitors.values
      .map(m => `${m.x},${m.y} ${Math.round(m.width / m.scale)}x${Math.round(m.height / m.scale)}`)
      .join("\n")
  }

  readonly property bool manyMonitors: Hyprland.monitors.values.length > 1

  function shoot(): void {
    // a free-form drag cannot go through grimblast, which always passes slurp -o
    // -- "select a display output". with boxes to choose from that is harmless,
    // but with none the whole output becomes the selection the moment the pointer
    // moves, and slurp draws a selection by *not* dimming it: the veil vanishes
    // and you are dragging blind. so region runs slurp itself, without -o.
    if (root.target === "region") {
      regionPicker.running = true
      return
    }

    // the others keep grimblast, which takes SLURP_RECTS and SLURP_ARGS from the
    // environment for exactly this:
    //
    //   app      grimblast's own boxes, every window, restricted to them
    //   monitor  one box per monitor -- or no picker at all when there is one,
    //            because asking which is silly when there is no choice
    shot.file = ""
    shot.environment = root.target === "app"
      ? ({ SLURP_ARGS: "-r" })
      : ({ SLURP_RECTS: root.monitorRects(), SLURP_ARGS: "-r" })

    // no --notify: grimblast would announce itself as ".grimblast-wrapped", which
    // is the nix wrapper's filename. it prints the path it saved to instead, so
    // the notification below is ours and says kuori.
    shot.command = ["grimblast", "copysave",
      root.target === "monitor" && !root.manyMonitors ? "output" : "area"]
    shot.running = true
  }

  // saved and copied in one pass: tee writes the file and hands the same bytes to
  // wl-copy, so the two cannot disagree about what was captured. grimblast's own
  // naming, so a screenshot taken this way sits beside the others.
  function grabRegion(geometry: string): void {
    const file = `${root.shots}/${Qt.formatDateTime(new Date(), "yyyyMMdd_HHmmss")}.png`

    shot.file = file
    shot.environment = ({})

    shot.command = ["sh", "-c",
      `mkdir -p '${root.shots}' && grim -g '${geometry}' - | tee '${file}' | wl-copy --type image/png`]
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

  // wf-recorder knows nothing about windows or pickers, so the geometry is drawn
  // first and the recording starts in the picker's onExited. the targets mean the
  // same here as they do for a screenshot: region drags, app and monitor pick.
  function record(): void {
    if (root.target === "monitor" && !root.manyMonitors) {
      root.launch("")
      return
    }

    // one box per window, from hyprland, which reports them in the layout
    // coordinates both slurp and wf-recorder speak.
    const rects = root.target === "app"
      ? Hyprland.toplevels.values
        .map(t => t.lastIpcObject)
        .filter(w => w)
        .map(w => `${w.at[0]},${w.at[1]} ${w.size[0]}x${w.size[1]}`)
        .join("\n")
      : root.monitorRects()

    // a shell because the boxes reach slurp on its stdin, and free-form region
    // selection is the one case with no boxes to give it.
    // both go through a shell, and for the same reason: slurp blocks forever on a
    // stdin that is an open pipe (see regionPicker below).
    picker.command = root.target === "region"
      ? ["sh", "-c", "exec slurp < /dev/null"]
      : ["sh", "-c", `printf '%s' '${rects}' | slurp -r -f '%x,%y %wx%h'`]

    picker.running = true
  }

  function launch(geometry: string): void {
    const file = `${root.videos}/recording-${root.stamp()}.mp4`
    const argv = ["wf-recorder", "-f", file]

    // hardware encoding only when libva can actually load a driver. wf-recorder
    // asks for h264_vaapi and **exits** if the connection fails rather than
    // falling back, so asking blindly is the difference between a recording and
    // none at all -- and a driver that is merely installed is not enough, it has
    // to be in /run/opengl-driver/lib/dri, which is what `accelerated` looks for.
    if (root.accelerated) argv.push("-c", "h264_vaapi", "-d", root.renderNode)

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

  function audioDevice(): string {
    return root.mic ? (Audio.source?.name ?? "") : ""
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

  FolderListModel {
    id: drivers

    folder: "file:///run/opengl-driver/lib/dri"
    nameFilters: ["iHD_drv_video.so", "i965_drv_video.so"]
    showDirs: false
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
      const text = dirs.text()
      const videos = /^XDG_VIDEOS_DIR="(.*)"$/m.exec(text)
      const shots = /^XDG_SCREENSHOTS_DIR="(.*)"$/m.exec(text) ?? /^XDG_PICTURES_DIR="(.*)"$/m.exec(text)

      if (videos) root.videos = videos[1].replace("$HOME", root.home)
      if (shots) root.shots = shots[1].replace("$HOME", root.home)
    }
  }

  // plain slurp, and the one place -o must not appear.
  Process {
    id: regionPicker

    // `slurp < /dev/null`, and the redirect is the whole point: slurp reads its
    // list of selectable boxes from stdin, and Process hands it a pipe that is
    // never written to and never closed, so it blocks in read() forever. The
    // process runs, maps no surface, dims nothing, and the screen looks untouched
    // while a capture is supposedly in progress. `stdinEnabled: false` does not
    // help -- the pipe is still there. Every other caller here reaches slurp
    // through a shell pipeline, which closes stdin for them, which is why this
    // only appeared when region stopped going through grimblast.
    command: ["sh", "-c", "exec slurp < /dev/null"]

    stdout: StdioCollector { id: regionGeometry }
    stderr: StdioCollector { id: regionError }

    onExited: exitCode => {
      if (exitCode !== 0) {
        console.log(`capture: region selection cancelled, exit ${exitCode}, stderr: [${regionError.text.trim()}]`)
        return
      }

      root.grabRegion(regionGeometry.text.trim())
    }
  }

  Process {
    id: shot

    // set when this shell built the file's name itself, empty when grimblast did
    // and printed it instead.
    property string file: ""

    // the path grimblast saved to, which is the last thing it prints.
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

      const file = shot.file.length > 0 ? shot.file : saved.text.trim().split("\n").pop()

      root.flash()
      root.notify("Screenshot saved", root.shorten(file), file)
    }
  }

  Process {
    id: recorder

    onStarted: root.notify("Recording", `${root.accelerated ? "Hardware encoding" : "Software encoding"} · ${root.shorten(root.file)}`, "")

    onExited: exitCode => {
      if (exitCode === 0) root.notify("Recording saved", root.shorten(root.file), "")
      else root.notify("Recording failed", `wf-recorder exited ${exitCode}`, "")
    }
  }

  // slurp writes "x,y WxH" on stdout, which is exactly what wf-recorder's -g
  // wants. a cancelled selection exits non-zero and records nothing.
  Process {
    id: picker

    stdout: StdioCollector { id: region }

    onExited: exitCode => {
      if (exitCode !== 0) {
        console.log("capture: selection cancelled")
        return
      }

      root.launch(region.text.trim())
    }
  }

  Process {
    id: announce
  }
}
