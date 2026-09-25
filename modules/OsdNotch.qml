import QtQuick
import qs.components
import qs.services
import qs.theme

// the design's other on-screen display: a tab of its own, hanging off the top
// band between the clock and the toggles, rather than a box dropping out of the
// system tab. it says what OsdBox says, from the same Osd, in one line: the
// glyph, the title while voice typing, the bar or the meter, and the reading.
//
// it is a Notch for the corners and the fillets, wrapped so the slide and the
// fade can move it whole: a Notch fades its own opacity, and a binding moving
// under that fade every frame would restart it every frame. it takes no input and
// is never in the window's mask.
Item {
  id: root

  // whether this is the screen to show on, as OsdBox has it.
  property bool here: true

  // 0 away, 1 fully out, sliding down from behind the band: the design's
  // `translateY(-100%)` with its fade.
  property real reveal: Osd.notched && root.here ? 1 : 0
  readonly property real slide: -root.height * (1 - root.reveal)

  // what NotchShadow asks of a tab, so the shadow can be drawn before the frame
  // with the others.
  readonly property bool flushLeft: false
  readonly property bool flushRight: false
  readonly property real hangHeight: 0
  readonly property real bodyHeight: tab.bodyHeight

  implicitWidth: tab.width
  implicitHeight: tab.height
  width: root.implicitWidth
  height: root.implicitHeight

  visible: root.reveal > 0
  opacity: root.reveal

  transform: Translate { y: root.slide }

  Behavior on reveal {
    Glide { duration: Theme.osdNotchDuration }
  }

  Notch {
    id: tab

    placement: "center"
    padding: Theme.notchPadding

    Row {
      spacing: Theme.osdNotchGap

      Glyph {
        anchors.verticalCenter: parent.verticalCenter

        icon: Osd.glyph
        iconColor: Osd.fill
        size: Theme.iconSize
        filled: true
      }

      // only voice typing names itself: a bar under a sun or a speaker says
      // which it is already, and "Listening" is the one thing a meter cannot.
      Text {
        anchors.verticalCenter: parent.verticalCenter
        visible: Osd.voice

        text: Osd.title
        color: Theme.osdTitleText
        font.family: Theme.uiFont
        font.pixelSize: Theme.osdTitleSize
        font.variableAxes: Theme.uiAxesSemiBold
      }

      OsdLevel {
        anchors.verticalCenter: parent.verticalCenter

        width: Theme.osdNotchTrack
        running: root.visible
      }

      Text {
        anchors.verticalCenter: parent.verticalCenter
        width: Math.max(Theme.osdNotchValueWidth, implicitWidth)

        text: Osd.reading
        color: Theme.osdValueText
        font.family: Theme.monoFont
        font.pixelSize: Theme.osdValueSize
        horizontalAlignment: Text.AlignRight
      }
    }
  }
}
