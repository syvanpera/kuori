import QtQuick
import Quickshell.Networking
import qs.services
import qs.theme
import qs.components

// the right tab: wifi, bluetooth, volume, notifications and battery. every one of
// them reports something and opens the section of the panel that is about it. the
// switches live in their own tab beside this one.
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

  // the section of the system panel this strip's icons open onto, if it is open.
  // an icon whose section is showing is accented and underlined, which is the only
  // thing on the strip that says what the panel below it is currently about.
  function showing(row: string): bool {
    return Notches.open === "system" && Notches.row === row
  }

  spacing: Theme.systemSpacing

  StripButton {
    active: root.showing("wifi")

    onClicked: Notches.toggleRow("wifi")

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
      iconColor: {
        if (root.showing("wifi")) return Theme.accent
        return root.wifiUp ? Theme.glyph : Theme.textDim
      }
    }
  }

  StripButton {
    active: root.showing("bluetooth")

    onClicked: Notches.toggleRow("bluetooth")

    Glyph {
      icon: {
        if (!root.btEnabled) return "bluetooth_disabled"
        if (root.btConnected) return "bluetooth_connected"
        return "bluetooth"
      }

      iconColor: {
        if (root.showing("bluetooth")) return Theme.accent
        return root.btEnabled ? Theme.glyph : Theme.textDim
      }
    }
  }

  StripButton {
    active: root.showing("audio")

    onClicked: Notches.toggleRow("audio")

    Glyph {
      icon: {
        if (!root.sinkReady) return "volume_off"
        if (root.muted) return "volume_mute"
        if (root.volume >= 50) return "volume_up"
        return "volume_down"
      }

      iconColor: {
        if (root.showing("audio")) return Theme.accent
        return !root.sinkReady || root.muted ? Theme.textDim : Theme.glyph
      }
    }
  }

  // what has arrived, and a way into it. it is the only one of the five that says
  // something when its row is shut: accent while there is a history behind it, open
  // or not, which is the design's own "hot".
  StripButton {
    active: root.showing("notifications")

    onClicked: Notches.toggleRow("notifications")

    Glyph {
      icon: Notifications.history.length > 0 ? "notifications_active" : "notifications_none"
      iconColor: {
        if (root.showing("notifications") || Notifications.history.length > 0) return Theme.accent
        return Theme.glyph
      }
    }
  }

  // the glyph and the percentage are one target, the way the design has them.
  StripButton {
    active: root.showing("battery")

    onClicked: Notches.toggleRow("battery")

    Row {
      spacing: Theme.batterySpacing

      Glyph {
        // the same ladder the panel's battery row draws from, so the strip and the
        // row can never disagree about what the battery looks like.
        icon: Power.glyph
        iconColor: {
          if (root.showing("battery")) return Theme.accent
          return !root.charging && root.level <= 15 ? Theme.urgent : Theme.glyph
        }
      }

      Text {
        // matched to the glyph box rather than to its own line height, because a
        // Row aligns its children on their tops and this text is the shorter one.
        height: Theme.iconSize
        verticalAlignment: Text.AlignVCenter

        text: `${root.level}%`
        color: root.showing("battery") ? Theme.accent : Theme.textDim
        font.family: Theme.monoFont
        font.pixelSize: Theme.labelSize
      }
    }
  }

  // not in the design, which gives a recording no indicator at all. a recording
  // you cannot see is one you forget you started, and this is a laptop.
  StripGlyph {
    shown: Capture.recording
    icon: "radio_button_checked"
    iconColor: Theme.urgent
  }
}
