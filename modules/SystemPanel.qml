import QtQuick
import qs.services
import qs.theme

// what the system tab becomes while it is open: a stack of rows, each one a
// thing the bar was only showing a glyph for.
Column {
  id: root

  // the design fixes the panel's width and everything inside divides it.
  readonly property real contentWidth: Theme.sysPanelWidth - Theme.sysPanelPadding * 2

  width: Theme.sysPanelWidth
  padding: Theme.sysPanelPadding
  spacing: Theme.sysSectionGap

  // which row is folded open lives in Notches, not here: the strip above this
  // panel opens a row too, and it has to be able to say so before the loader has
  // built any of this. Notches clears it when the tab closes.
  Column {
    width: root.contentWidth
    spacing: Theme.sysRowSpacing

    NetworkRow {
      width: parent.width
      expanded: Notches.row === "wifi"

      onToggled: Notches.foldRow("wifi")
    }

    BluetoothRow {
      width: parent.width
      expanded: Notches.row === "bluetooth"

      onToggled: Notches.foldRow("bluetooth")
    }

    AudioRow {
      width: parent.width
      expanded: Notches.row === "audio"

      onToggled: Notches.foldRow("audio")
    }

    BatteryRow {
      width: parent.width
      expanded: Notches.row === "battery"

      onToggled: Notches.foldRow("battery")
    }

    DisplayRow {
      width: parent.width
      expanded: Notches.row === "display"

      onToggled: Notches.foldRow("display")
    }

    NotificationRow {
      width: parent.width
      expanded: Notches.row === "notifications"

      onToggled: Notches.foldRow("notifications")
    }
  }

  // ruled off from the rows above it, which is how the design separates the one
  // block in this panel that is not a row.
  Rectangle {
    width: root.contentWidth
    height: 1
    color: Theme.sysLine
  }

  CaptureSection {
    width: root.contentWidth
  }
}
