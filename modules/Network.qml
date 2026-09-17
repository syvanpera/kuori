import QtQuick
import Quickshell.Networking
import qs.theme
import qs.components

Pill {
  id: root

  property var wifiDevice: Networking.devices.values.find(d => d.type === DeviceType.Wifi)
  property var active: wifiDevice ? wifiDevice.networks.values.find(n => n.connected) : null

  readonly property real signal: active ? active.signalStrength : 0

  icon: {
    if (!Networking.wifiEnabled) return "android_wifi_3_bar_off"
    if (!active) return "android_wifi_3_bar_off"
    if (signal >= 0.75)
      return "android_wifi_4_bar";
    if (signal >= 0.55)
      return "android_wifi_3_bar";
    if (signal >= 0.35)
      return "wifi_2_bar";
    if (signal >= 0.15)
      return "wifi_1_bar";
    return "android_wifi_0_bar";
  }

  iconColor: (!Networking.wifiEnabled || !active) ? Theme.red : Theme.green

  text: {
    if (!Networking.wifiEnabled) return "off"
    if (!root.active) return "disconnected"

    return root.active.name
  }
}
