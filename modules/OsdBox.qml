import QtQuick
import qs.components
import qs.services
import qs.theme

// what the volume and brightness keys put on screen: a box that drops out of the
// system tab, says which one moved and how far, and takes itself away again.
//
// it is OsdBox rather than Osd because services/Osd.qml already has that name, and
// a window importing both modules could not say which one it meant -- the same
// collision services/Bluez.qml is named around.
//
// it hangs below the strip and is wider than it, so its left corners are exposed
// and take the tab's own radius while its right edge stays flush against the
// border, where the tab's fillets carry on down its side.
Item {
  id: root

  // the strip this hangs from. the design states the width as that plus osdWiden,
  // and the contents win if they need more.
  property real stripWidth: 0

  // whether this is the screen to show on. every screen has a box, and a key press
  // is answered on the one being looked at -- three boxes for one brightness key
  // is two of them reporting a laptop panel from monitors it does not light.
  property bool here: true

  readonly property bool volume: Osd.kind === "volume"
  readonly property bool muted: root.volume && Audio.muted

  readonly property int value: {
    if (!root.volume) return Backlight.percent
    return root.muted ? 0 : Math.round(Audio.volume * 100)
  }

  // the glyph and the bar are the same colour, so a muted sound reads as one
  // statement rather than a grey icon over a blue bar.
  readonly property color fill: root.muted ? Theme.osdFillMuted : Theme.osdFill

  // 0 away, 1 fully out. the drop-in reads this rather than animating three
  // properties separately and letting them drift apart.
  property real reveal: Osd.shown && root.here ? 1 : 0

  // what the shadow beside the frame has to match. it is drawn there rather than
  // here so the border band covers the part of it that falls on the band.
  readonly property real bodyHeight: root.height

  implicitWidth: Math.max(root.stripWidth + Theme.osdWiden, content.implicitWidth + Theme.osdPaddingH * 2)
  implicitHeight: content.implicitHeight + Theme.osdPaddingTop + Theme.osdPaddingBottom
  width: root.implicitWidth
  height: root.implicitHeight

  visible: root.reveal > 0
  opacity: root.reveal

  // the design's `translateY(-10px) scaleY(.82)` out of the tab, from the top
  // right corner it hangs from.
  transform: [
    Scale {
      origin.x: root.width
      origin.y: 0
      yScale: Theme.osdSquash + (1 - Theme.osdSquash) * root.reveal
    },
    Translate {
      y: -Theme.osdRise * (1 - root.reveal)
    }
  ]

  Behavior on reveal {
    Glide { duration: Theme.osdDuration }
  }

  Rectangle {
    anchors.fill: parent

    color: Theme.notch
    topLeftRadius: Theme.notchRadius
    bottomLeftRadius: Theme.notchRadius
  }

  Row {
    id: content

    x: Theme.osdPaddingH
    y: Theme.osdPaddingTop

    spacing: Theme.osdGap

    Glyph {
      anchors.verticalCenter: column.verticalCenter

      icon: {
        if (!root.volume) return Backlight.levelGlyph(Backlight.level)

        // the real level and the mute flag rather than the zeroed reading above:
        // the shared ladder is the one that decides what muted looks like.
        return Audio.levelGlyph(Audio.volume, root.muted)
      }

      iconColor: root.fill
      size: Theme.osdGlyphSize
      filled: true
    }

    Column {
      id: column

      width: Theme.osdColumn
      spacing: Theme.osdColumnGap

      Item {
        width: parent.width
        height: title.implicitHeight

        Text {
          id: title

          text: {
            if (!root.volume) return "Brightness"
            return root.muted ? "Muted" : "Volume"
          }

          color: Theme.osdTitleText
          font.family: Theme.uiFont
          font.pixelSize: Theme.osdTitleSize
          font.variableAxes: Theme.uiAxesSemiBold
        }

        Text {
          anchors.right: parent.right
          anchors.baseline: title.baseline

          // a muted sound has no level to report, so it says so rather than
          // printing the nothing it is playing at.
          text: root.muted ? "—" : `${root.value}%`
          color: Theme.osdValueText
          font.family: Theme.monoFont
          font.pixelSize: Theme.osdValueSize
        }
      }

      Meter {
        width: parent.width
        height: Theme.osdTrack
        radius: Theme.osdTrackRadius
        color: Theme.osdRail

        value: root.value / 100
        tint: root.fill
        fillDuration: Theme.osdFillDuration
      }
    }
  }
}
