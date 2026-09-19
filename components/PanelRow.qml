import QtQuick
import qs.theme

// a row in the system panel: a summary you can read at a glance, and a body that
// folds out under it when you click. the panel decides which row is open, since
// only one can be, so this takes `expanded` rather than keeping it.
Rectangle {
  id: root

  property string icon: ""
  property string label: ""
  property string value: ""

  // whether the row's subject is on at all. it tints the icon, which is the only
  // thing in the collapsed row that says so.
  property bool lit: false

  property bool expanded: false

  // what the children of the fold have to fit into, since a Column does not
  // stretch what it stacks.
  readonly property real bodyWidth: root.width - Theme.sysBodyPaddingH * 2

  // what drops out of the row. one child, measured by the column it lands in, so
  // the fold animates to a height nothing had to write down.
  default property alias content: body.data

  signal toggled()

  implicitHeight: header.height + fold.height

  radius: Theme.sysRowRadius
  color: root.expanded ? Theme.sysRowOpen : "transparent"

  // the fold has to be cut off at the row's edge on its way open, and the row's
  // own corners are rounded, so the clip is doing two jobs.
  clip: true

  Behavior on color {
    ColorAnimation { duration: Theme.notchFadeDuration }
  }

  Item {
    id: header

    anchors.left: parent.left
    anchors.right: parent.right
    anchors.top: parent.top
    height: Theme.sysRowIcon + Theme.sysRowPaddingV * 2

    Glyph {
      id: rowIcon

      x: Theme.sysRowPaddingH
      anchors.verticalCenter: parent.verticalCenter

      size: Theme.sysRowIcon
      icon: root.icon
      iconColor: root.lit ? Theme.accent : Theme.sysDim
    }

    Text {
      id: rowLabel

      anchors.left: rowIcon.right
      anchors.leftMargin: Theme.sysRowGap
      anchors.verticalCenter: parent.verticalCenter

      text: root.label
      color: Theme.text
      font.family: Theme.uiFont
      font.pixelSize: Theme.sysRowLabelSize
      font.weight: Font.Medium
    }

    Glyph {
      id: chevron

      x: root.width - Theme.sysRowPaddingH - width
      anchors.verticalCenter: parent.verticalCenter

      size: Theme.sysChevron
      icon: "keyboard_arrow_down"
      iconColor: Theme.sysDim
      rotation: root.expanded ? 180 : 0

      Behavior on rotation {
        NumberAnimation { duration: 200 }
      }
    }

    Text {
      // the design gives the label flex and leaves the value its natural width.
      // anchoring both ends and aligning right is the same thing until the value
      // is long enough to reach the label, and then it elides instead of pushing.
      anchors.left: rowLabel.right
      anchors.leftMargin: Theme.sysRowGap
      anchors.right: chevron.left
      anchors.rightMargin: Theme.sysRowGap
      anchors.verticalCenter: parent.verticalCenter

      text: root.value
      color: Theme.sysValue
      font.family: Theme.monoFont
      font.pixelSize: Theme.sysRowValueSize
      horizontalAlignment: Text.AlignRight
      elide: Text.ElideRight
    }

    MouseArea {
      anchors.fill: parent

      onClicked: root.toggled()
    }
  }

  Item {
    id: fold

    anchors.left: parent.left
    anchors.right: parent.right
    anchors.top: header.bottom
    height: root.expanded ? body.implicitHeight : 0

    Behavior on height {
      NumberAnimation {
        duration: Theme.notchExpandDuration
        easing.type: Easing.Bezier
        easing.bezierCurve: Theme.easeStandard
      }
    }

    Column {
      id: body

      anchors.left: parent.left
      anchors.right: parent.right

      leftPadding: Theme.sysBodyPaddingH
      rightPadding: Theme.sysBodyPaddingH
      topPadding: Theme.sysBodyTop
      bottomPadding: Theme.sysBodyBottom
      spacing: Theme.sysBodyGap
    }
  }
}
