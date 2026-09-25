pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import Qt.labs.folderlistmodel

// voice typing: what the voxtype daemon is doing, for the osd. the daemon is the
// machine's, not this shell's -- it types into whatever has focus with or without
// kuori -- so nothing here starts, stops or configures it. it only reads.
//
// voxtype writes one word to $XDG_RUNTIME_DIR/voxtype/state on every transition:
// idle, recording, streaming or transcribing. it writes it in place, so a watch
// on the file sees each one; but it deletes the file when the daemon stops and
// writes a new one when it starts, and a watch on a deleted file hears nothing
// again. the directory listing below is what notices the new one.
Singleton {
  id: root

  readonly property string dir: `${Quickshell.env("XDG_RUNTIME_DIR")}/voxtype`

  // what the daemon last wrote. "idle" with no daemon too: nothing is being
  // heard either way.
  property string heard: "idle"

  // what the ipc's mocks put in its place, "" for none.
  property string mock: ""

  readonly property string state: root.mock !== "" ? root.mock : root.heard

  // hearing speech: a push-to-talk hold, or a streaming session typing as it goes.
  readonly property bool listening: root.state === "recording" || root.state === "streaming"
  readonly property bool transcribing: root.state === "transcribing"

  // `voxtype record start --no-osd` asks every osd to stay out of the way of that
  // one recording. the daemon says so with a marker file beside the state.
  readonly property bool suppressed: marker.count > 0

  readonly property bool active: (root.listening || root.transcribing) && !root.suppressed

  // when the recording began and ended, for the running time on the osd, which
  // stops where the recording did and stays there while it is transcribed.
  property real since: 0
  property real until: 0

  onListeningChanged: {
    if (root.listening) {
      root.since = Date.now()
      root.until = 0
    } else {
      root.until = Date.now()
    }
  }

  FileView {
    id: file

    path: `${root.dir}/state`
    watchChanges: true
    printErrors: false

    onLoaded: root.heard = file.text().trim() || "idle"
    onLoadFailed: root.heard = "idle"
    onFileChanged: file.reload()
  }

  // qt watches the directory, so neither of these costs a process or a poll.
  FolderListModel {
    folder: `file://${root.dir}`
    nameFilters: ["state"]
    showDirs: false

    onCountChanged: file.reload()
  }

  FolderListModel {
    id: marker

    folder: `file://${root.dir}`
    nameFilters: ["osd_suppressed"]
    showDirs: false
  }

  // every state the osd can show without a microphone: listening, transcribing,
  // or idle to hand it back to the daemon.
  IpcHandler {
    target: "voxtype"

    function mock(state: string): void {
      root.mock = state === "listening" ? "recording" : state === "idle" ? "" : state
    }
  }
}
