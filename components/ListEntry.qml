import QtQuick
import qs.theme

// one line in a system panel list: a glyph, a name, sometimes a second line, and
// sometimes something at the far end -- a lock, a switch. an access point, a wire,
// a bluetooth device and an audio output are all drawn this way, and what differs
// between them is what they say, not how.
Rectangle {
  id: root

  property string icon: ""
  property string name: ""
  property string detail: ""

  // the entry is the one its list is about -- connected, current, being asked.
  // the glyph takes the accent and the name brightens.
  property bool lit: false

  property color nameColor: Theme.sysNetName
  property color detailColor: Theme.sysNetDetail

  // the background while the pointer is elsewhere.
  property color fill: "transparent"

  // whether a click means anything. an entry that would ignore one does not light
  // up under the pointer either.
  property bool clickable: true

  // one line sized to the glyph rather than to the text. an audio output has no
  // second line, and the design sizes its row by the icon.
  property bool compact: false

  // what sits at the far end, if anything. the name gives way to it.
  default property alias trailing: trailing.data

  signal clicked()

  implicitHeight: (root.compact ? Theme.sysNetIcon : Math.max(Theme.sysNetIcon, text.implicitHeight)) + Theme.sysNetPaddingV * 2

  radius: Theme.sysNetRadius
  color: hover.containsMouse && root.clickable ? Theme.sysNetHover : root.fill

  Behavior on color {
    ColorAnimation { duration: Theme.notchFadeDuration }
  }

  Glyph {
    id: glyph

    x: Theme.sysNetPaddingH
    anchors.verticalCenter: parent.verticalCenter

    size: Theme.sysNetIcon
    icon: root.icon
    iconColor: root.lit ? Theme.accent : Theme.sysNetGlyph
  }

  Column {
    id: text

    anchors.left: glyph.right
    anchors.leftMargin: Theme.sysNetGap
    anchors.right: trailing.width > 0 ? trailing.left : parent.right
    anchors.rightMargin: trailing.width > 0 ? Theme.sysNetGap : Theme.sysNetPaddingH
    anchors.verticalCenter: parent.verticalCenter

    spacing: Theme.sysNetTextSpacing

    Text {
      width: parent.width

      text: root.name
      color: root.lit ? Theme.text : root.nameColor
      font.family: Theme.monoFont
      font.pixelSize: Theme.sysNetNameSize
      font.weight: Font.Medium
      elide: Text.ElideRight
    }

    Text {
      width: parent.width
      visible: root.detail !== ""

      text: root.detail
      color: root.detailColor
      font.family: Theme.monoFont
      font.pixelSize: Theme.sysNetDetailSize
      elide: Text.ElideRight
    }
  }

  // under the trailing control, which is declared after it: a switch at the far
  // end answers its own clicks.
  MouseArea {
    id: hover

    anchors.fill: parent
    hoverEnabled: true
    enabled: root.clickable

    onClicked: root.clicked()
  }

  Row {
    id: trailing

    x: root.width - Theme.sysNetPaddingH - trailing.width
    anchors.verticalCenter: parent.verticalCenter
  }
}
