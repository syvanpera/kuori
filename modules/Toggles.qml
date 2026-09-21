import QtQuick
import qs.components
import qs.services
import qs.theme

// the toggles tab: three switches that are always on screen whichever way they are
// set, because a switch you cannot see is one you cannot throw. they carry no
// reading -- what they look like is the whole of what they say.
Row {
  id: root

  spacing: Theme.togglesSpacing

  StripButton {
    onClicked: Display.setNight(!Display.night)

    Glyph {
      icon: "nightlight"
      iconColor: Display.night ? Theme.accent : Theme.stripOff
      filled: true
    }
  }

  StripButton {
    onClicked: Display.setAwake(!Display.awake)

    Glyph {
      icon: "coffee"
      iconColor: Display.awake ? Theme.accent : Theme.stripOff
      filled: true
    }
  }

  // one glyph either way: do not disturb is a switch, not a report of what has
  // arrived. what has arrived is the bell in the system tab, which opens the
  // history rather than silencing it.
  StripButton {
    onClicked: Notifications.toggleDnd()

    Glyph {
      icon: "do_not_disturb_on"
      iconColor: Notifications.dnd ? Theme.accent : Theme.stripOff
      filled: true
    }
  }
}
