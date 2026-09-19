import QtQuick
import Quickshell.Bluetooth
import Quickshell.Networking
import Quickshell.Services.Pipewire
import Quickshell.Services.UPower
import qs.theme
import qs.components

// the right tab: wifi, bluetooth, volume, battery and the do-not-disturb lamp.
Row {
  id: root

  readonly property var wifiDevice: Networking.devices.values.find(d => d.type === DeviceType.Wifi) ?? null
  readonly property var wifiNetwork: root.wifiDevice?.networks.values.find(n => n.connected) ?? null
  readonly property bool wifiUp: Networking.wifiEnabled && root.wifiNetwork !== null
  readonly property real signalStrength: root.wifiNetwork?.signalStrength ?? 0

  readonly property var btAdapter: Bluetooth.defaultAdapter
  readonly property bool btEnabled: root.btAdapter?.enabled ?? false
  readonly property bool btConnected: root.btEnabled && Bluetooth.devices.values.some(d => d.connected)

  readonly property var sink: Pipewire.defaultAudioSink
  readonly property bool sinkReady: root.sink?.ready ?? false
  readonly property bool muted: root.sinkReady && root.sink.audio.muted
  readonly property int volume: root.sinkReady ? Math.round(root.sink.audio.volume * 100) : 0

  readonly property var battery: UPower.displayDevice
  readonly property bool charging: root.battery?.state === UPowerDeviceState.Charging
  readonly property int level: Math.round((root.battery?.percentage ?? 0) * 100)

  spacing: Theme.systemSpacing

  Glyph {
    // a threshold table beats an if-ladder here: each floor stays on the same
    // line as the glyph it picks, and choosing one is a single find().
    readonly property var ladder: [
      { floor: 0.75, icon: "android_wifi_4_bar" },
      { floor: 0.55, icon: "android_wifi_3_bar" },
      { floor: 0.35, icon: "network_wifi_2_bar" },
      { floor: 0.00, icon: "network_wifi_1_bar" }
    ]

    icon: root.wifiUp ? ladder.find(step => root.signalStrength >= step.floor).icon : "android_wifi_3_bar_off"
    // the design paints every glyph the same shade. dimming rather than
    // reddening is the smallest deviation that still makes a dead radio legible.
    iconColor: root.wifiUp ? Theme.glyph : Theme.textDim
  }

  Glyph {
    icon: {
      if (!root.btEnabled) return "bluetooth_disabled"
      if (root.btConnected) return "bluetooth_connected"
      return "bluetooth"
    }

    iconColor: root.btEnabled ? Theme.glyph : Theme.textDim
  }

  Glyph {
    icon: {
      if (!root.sinkReady) return "volume_off"
      if (root.muted) return "volume_mute"
      if (root.volume >= 50) return "volume_up"
      return "volume_down"
    }

    iconColor: !root.sinkReady || root.muted ? Theme.textDim : Theme.glyph
  }

  Row {
    spacing: Theme.batterySpacing

    Glyph {
      // battery_charging_90_2 does not exist in the installed font and rendered
      // as literal text in the old bar; battery_charging_90 is the real name.
      readonly property var ladder: root.charging
        ? [
          { floor: 95, icon: "battery_charging_full_2" },
          { floor: 80, icon: "battery_charging_90" },
          { floor: 60, icon: "battery_charging_80_2" },
          { floor: 50, icon: "battery_charging_60_2" },
          { floor: 40, icon: "battery_charging_50_2" },
          { floor: 20, icon: "battery_charging_30_2" },
          { floor: 0, icon: "battery_charging_20_2" }
        ]
        : [
          { floor: 95, icon: "battery_android_frame_full" },
          { floor: 80, icon: "battery_android_frame_6" },
          { floor: 60, icon: "battery_android_frame_5" },
          { floor: 50, icon: "battery_android_frame_4" },
          { floor: 40, icon: "battery_android_frame_3" },
          { floor: 10, icon: "battery_android_frame_2" },
          { floor: 0, icon: "battery_android_frame_alert" }
        ]

      icon: ladder.find(step => root.level >= step.floor).icon
      iconColor: !root.charging && root.level <= 15 ? Theme.urgent : Theme.glyph
    }

    Text {
      // matched to the glyph box rather than to its own line height, because a
      // Row aligns its children on their tops and this text is the shorter one.
      height: Theme.iconSize
      verticalAlignment: Text.AlignVCenter

      text: `${root.level}%`
      color: Theme.textDim
      font.family: Theme.monoFont
      font.pixelSize: Theme.labelSize
    }
  }

  Glyph {
    icon: "bedtime"
    iconColor: Theme.warm
    filled: true
  }

  // pipewire objects stay unbound until something asks for them, so without this
  // the sink never becomes ready and audio is null.
  PwObjectTracker {
    objects: [root.sink]
  }
}
