pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Services.Pipewire

// what is playing sound and what is listening, and how loud each of them is.
//
// the only importer of Quickshell.Services.Pipewire, for the same reason Bluez is
// the only importer of the bluetooth module: one place owns the object tracking,
// because a pipewire node stays unbound -- and its audio null -- until something
// asks for it, and two trackers on one node is two of everything for nothing.
Singleton {
  id: root

  // raised while the audio row is folded open. the device lists are only bound
  // then, so a shut panel tracks the two default nodes and nothing else.
  property bool detailed: false

  readonly property var sink: Pipewire.defaultAudioSink
  readonly property var source: Pipewire.defaultAudioSource

  readonly property bool sinkReady: root.sink?.ready ?? false
  readonly property bool sourceReady: root.source?.ready ?? false

  readonly property bool muted: root.sinkReady && root.sink.audio.muted
  readonly property real volume: root.sinkReady ? root.sink.audio.volume : 0
  readonly property real gain: root.sourceReady ? root.source.audio.volume : 0

  // what the collapsed row says on the right.
  readonly property string summary: root.label(root.sink) || "No output"

  // a stream is an application playing, not a device to choose between, and the
  // webcams on this machine arrive as nodes too.
  readonly property var sinks: Pipewire.nodes.values
    .filter(n => n.isSink && !n.isStream && (n.type & PwNodeType.Audio))
    .sort((a, b) => root.label(a).localeCompare(root.label(b)))

  readonly property var sources: Pipewire.nodes.values
    .filter(n => !n.isSink && !n.isStream && (n.type & PwNodeType.AudioSource) === PwNodeType.AudioSource)
    .sort((a, b) => root.label(a).localeCompare(root.label(b)))

  // the nick is what the design writes -- "ALC285 Analog" rather than "Built-in
  // Audio Analog Stereo" -- and not every node has one.
  function label(node: var): string {
    return node?.nickname || node?.description || node?.name || ""
  }

  function setMuted(on: bool): void {
    if (root.sinkReady) root.sink.audio.muted = on
  }

  function setVolume(node: var, level: real): void {
    if (node?.ready) node.audio.volume = Math.max(0, Math.min(1, level))
  }

  function selectSink(node: var): void {
    Pipewire.preferredDefaultAudioSink = node
  }

  function selectSource(node: var): void {
    Pipewire.preferredDefaultAudioSource = node
  }

  // pipewire carries the freedesktop icon name the device declared, the same
  // vocabulary bluez uses, plus a form factor when it has one.
  function glyph(node: var): string {
    const props = node?.properties ?? ({})
    const icon = props["device.icon-name"] ?? ""
    const form = props["device.form-factor"] ?? ""
    const name = node?.name ?? ""

    if (form === "headset" || form === "headphone") return "headphones"
    if (form === "webcam") return "photo_camera"
    if (form === "microphone") return "mic"

    if (icon.includes("headset") || icon.includes("headphone")) return "headphones"
    if (icon.includes("camera")) return "photo_camera"
    if (icon.includes("microphone")) return "mic"

    // hdmi and displayport outputs are the screen, which is how the design draws
    // them.
    if (name.includes("hdmi") || name.includes("displayport")) return "desktop_windows"

    return node?.isSink ? "speaker" : "mic"
  }

  // the two defaults are always bound: the tab's own strip reads the sink even
  // while every panel is shut. the rest join them only while the row is open.
  PwObjectTracker {
    objects: {
      const tracked = [root.sink, root.source]
      if (!root.detailed) return tracked

      return tracked.concat(root.sinks).concat(root.sources)
    }
  }
}
