import QtQuick
import qs.components
import qs.services
import qs.theme

// what the system tab becomes while it is open: a stack of rows, each one a
// thing the bar was only showing a glyph for.
Column {
  id: root

  // the design fixes the panel's width and everything inside divides it.
  readonly property real contentWidth: Theme.sysPanelWidth - Theme.sysPanelPadding * 2

  // what the arrow keys are on: a row's header, a switch, or an entry in the row
  // that is out. null until the first arrow, so opening the panel shows nothing
  // lit that nobody asked for.
  property Item cursor: null

  // the one item wearing the wash, kept rather than found again: the cursor can
  // be in a row that has since folded shut, where a walk of the targets would not
  // reach it to put its wash out.
  property Item lit: null

  // every item the cursor can land on, in reading order: each row's header, and
  // the switches and entries of the one row that is out. walked afresh on every
  // key rather than kept, because the lists under it change on their own -- a scan
  // finds an access point, a device connects -- and a kept list would go stale.
  //
  // a Column stacks its children in the order they are listed, and a Repeater
  // inserts what it makes at its own place in that list, so children order is the
  // order they are drawn in.
  function targets(): var {
    const found = []

    const walk = item => {
      for (const child of item.children) {
        if (!child.visible) continue

        if (child.keyTarget === true) found.push(child)
        if (child.keyChildren === false) continue

        walk(child)
      }
    }

    walk(root)

    return found
  }

  // one step through the targets, wrapping at both ends like the launcher's list.
  // the first press starts from the row that is out, so a panel opened onto audio
  // goes straight into audio rather than back up to the network row.
  function step(delta: int): void {
    const list = root.targets()
    if (list.length === 0) return

    let at = list.indexOf(root.cursor)

    if (at < 0) {
      at = list.findIndex(item => item.keyChildren === true)
      if (at < 0) at = delta > 0 ? -1 : list.length
    }

    root.cursor = list[(at + delta + list.length) % list.length]
  }

  // return: whatever a click on the cursor would do.
  function press(): void {
    root.cursor?.press()
  }

  onCursorChanged: {
    if (root.lit) root.lit.keyed = false

    root.lit = root.cursor

    if (root.cursor) root.cursor.keyed = true
  }

  width: Theme.sysPanelWidth
  padding: Theme.sysPanelPadding
  spacing: Theme.sysSectionGap

  // the panel is kept loaded while the tab is shut, so the cursor is put away by
  // hand: reopened, the panel starts with nothing lit.
  Connections {
    target: Notches

    function onOpenChanged(): void {
      if (Notches.open !== "system") root.cursor = null
    }
  }

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
  Rule {
    width: root.contentWidth
  }

  CaptureSection {
    width: root.contentWidth
  }
}
