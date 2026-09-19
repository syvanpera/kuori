import QtQuick
import qs.components
import qs.services
import qs.theme

// the audio row: what sound is coming out of, how loud, and the same for what it
// is going into.
PanelRow {
  id: root

  icon: {
    if (!Audio.sinkReady || Audio.muted) return "volume_off"
    if (Audio.volume >= 0.5) return "volume_up"
    return "volume_down"
  }

  label: "Audio"
  lit: Audio.sinkReady && !Audio.muted
  value: Audio.summary

  // the device lists are only bound while the row is open.
  Binding {
    target: Audio
    property: "detailed"
    value: root.expanded
  }

  Item {
    width: root.bodyWidth
    height: Math.max(enabledLabel.implicitHeight, unmuted.height)

    Text {
      id: enabledLabel

      anchors.left: parent.left
      anchors.verticalCenter: parent.verticalCenter

      text: "ENABLED"
      color: Theme.sysCap
      font.family: Theme.monoFont
      font.pixelSize: Theme.sysCapSize
      font.weight: Font.Medium
      font.letterSpacing: Theme.sysCapSpacing
    }

    // the only thing here that can be switched off is the sound itself, so the
    // design's ENABLED is mute read the right way up.
    Switch {
      id: unmuted

      anchors.right: parent.right
      anchors.verticalCenter: parent.verticalCenter

      checked: Audio.sinkReady && !Audio.muted

      onToggled: Audio.setMuted(!Audio.muted)
    }
  }

  Text {
    text: "OUTPUT"
    color: Theme.sysCap
    font.family: Theme.monoFont
    font.pixelSize: Theme.sysCapSize
    font.weight: Font.Medium
    font.letterSpacing: Theme.sysCapSpacing
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

  Text {
    text: "INPUT"
    color: Theme.sysCap
    font.family: Theme.monoFont
    font.pixelSize: Theme.sysCapSize
    font.weight: Font.Medium
    font.letterSpacing: Theme.sysCapSpacing
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
