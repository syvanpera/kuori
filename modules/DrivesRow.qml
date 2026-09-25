import QtQuick
import Quickshell
import qs.components
import qs.services
import qs.theme

// the drives row: there only while something is plugged in, one card per drive.
PanelRow {
  id: root

  icon: "usb"
  label: "Drives"

  // the design paints this one accent whatever the drives are doing, as it does
  // the battery.
  lit: true
  value: Drives.summary

  visible: Drives.rows.length > 0

  // a locked drive's passphrase is what the row is for, so it takes the keyboard
  // as the row folds out.
  onExpandedChanged: {
    if (!root.expanded) return

    for (let i = 0; i < cards.count; i++) {
      const card = cards.itemAt(i)
      if (card?.locked) {
        card.takeFocus()
        return
      }
    }
  }

  Binding {
    target: Drives
    property: "detailed"
    value: root.expanded
  }

  Caption {
    text: "CONNECTED"
  }

  Column {
    width: root.bodyWidth
    spacing: Theme.drvListGap

    // ids rather than the rows themselves: a row is rebuilt on every listing, and
    // a delegate made per row object would be torn down with it, passphrase and
    // all. an id is the same string every time, so the card lives as long as the
    // drive does.
    Repeater {
      id: cards

      model: ScriptModel {
        values: Drives.rows.map(row => row.id)
      }

      DriveEntry {
        id: card

        required property string modelData

        drive: Drives.rows.find(row => row.id === card.modelData) ?? ({})
        shown: root.expanded
      }
    }
  }
}
