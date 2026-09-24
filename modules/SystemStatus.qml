import QtQuick
import qs.components
import qs.services
import qs.theme

// the right tab: network, bluetooth, volume, notifications, display and battery. every one of
// them reports something and opens the section of the panel that is about it. the
// switches live in their own tab beside this one.
Row {
  id: root

  // the screen this strip is on. its icons open the panel here, not on whichever
  // monitor hyprland happens to think is focused.
  property string screenName: ""

  readonly property bool silent: Audio.silent

  readonly property bool charging: Power.charging
  readonly property int level: Power.percent

  // the section of the system panel this strip's icons open onto, if it is open.
  // an icon whose section is showing is accented and underlined, which is the only
  // thing on the strip that says what the panel below it is currently about.
  function showing(row: string): bool {
    return Notches.openOn(root.screenName) === "system" && Notches.row === row
  }

  spacing: Theme.systemSpacing

  StripButton {
    active: root.showing("wifi")

    onClicked: Notches.toggleRow("wifi", root.screenName)

    Glyph {
      icon: Network.linkGlyph
      // the design paints every glyph the same shade. dimming rather than
      // reddening is the smallest deviation that still makes a dead link legible.
      iconColor: {
        if (root.showing("wifi")) return Theme.accent
        return Network.online ? Theme.glyph : Theme.textDim
      }
    }
  }

  StripButton {
    active: root.showing("bluetooth")

    onClicked: Notches.toggleRow("bluetooth", root.screenName)

    Glyph {
      icon: Bluez.radioGlyph

      iconColor: {
        if (root.showing("bluetooth")) return Theme.accent
        return Bluez.enabled ? Theme.glyph : Theme.textDim
      }
    }
  }

  StripButton {
    active: root.showing("audio")

    onClicked: Notches.toggleRow("audio", root.screenName)

    Glyph {
      icon: Audio.levelGlyph(Audio.volume, root.silent)

      iconColor: {
        if (root.showing("audio")) return Theme.accent
        return root.silent ? Theme.textDim : Theme.glyph
      }
    }
  }

  // what has arrived, and a way into it. it is the only one of the six that says
  // something when its row is shut: accent while there is a history behind it, open
  // or not, which is the design's own "hot".
  StripButton {
    active: root.showing("notifications")

    onClicked: Notches.toggleRow("notifications", root.screenName)

    Glyph {
      icon: Notifications.history.length > 0 ? "notifications_active" : "notifications_none"
      iconColor: {
        if (root.showing("notifications") || Notifications.history.length > 0) return Theme.accent
        return Theme.glyph
      }
    }
  }

  // it reports nothing: a way into night light, stay awake and the sliders, which
  // the toggles tab beside this one only half covers.
  StripButton {
    active: root.showing("display")

    onClicked: Notches.toggleRow("display", root.screenName)

    Glyph {
      icon: "desktop_windows"
      iconColor: root.showing("display") ? Theme.accent : Theme.glyph
    }
  }

  // the glyph and the percentage are one target, the way the design has them.
  StripButton {
    active: root.showing("battery")

    onClicked: Notches.toggleRow("battery", root.screenName)

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
