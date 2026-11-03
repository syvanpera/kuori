import QtQuick
import Quickshell.Widgets
import qs.components
import qs.theme

// one line of a tray menu: a label, with a check, a radio or the application's
// own icon in front of it, and a chevron after it when it opens a submenu. or a
// separator, which is a hairline and nothing else. the sizes are the system
// panel's list entries', so a menu reads as one more list in the shell.
Item {
  id: root

  property bool separator: false
  property string text: ""

  // a material symbol in front of the label, or the application's own picture
  // there instead. the symbol wins: it is the entry's check or radio.
  property string leading: ""
  property string image: ""

  // whether the label sits past the leading column, which the menu decides for
  // every entry at once so the labels line up.
  property bool indented: false

  property bool submenu: false

  // the tray menu's keyboard, the system panel's way: a target is anything with
  // keyTarget, keyed and press().
  readonly property bool keyTarget: !root.separator && root.enabled
  property bool keyed: false

  signal clicked()

  function press(): void {
    if (root.keyTarget) root.clicked()
  }

  implicitHeight: root.separator
    ? Theme.trayMenuSeparatorGap * 2 + 1
    : Math.max(Theme.sysNetIcon, label.implicitHeight) + Theme.sysNetPaddingV * 2

  // a disabled entry is still there to be read, only fainter.
  opacity: root.enabled ? 1 : Theme.trayMenuDisabled

  Rule {
    visible: root.separator
    width: root.width
    anchors.verticalCenter: parent.verticalCenter
  }

  Rectangle {
    anchors.fill: parent
    visible: !root.separator

    radius: Theme.sysNetRadius
    color: (hover.containsMouse || root.keyed) && root.enabled ? Theme.sysNetHover : "transparent"

    Behavior on color {
      ColorAnimation { duration: Theme.notchFadeDuration }
    }
  }

  Glyph {
    id: glyph

    visible: !root.separator && root.leading !== ""
    x: Theme.sysNetPaddingH
    anchors.verticalCenter: parent.verticalCenter

    size: Theme.sysNetIcon
    icon: root.leading
    iconColor: root.keyed ? Theme.accent : Theme.sysNetGlyph
  }

  IconImage {
    visible: !root.separator && root.leading === "" && root.image !== ""
    x: Theme.sysNetPaddingH
    anchors.verticalCenter: parent.verticalCenter

    implicitSize: Theme.sysNetIcon
    source: root.image
    asynchronous: true
  }

  Text {
    id: label

    visible: !root.separator
    anchors.left: parent.left
    anchors.leftMargin: root.indented ? Theme.sysNetPaddingH + Theme.sysNetIcon + Theme.sysNetGap : Theme.sysNetPaddingH
    anchors.right: chevron.visible ? chevron.left : parent.right
    anchors.rightMargin: chevron.visible ? Theme.sysNetGap : Theme.sysNetPaddingH
    anchors.verticalCenter: parent.verticalCenter

    text: root.text
    color: root.keyed || hover.containsMouse ? Theme.text : Theme.sysNetName
    font.family: Theme.monoFont
    font.pixelSize: Theme.sysNetNameSize
    font.weight: Font.Medium
    elide: Text.ElideRight
  }

  Glyph {
    id: chevron

    visible: !root.separator && root.submenu
    x: root.width - Theme.sysNetPaddingH - width
    anchors.verticalCenter: parent.verticalCenter

    size: Theme.sysNetIcon
    icon: "chevron_right"
    iconColor: Theme.sysNetGlyph
  }

  MouseArea {
    id: hover

    anchors.fill: parent
    hoverEnabled: true
    enabled: root.keyTarget

    onClicked: root.clicked()
  }
}
