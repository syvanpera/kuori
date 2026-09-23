import QtQuick
import qs.theme

// a labelled switch with a line under it saying what the switch is currently
// doing: the shape the design gives night light and stay awake.
Item {
  id: root

  property string icon: ""
  property string label: ""
  property string detail: ""
  property bool checked: false

  // the system panel's keyboard lands here, and return throws the switch.
  readonly property bool keyTarget: true
  property bool keyed: false

  signal toggled()

  function press(): void {
    root.toggled()
  }

  implicitHeight: Math.max(glyph.height, text.implicitHeight, control.height)

  KeyWash {
    shown: root.keyed
  }

  Glyph {
    id: glyph

    anchors.left: parent.left
    anchors.verticalCenter: parent.verticalCenter

    icon: root.icon
    size: Theme.dispToggleIcon

    // the icon is the only part of the collapsed row that says whether this is on.
    iconColor: root.checked ? Theme.accent : Theme.dispToggleOff

    Behavior on iconColor {
      ColorAnimation { duration: Theme.notchFadeDuration }
    }
  }

  Column {
    id: text

    anchors.left: glyph.right
    anchors.leftMargin: Theme.dispToggleGap
    anchors.right: control.left
    anchors.rightMargin: Theme.dispToggleGap
    anchors.verticalCenter: parent.verticalCenter

    spacing: Theme.dispToggleTextGap

    Text {
      width: parent.width

      text: root.label
      elide: Text.ElideRight
      color: Theme.dispToggleLabel
      font.family: Theme.uiFont
      font.variableAxes: Theme.uiAxesMedium
      font.pixelSize: Theme.dispToggleLabelSize
    }

    Text {
      width: parent.width

      text: root.detail
      elide: Text.ElideRight
      color: Theme.dispToggleSub
      font.family: Theme.monoFont
      font.pixelSize: Theme.dispToggleSubSize
    }
  }

  Switch {
    id: control

    anchors.right: parent.right
    anchors.verticalCenter: parent.verticalCenter

    checked: root.checked

    onToggled: root.toggled()
  }
}
