import QtQuick
import QtQuick.Effects
import qs.services
import qs.theme

// the name of the strip icon the pointer is resting on, hung under the tab. the
// design writes these as `title` attributes and leaves the drawing to the browser;
// this is the smallest thing that looks like it belongs to the shell -- the tab's
// own surface, its shadow, one line of text.
//
// one per frame rather than one per button, drawn last so it is over the frame
// and every tab. it only paints: the window's input region never includes it, so
// it cannot take a click meant for the window underneath.
Item {
  id: root

  // the screen this frame is on. a button hovered on another screen is not ours.
  property string screenName: ""

  // something else is hanging where this would go: the osd under the system tab.
  property bool blocked: false

  readonly property Item button: Notches.tipScreen === root.screenName ? Notches.tip : null

  // an open panel is already the answer to what the icon is, and a tip over it
  // would sit on top of the thing being read.
  readonly property bool shown: Theme.stripTips
    && root.button !== null
    && root.button.tip !== ""
    && Notches.openOn(root.screenName) === ""
    && !root.blocked

  // where the button is, captured as it is set. the strip does not move under a
  // resting pointer, so this does not need to follow it.
  property point anchor: Qt.point(0, 0)

  onButtonChanged: {
    if (!root.button) return
    root.anchor = root.button.mapToItem(root.parent, root.button.width / 2, 0)
  }

  x: Math.max(Theme.borderWidth + Theme.tipMargin,
    Math.min(root.parent.width - Theme.borderWidth - Theme.tipMargin - root.width,
      Math.round(root.anchor.x - root.width / 2)))
  y: Theme.borderWidth + Theme.notchHeight + Theme.tipGap
  width: label.implicitWidth + Theme.tipPaddingH * 2
  height: label.implicitHeight + Theme.tipPaddingV * 2

  opacity: root.shown ? 1 : 0
  visible: root.opacity > 0

  Behavior on opacity {
    NumberAnimation { duration: Theme.notchFadeDuration }
  }

  // sliding from one icon to the next rather than jumping, while it is up.
  Behavior on x {
    enabled: root.opacity > 0
    Glide { duration: Theme.notchFadeDuration }
  }

  RectangularShadow {
    anchors.fill: parent

    blur: Theme.tipShadowBlur
    offset.y: Theme.tipShadowOffset
    radius: Theme.tipRadius
    color: Theme.notchShadowAmbient
  }

  Rectangle {
    anchors.fill: parent

    radius: Theme.tipRadius
    color: Theme.notch
  }

  Text {
    id: label

    anchors.centerIn: parent

    // live while showing, so a switch thrown under the pointer says what it just
    // became, and left alone once it goes, so the text does not empty itself while
    // the tip fades.
    Binding on text {
      when: root.button !== null
      restoreMode: Binding.RestoreNone
      value: root.button?.tip ?? ""
    }

    color: Theme.text
    font.family: Theme.uiFont
    font.pixelSize: Theme.tipSize
    font.variableAxes: Theme.uiAxesMedium
  }
}
