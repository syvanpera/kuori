import QtQuick
import qs.theme

// what the system tab becomes while it is open: a stack of rows, each one a
// thing the bar was only showing a glyph for.
Column {
  id: root

  // which row is folded open, "" for none. one place rather than a flag per row,
  // because opening one has to shut whichever was already out.
  property string open: ""

  // the design fixes the panel's width and everything inside divides it.
  readonly property real contentWidth: Theme.sysPanelWidth - Theme.sysPanelPadding * 2

  width: Theme.sysPanelWidth
  padding: Theme.sysPanelPadding
  spacing: Theme.sysSectionGap

  // the loader keeps this alive while the tab is shut, so closing is the only
  // moment there is to fold the rows back up.
  onEnabledChanged: if (!root.enabled) root.open = ""

  function toggle(id: string): void {
    root.open = root.open === id ? "" : id
  }

  Column {
    width: root.contentWidth
    spacing: Theme.sysRowSpacing

    NetworkRow {
      width: parent.width
      expanded: root.open === "wifi"

      onToggled: root.toggle("wifi")
    }

    BluetoothRow {
      width: parent.width
      expanded: root.open === "bluetooth"

      onToggled: root.toggle("bluetooth")
    }
  }
}
