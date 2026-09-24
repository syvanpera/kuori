import QtQuick
import qs.services
import qs.theme

// something on a strip that opens its own section of the panel or throws a
// switch: the system tab's reports and the toggles tab's three. it wraps whatever
// it is given rather than drawing a glyph itself, because the battery is a glyph
// and its percentage and the design makes the pair one target.
//
// the rule under an open section is a rectangle, not font.underline: the design
// states a thickness and a gap, and a font underline honours neither.
Item {
  id: root

  // whether this is the section the panel is currently showing.
  property bool active: false

  // the design's `title` for this icon, and the screen it is on: the frame there
  // draws it once the pointer has rested (StripTip).
  property string tip: ""
  property string screenName: ""

  default property alias content: holder.data

  signal clicked()

  implicitWidth: holder.implicitWidth
  implicitHeight: holder.implicitHeight
  width: root.implicitWidth
  height: root.implicitHeight

  function showTip(): void {
    Notches.tipScreen = root.screenName
    Notches.tip = root
  }

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

  // one QML Timer per button, but only running while the pointer rests on it.
  Timer {
    id: rest

    interval: Theme.tipDelay

    onTriggered: root.showTip()
  }

  MouseArea {
    anchors.fill: parent

    hoverEnabled: Theme.stripTips && root.tip !== ""

    // qt sends the next button its enter before the last one its exit, so a tip
    // still up is as warm as one that has just gone.
    onEntered: {
      if (Notches.tip !== null || Date.now() - Notches.tipGone < Theme.tipWarm) root.showTip()
      else rest.restart()
    }

    onExited: {
      rest.stop()
      if (Notches.tip !== root) return
      Notches.tip = null
      Notches.tipGone = Date.now()
    }

    onClicked: root.clicked()
  }
}
