import QtQuick
import Quickshell.Networking
import qs.services
import qs.theme
import qs.components

// the right tab: wifi, bluetooth, volume and battery, and a bell at the end when
// something has arrived that nobody has looked at.
Row {
  id: root

  readonly property var wifiDevice: Networking.devices.values.find(d => d.type === DeviceType.Wifi) ?? null
  readonly property var wifiNetwork: root.wifiDevice?.networks.values.find(n => n.connected) ?? null
  readonly property bool wifiUp: Networking.wifiEnabled && root.wifiNetwork !== null
  readonly property real signalStrength: root.wifiNetwork?.signalStrength ?? 0

  readonly property bool btEnabled: Bluez.enabled
  readonly property bool btConnected: Bluez.connected.length > 0

  readonly property bool sinkReady: Audio.sinkReady
  readonly property bool muted: Audio.muted
  readonly property int volume: Math.round(Audio.volume * 100)

  readonly property bool charging: Power.charging
  readonly property int level: Power.percent

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
      // the same ladder the panel's battery row draws from, so the strip and the
      // row can never disagree about what the battery looks like.
      icon: Power.glyph
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

  // and then whatever is switched on that the strip cannot otherwise show, in the
  // design's order. each of these is nothing at all until it has something to say.
  StripGlyph {
    shown: Display.night
    icon: "nightlight"
  }

  StripGlyph {
    shown: Display.awake
    icon: "coffee"
  }

  StripGlyph {
    shown: Notifications.dnd || Notifications.unread > 0
    icon: Notifications.dnd ? "notifications_off" : "notifications"
    iconColor: Notifications.dnd ? Theme.notifDim : Theme.accent
  }

  // not in the design, which gives a recording no indicator at all. a recording
  // you cannot see is one you forget you started, and this is a laptop.
  StripGlyph {
    shown: Capture.recording
    icon: "radio_button_checked"
    iconColor: Theme.urgent
  }
}
