import QtQuick
import Quickshell.Widgets
import qs.theme

// what every card on the toast stack is drawn in: a tile on the left, who it is
// from and when on the first line, and whatever the card says underneath. a
// notification and a bluetooth question fill it differently and look the same.
Rectangle {
  id: root

  property string app: ""
  property string when: ""

  // what sits in the tile: an icon, or a glyph when there is none.
  property alias tile: chip.data

  // what goes under the header line.
  default property alias content: column.data

  // a click anywhere on the card that nothing on it answered for itself.
  signal clicked()

  // the sentence a card says, in the toast's own type.
  component BodyText: Text {
    width: parent.width

    wrapMode: Text.Wrap
    color: Theme.toastBody
    font.family: Theme.uiFont
    font.variableAxes: Theme.uiAxesRegular
    font.pixelSize: Theme.toastBodySize
    lineHeight: Theme.toastBodyLine
    lineHeightMode: Text.FixedHeight
  }

  width: Theme.toastWidth
  implicitHeight: body.implicitHeight + Theme.toastPaddingV * 2

  radius: Theme.toastRadius
  color: Theme.toastFill

  // the design's `0 0 0 1px rgba(255,255,255,.05)`, which is the only thing
  // separating a dark card from a dark desktop once the blur has softened both.
  border.width: 1
  border.color: Theme.pkOutline

  // under everything else in the card, because it is declared first: a click on
  // one of the card's own buttons is not also a click on the card.
  MouseArea {
    anchors.fill: parent

    onClicked: root.clicked()
  }

  Row {
    id: body

    x: Theme.toastPaddingH
    y: Theme.toastPaddingV
    width: parent.width - Theme.toastPaddingH * 2

    spacing: Theme.toastRowGap

    ClippingRectangle {
      id: chip

      width: Theme.toastChipSize
      height: Theme.toastChipSize
      radius: Theme.toastChipRadius
      color: Theme.toastChipFill
    }

    Column {
      id: column

      width: parent.width - Theme.toastChipSize - Theme.toastRowGap
      spacing: Theme.toastTextGap

      Item {
        width: parent.width
        height: Math.max(from.implicitHeight, time.implicitHeight)

        Text {
          id: from

          anchors.left: parent.left
          anchors.right: time.left
          anchors.rightMargin: Theme.toastRowGap
          anchors.baseline: time.baseline

          text: root.app
          elide: Text.ElideRight
          color: Theme.tintBright
          font.family: Theme.monoFont
          font.pixelSize: Theme.toastAppSize
          font.weight: Font.Medium
        }

        Text {
          id: time

          anchors.right: parent.right

          text: root.when
          color: Theme.toastTime
          font.family: Theme.monoFont
          font.pixelSize: Theme.toastTimeSize
        }
      }
    }
  }
}
