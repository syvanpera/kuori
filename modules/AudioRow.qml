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

  // the heading stays with nothing listed under it: the level beneath it still
  // means something, and the design always draws both.
  DeviceSection {
    width: root.bodyWidth
    heading: "OUTPUT"
    ruled: false
    hideEmpty: false
    model: Audio.sinks

    delegate: AudioDevice {
      required property var modelData

      width: root.bodyWidth
      node: modelData
      current: modelData === Audio.sink

      onPicked: Audio.selectSink(modelData)
    }

    DisplaySlider {
      width: root.bodyWidth
      value: Audio.volume
      reading: `${Math.round(Audio.volume * 100)}%`

      onMoved: level => Audio.setVolume(Audio.sink, level)
    }
  }

  DeviceSection {
    width: root.bodyWidth
    heading: "INPUT"
    hideEmpty: false
    model: Audio.sources

    delegate: AudioDevice {
      required property var modelData

      width: root.bodyWidth
      node: modelData
      current: modelData === Audio.source

      onPicked: Audio.selectSource(modelData)
    }

    Column {
      width: root.bodyWidth
      spacing: Theme.micMeterTop

      DisplaySlider {
        id: gain

        width: root.bodyWidth
        value: Audio.gain
        reading: `${Math.round(Audio.gain * 100)}%`

        onMoved: level => Audio.setVolume(Audio.source, level)
      }

      // as wide as the track above it, the reading's column left empty.
      LevelMeter {
        width: root.bodyWidth - gain.labelWidth - Theme.sysSliderGap
        visible: Theme.micMeter
        running: Audio.metering
        level: Audio.inputLevel
      }
    }
  }
}
