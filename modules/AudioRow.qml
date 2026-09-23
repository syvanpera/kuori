import QtQuick
import qs.components
import qs.services
import qs.theme

// the audio row: what sound is coming out of, how loud, and the same for what it
// is going into.
PanelRow {
  id: root

  icon: Audio.levelGlyph(Audio.volume, Audio.silent)

  label: "Audio"
  lit: !Audio.silent
  value: Audio.summary

  // the device lists are only bound while the row is open.
  Binding {
    target: Audio
    property: "detailed"
    value: root.expanded
  }

  // the only thing here that can be switched off is the sound itself, so the
  // design's ENABLED is mute read the right way up.
  SectionSwitch {
    width: root.bodyWidth
    checked: !Audio.silent

    onToggled: Audio.setMuted(!Audio.muted)
  }

  Caption {
    text: "OUTPUT"
  }

  VolumeSlider {
    width: root.bodyWidth
    value: Audio.volume

    onMoved: level => Audio.setVolume(Audio.sink, level)
  }

  Column {
    width: root.bodyWidth
    spacing: Theme.sysNetSpacing

    Repeater {
      model: Audio.sinks

      AudioDevice {
        required property var modelData

        node: modelData
        current: modelData === Audio.sink

        onPicked: Audio.selectSink(modelData)
      }
    }
  }

  Rectangle {
    width: root.bodyWidth
    height: 1
    color: Theme.sysLine
  }

  Caption {
    text: "INPUT"
  }

  VolumeSlider {
    width: root.bodyWidth
    value: Audio.gain

    onMoved: level => Audio.setVolume(Audio.source, level)
  }

  Column {
    width: root.bodyWidth
    spacing: Theme.sysNetSpacing

    Repeater {
      model: Audio.sources

      AudioDevice {
        required property var modelData

        node: modelData
        current: modelData === Audio.source

        onPicked: Audio.selectSource(modelData)
      }
    }
  }
}
