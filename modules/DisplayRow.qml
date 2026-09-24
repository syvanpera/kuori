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

  DisplayToggle {
    width: root.bodyWidth

    icon: "nightlight"
    label: "Night light"
    detail: Display.night ? `Warm ${Display.temperature}K` : "Off"
    checked: Display.night

    onToggled: Display.setNight(!Display.night)
  }

  DisplayToggle {
    width: root.bodyWidth

    icon: "coffee"
    label: "Stay awake"
    detail: Display.awake ? "Idle inhibited" : Display.inhibited ? `Held by ${Display.heldBy[0].app || "an application"}` : (Theme.lockIdle > 0 ? `Idle after ${Math.round(Theme.lockIdle / 60)} min` : "Never idles")
    checked: Display.awake

    onToggled: Display.setAwake(!Display.awake)
  }

  Rule {
    width: root.bodyWidth
  }

  Caption {
    text: "BRIGHTNESS"
  }

  DisplaySlider {
    width: root.bodyWidth

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
    width: root.bodyWidth

    visible: Display.night
    icon: "nightlight"
    tint: Theme.elevated
    labelWidth: Theme.dispTempLabelWidth
    value: Display.temperatureFraction
    reading: `${Display.temperature}K`

    onMoved: fraction => Display.setTemperatureFraction(fraction)
  }
}
