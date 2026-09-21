import QtQuick
import qs.theme

// something on the system tab's strip that opens its own section of the panel:
// the wifi, bluetooth, volume and battery reports. it wraps whatever it is given
// rather than drawing a glyph itself, because the battery is a glyph and its
// percentage and the design makes the pair one target.
//
// the rule under an open section is a rectangle, not font.underline: the design
// states a thickness and a gap, and a font underline honours neither.
Item {
  id: root

  // whether this is the section the panel is currently showing.
  property bool active: false

  default property alias content: holder.data

  signal clicked()

  implicitWidth: holder.implicitWidth
  implicitHeight: holder.implicitHeight
  width: root.implicitWidth
  height: root.implicitHeight

  Item {
    id: holder

    // the child sits at 0,0 and never anchors back here, so measuring it this way
    // cannot loop.
    implicitWidth: childrenRect.width
    implicitHeight: childrenRect.height
    width: holder.implicitWidth
    height: holder.implicitHeight
  }

  // below the content rather than inside it, so a section opening does not make
  // the strip taller and shove every glyph on it sideways. the strip's padding is
  // deeper than the gap, so it still lands on the tab.
  Rectangle {
    y: root.height + Theme.stripUnderlineGap
    width: root.width
    height: Theme.stripUnderline
    radius: height / 2
    color: Theme.accent

    opacity: root.active ? 1 : 0

    Behavior on opacity {
      NumberAnimation { duration: Theme.notchFadeDuration }
    }
  }

  MouseArea {
    anchors.fill: parent

    onClicked: root.clicked()
  }
}
