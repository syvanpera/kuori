import QtQuick
import qs.components
import qs.services
import qs.theme

// the toggles tab: three switches that are always on screen whichever way they are
// set, because a switch you cannot see is one you cannot throw. they carry no
// reading -- what they look like is the whole of what they say.
Row {
  id: root

  // the screen this strip is on, for the tips under its switches.
  property string screenName: ""

  spacing: Theme.togglesSpacing

  // gone while hyprsunset is not running: a switch that cannot warm the screen
  // is one that lies about it.
  StripButton {
    visible: Theme.shows(Display.available)
    screenName: root.screenName
    tip: Display.night ? "Night light on — click to turn off" : "Night light off — click to turn on"

    onClicked: Display.setNight(!Display.night)

    Glyph {
      icon: "nightlight"
      iconColor: Display.night ? Theme.accent : Theme.stripOff
      filled: true
    }
  }

  // lit while anything holds the screen awake, an application's own inhibit
  // included; the click still only throws the switch.
  StripButton {
    screenName: root.screenName
    tip: {
      if (Display.awake) return "Stay awake on — click to turn off"
      // the glyph is lit for an application's hold too, so the words have to say
      // whose it is, or a lit switch reads "off".
      if (Display.inhibited) return `Stay awake off — kept awake by ${Display.heldBy[0]?.app || "an application"}`
      return "Stay awake off — click to turn on"
    }

    onClicked: Display.setAwake(!Display.awake)

    Glyph {
      icon: "coffee"
      iconColor: Display.inhibited ? Theme.accent : Theme.stripOff
      filled: true
    }
  }

  // one glyph either way: do not disturb is a switch, not a report of what has
  // arrived. what has arrived is the bell in the system tab, which opens the
  // history rather than silencing it.
  StripButton {
    screenName: root.screenName
    tip: Notifications.dnd ? "Do not disturb on — click to turn off" : "Do not disturb off — click to turn on"

    onClicked: Notifications.toggleDnd()

    Glyph {
      icon: "do_not_disturb_on"
      iconColor: Notifications.dnd ? Theme.accent : Theme.stripOff
      filled: true
    }
  }
}
