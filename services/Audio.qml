pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Services.Pipewire
import qs.theme

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

  // pipewire keeps the default as a node *name*, and quickshell resolves it to the
  // first node answering to that name. a filter chain names its sink and the
  // stream it plays through alike -- the Framework Speakers convolver is
  // audio_effect.laptop-convolver on both sides -- and the stream is what came
  // back: a node at a fixed 1.00 that no volume key ever touches, while wpctl's
  // own @DEFAULT_AUDIO_SINK@ went to the sink. so a default that turns out to be a
  // stream is traded for the device of the same name.
  readonly property var sink: root.device(Pipewire.defaultAudioSink, true)
  readonly property var source: root.device(Pipewire.defaultAudioSource, false)

  readonly property bool sinkReady: root.sink?.ready ?? false
  readonly property bool sourceReady: root.source?.ready ?? false

  readonly property bool muted: root.sinkReady && root.sink.audio.muted

  // a sink that is muted and one that is not there yet say the same thing: no
  // sound is coming out. the strip, the panel row and its switch all ask this.
  readonly property bool silent: !root.sinkReady || root.muted
  readonly property real volume: root.sinkReady ? root.sink.audio.volume : 0
  readonly property real gain: root.sourceReady ? root.source.audio.volume : 0

  // what the microphone is hearing, 0 to 1. quickshell already takes the cube
  // root of the sample peak, so speech lands mid-bar without a curve of ours.
  // measuring opens a capture stream on the source, so it runs only while the
  // row is open, or while voxtype is listening and the osd shows what it hears,
  // and says nothing otherwise.
  readonly property bool metering: (root.detailed || Voxtype.listening) && root.sourceReady && Theme.micMeter
  readonly property real inputLevel: root.metering ? peaks.peak : 0

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

  function device(named: var, sink: bool): var {
    if (!named?.isStream) return named

    return Pipewire.nodes.values.find(node => !node.isStream && node.isSink === sink
      && (node.type & PwNodeType.Audio) && node.name === named.name) ?? named
  }

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

  // the one ladder for how loud a thing looks: the tab's strip, the panel's audio
  // row and the osd all ask this, so none of them can disagree with the other two.
  // the steps are the design's own, from the only place it writes them down -- its
  // osd -- including that a muted sink reads as off rather than as quiet, because
  // it zeroes the value before choosing a glyph.
  function levelGlyph(level: real, muted: bool): string {
    if (muted || level <= 0) return "volume_off"
    if (level < 0.34) return "volume_mute"
    if (level < 0.67) return "volume_down"

    return "volume_up"
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

  PwNodePeakMonitor {
    id: peaks

    node: root.source
    enabled: root.metering
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
