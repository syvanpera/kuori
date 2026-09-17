import QtQuick
import Quickshell.Services.UPower
import qs.theme
import qs.components

Pill {
  id: root

  readonly property var battery: UPower.displayDevice
  readonly property bool charging: battery.state === UPowerDeviceState.Charging
  readonly property int level: Math.round(battery.percentage * 100)

  icon: {
    if (charging) {
      if (level >= 95) return "battery_charging_full_2"
      if (level >= 90) return "battery_charging_90_2"
      if (level >= 80) return "battery_charging_80_2"
      if (level >= 60) return "battery_charging_60_2"
      if (level >= 50) return "battery_charging_50_2"
      if (level >= 30) return "battery_charging_30_2"
      return "battery_charging_20_2"
    }

    if (level >= 95) return "battery_android_frame_full"
    if (level >= 90) return "battery_android_frame_6"
    if (level >= 80) return "battery_android_frame_5"
    if (level >= 60) return "battery_android_frame_4"
    if (level >= 50) return "battery_android_frame_3"
    if (level >= 30) return "battery_android_frame_2"
    return "battery_android_frame_alert"
  }

  iconColor: charging ? Theme.green : level <= 15 ? Theme.red : level <= 30 ? Theme.orange : Theme.green

  text: `${root.level}%`
}
