import QtQuick
import Quickshell
import Quickshell.Widgets
import qs.components
import qs.services
import qs.theme

// what the tray tab hangs under its icons: the menu of the one that was right
// clicked, drawn by the shell rather than handed to qt's own popup, so it is the
// same surface as every other panel. a submenu replaces the list, with a row at
// the top to go back up.
Column {
  id: root

  readonly property var item: Tray.menuItem

  // the submenus walked into from the item's own menu, innermost last, each with
  // the label it was reached by.
  property var stack: []

  readonly property var handle: root.stack.length > 0
    ? root.stack[root.stack.length - 1].handle
    : root.item?.menu ?? null

  readonly property var entries: opener.children?.values ?? []

  // a column of labels only lines up with a column of checks if every label sits
  // past them, so the whole list takes the indent when any entry has something
  // in front of it.
  readonly property bool indented: root.entries.some(entry => entry.buttonType !== QsMenuButtonType.None || entry.icon !== "")

  // what the arrow keys are on: null until the first arrow, so a menu opened by
  // the mouse shows nothing lit that nobody asked for.
  property Item cursor: null

  // the rows a click means something on, in reading order: the way back, then
  // every enabled entry. walked on every key rather than kept, because an
  // application can rewrite its menu while it is open.
  function rows(): var {
    const found = Array.from(list.children).filter(child => child.keyTarget === true && child.visible)

    if (back.visible) found.unshift(back)

    return found
  }

  // one step through the rows, wrapping at both ends like the system panel.
  function step(delta: int): void {
    const found = root.rows()
    if (found.length === 0) return

    let at = found.indexOf(root.cursor)
    if (at < 0) at = delta > 0 ? -1 : found.length

    root.cursor = found[(at + delta + found.length) % found.length]
  }

  function press(): void {
    if (root.cursor && root.rows().includes(root.cursor)) root.cursor.press()
  }

  // a fresh array is a change even when it is as empty as the last, and the
  // first read of item, from inside handle's binding, lands here: emptying an
  // empty stack then would be handle changing while it is being worked out.
  function reset(): void {
    if (root.stack.length > 0) root.stack = []
    root.cursor = null
  }

  function enter(entry: var): void {
    root.stack = [...root.stack, { handle: entry, text: root.label(entry.text) }]
    root.cursor = null
  }

  function leave(): void {
    if (root.stack.length === 0) return

    root.stack = root.stack.slice(0, -1)
    root.cursor = null
  }

  // dbusmenu marks a mnemonic with an underscore and writes a real one as two.
  function label(text: string): string {
    return text.replace(/__|_/g, match => match === "__" ? "_" : "")
  }

  // another item's menu starts at its top, and so does the same one opened again.
  // on the way in rather than out, so a menu fading away keeps what it showed.
  onItemChanged: root.reset()

  Connections {
    target: Notches

    function onOpenChanged(): void {
      if (Notches.open === "tray") root.reset()
    }
  }

  width: Theme.trayMenuWidth
  padding: Theme.trayMenuPadding
  topPadding: Theme.trayMenuPaddingTop
  spacing: Theme.sysNetSpacing

  // the opener is what tells the application its menu is being looked at, which
  // some only fill in when they hear it.
  QsMenuOpener {
    id: opener

    menu: root.handle
  }

  TrayMenuEntry {
    id: back

    visible: root.stack.length > 0
    width: root.width - root.padding * 2

    text: root.stack[root.stack.length - 1]?.text ?? ""
    leading: "chevron_left"
    indented: true
    keyed: root.cursor === back

    onClicked: root.leave()
  }

  Rule {
    visible: back.visible
    width: root.width - root.padding * 2
  }

  Column {
    id: list

    width: root.width - root.padding * 2
    spacing: Theme.sysNetSpacing

    Repeater {
      model: root.entries

      TrayMenuEntry {
        id: entry

        required property var modelData

        width: list.width

        separator: entry.modelData.isSeparator
        text: root.label(entry.modelData.text)
        image: entry.modelData.icon
        enabled: entry.modelData.enabled
        submenu: entry.modelData.hasChildren
        indented: root.indented
        keyed: root.cursor === entry

        leading: {
          const checked = entry.modelData.checkState === Qt.Checked

          if (entry.modelData.buttonType === QsMenuButtonType.CheckBox) return checked ? "check_box" : "check_box_outline_blank"
          if (entry.modelData.buttonType === QsMenuButtonType.RadioButton) return checked ? "radio_button_checked" : "radio_button_unchecked"
          return ""
        }

        onClicked: {
          if (entry.modelData.hasChildren) {
            root.enter(entry.modelData)
            return
          }

          entry.modelData.triggered()
          Notches.close()
        }
      }
    }
  }

  // an application can answer with nothing, or not yet.
  Text {
    visible: root.entries.length === 0
    width: root.width - root.padding * 2
    leftPadding: Theme.sysNetPaddingH
    topPadding: Theme.sysNetPaddingV
    bottomPadding: Theme.sysNetPaddingV

    text: "Nothing in this menu"
    color: Theme.sysNetDetail
    font.family: Theme.monoFont
    font.pixelSize: Theme.sysNetNameSize
  }
}
