import QtQuick
import Quickshell.Services.Pipewire
import qs.theme
import qs.components

Pill {
  id: root

  property var sink: Pipewire.defaultAudioSink
  readonly property bool ready: sink && sink.ready
  readonly property bool muted: ready && sink.audio.muted
  readonly property int level: ready ? Math.round(sink.audio.volume * 100) : 0

  icon: {
    if (!ready) return "volume_off"
    if (muted) return "volume_mute"
    if (level >= 50) return "volume_up"
    return "volume_down"
  }

  iconColor: (!ready || muted) ? Theme.red : Theme.blue

  text: `${root.level}%`

  // Pipewire objects stay unbound until something asks for them, so without
  // this the sink never becomes ready and audio is null.
  PwObjectTracker {
    objects: [root.sink]
  }
}
