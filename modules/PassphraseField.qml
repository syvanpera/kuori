import QtQuick
import qs.components
import qs.services
import qs.theme

// what a locked network opens underneath itself: somewhere to type the
// passphrase, and a button to try it. enter does the same thing as the button.
Item {
  id: root

  // the design pads this row unevenly, so the two controls are centred on what is
  // left rather than on the row.
  readonly property real midline: (Theme.sysFieldTop + root.height - Theme.sysFieldBottom) / 2

  implicitHeight: Theme.sysFieldHeight

  PillButton {
    id: join

    x: root.width - Theme.sysFieldPaddingH - width
    y: root.midline - height / 2

    label: "Connect"
    fill: Theme.sysJoinFill
    hoverFill: Theme.sysJoinHover
    textColor: Theme.accent
    textSize: Theme.sysJoinSize
    paddingH: Theme.sysJoinPaddingH
    paddingV: Theme.sysJoinPaddingV
    radius: Theme.sysFieldRadius

    onClicked: Network.join(input.text)
  }

  Rectangle {
    id: field

    x: Theme.sysFieldPaddingH
    y: root.midline - height / 2

    width: join.x - Theme.sysFieldGap - x
    height: input.implicitHeight + Theme.sysFieldInnerV * 2
    radius: Theme.sysFieldRadius
    color: Theme.sysFieldFill
    border.width: 1
    border.color: Theme.sysFieldBorder

    Field {
      id: input

      anchors.left: parent.left
      anchors.right: parent.right
      anchors.leftMargin: Theme.sysFieldInnerH
      anchors.rightMargin: Theme.sysFieldInnerH
      anchors.verticalCenter: parent.verticalCenter

      // the field is the only reason this row exists, so it takes the keyboard the
      // moment it appears rather than waiting to be clicked.
      focus: true
      echoMode: TextInput.Password
      color: Theme.text
      font.family: Theme.monoFont
      font.pixelSize: Theme.sysFieldSize
      font.weight: Font.Medium
      selectByMouse: true

      Component.onCompleted: input.forceActiveFocus()

      Keys.onReturnPressed: Network.join(input.text)

      // the numpad's enter is a different key.
      Keys.onEnterPressed: Network.join(input.text)

      // escape folds the field away rather than shutting the whole panel: the
      // panel is still where you were, and one more escape leaves it.
      Keys.onEscapePressed: Network.selected = ""

      placeholder: "Passphrase"

      // the frame's key sink is what hears escape once this is gone, and it will
      // not take the keyboard back on its own.
      Component.onDestruction: Notches.refocus()
    }
  }
}
