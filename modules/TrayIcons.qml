import QtQuick
import Quickshell.Widgets
import qs.components
import qs.services
import qs.theme

// the tray tab's strip: one icon per application that put one in the tray. a left
// click is the application's own, the right click opens its menu out of the tab,
// the middle click is its secondary action and the wheel is passed on.
Row {
  id: root

  // the screen this strip is on, for its tips and for the menu to open there.
  property string screenName: ""

  spacing: Theme.traySpacing

  Repeater {
    model: Tray.items

    StripButton {
      id: button

      required property var modelData

      active: Tray.showing(button.modelData, root.screenName)
      screenName: root.screenName
      tip: button.modelData.tooltipTitle || button.modelData.title || button.modelData.id

      buttons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
      wheels: true

      onClicked: Tray.activate(button.modelData, root.screenName)

      onOtherClicked: which => {
        if (which === Qt.RightButton) Tray.toggleMenu(button.modelData, root.screenName)
        else button.modelData.secondaryActivate()
      }

      onScrolled: (delta, horizontal) => button.modelData.scroll(delta, horizontal)

      // an IconImage rather than an Image: it sets both sides of the source size,
      // and an image://icon source given only a height decodes at 2x2.
      IconImage {
        implicitSize: Theme.trayIconSize
        source: button.modelData.icon
        asynchronous: true
      }
    }
  }
}
