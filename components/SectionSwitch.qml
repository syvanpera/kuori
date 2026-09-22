import QtQuick

// a caption with a switch at the far end of the line: the shape the design puts at
// the top of the wifi, bluetooth, audio and notification rows, where the one thing
// the section can be turned off by lives.
//
// CaptureSwitch is the same arrangement in the capture panel's own face, which is
// sentence case and a different font. they are two looks rather than one, so they
// stay two components.
Item {
  id: root

  property string label: "ENABLED"
  property bool checked: false

  signal toggled()

  implicitHeight: Math.max(caption.implicitHeight, control.height)

  Caption {
    id: caption

    anchors.left: parent.left
    anchors.verticalCenter: parent.verticalCenter

    text: root.label
  }

  Switch {
    id: control

    anchors.right: parent.right
    anchors.verticalCenter: parent.verticalCenter

    checked: root.checked

    onToggled: root.toggled()
  }
}
