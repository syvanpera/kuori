import QtQuick
import qs.components
import qs.services
import qs.theme

// the system panel's display section: the two toggles that were a notch of their
// own until the design folded them in here, the brightness slider, and the colour
// temperature when there is one to set.
PanelRow {
  id: root

  icon: "monitor"
  label: "Display"
  value: Display.summary
  lit: true

  Column {
    width: root.bodyWidth
    spacing: Theme.sysBodyGap

    DisplayToggle {
      width: parent.width

      icon: "nightlight"
      label: "Night light"
      detail: Display.night ? `Warm ${Display.temperature}K` : "Off"
      checked: Display.night

      onToggled: Display.setNight(!Display.night)
    }

    DisplayToggle {
      width: parent.width

      icon: "coffee"
      label: "Stay awake"
      detail: Display.awake ? "Idle inhibited" : "Idle after 10 min"
      checked: Display.awake

      onToggled: Display.setAwake(!Display.awake)
    }

    Rectangle {
      width: parent.width
      height: 1
      color: Theme.sysLine
    }

    Caption {
      text: "BRIGHTNESS"
    }

    DisplaySlider {
      width: parent.width

      // a machine with no backlight gets no slider, the way the old row simply
      // did not appear.
      visible: Backlight.known
      icon: "light_mode"
      value: Backlight.level
      reading: `${Backlight.percent}%`

      onMoved: level => Backlight.set(level)
    }

    // the design only offers a temperature while there is one being applied.
    Caption {
      visible: Display.night

      text: "TEMPERATURE"
    }

    DisplaySlider {
      width: parent.width

      visible: Display.night
      icon: "nightlight"
      tint: Theme.elevated
      labelWidth: Theme.dispTempLabelWidth
      value: (Display.temperature - Theme.dispTempMin) / (Theme.dispTempMax - Theme.dispTempMin)
      reading: `${Display.temperature}K`

      onMoved: fraction => Display.setTemperature(Theme.dispTempMin + fraction * (Theme.dispTempMax - Theme.dispTempMin))
    }
  }
}
