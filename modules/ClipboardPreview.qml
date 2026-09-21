import QtQuick
import qs.components
import qs.services
import qs.theme

// what the selected clipboard entry actually is, under the launcher's list. the
// list shows cliphist's own truncated preview; this shows the whole thing.
Rectangle {
  id: root

  // the row the launcher has selected, or null.
  required property var row

  readonly property string kind: root.row?.kind ?? ""

  implicitHeight: body.implicitHeight + Theme.clipPreviewTop + Theme.clipPreviewBottom

  radius: Theme.clipPreviewRadius
  color: Theme.clipPreviewFill

  Column {
    id: body

    x: Theme.clipPreviewPaddingH
    y: Theme.clipPreviewTop
    width: parent.width - Theme.clipPreviewPaddingH * 2

    spacing: Theme.clipPreviewGap

    Text {
      // the design puts the entry's age on the right of this line. cliphist keeps
      // no timestamps -- its ids are a counter -- so there is nothing true to put
      // there, the same reason the rows themselves carry no age.
      text: "PREVIEW"
      color: Theme.clipPreviewMeta
      font.family: Theme.monoFont
      font.pixelSize: Theme.clipPreviewMetaSize
      font.weight: Font.Medium
      font.letterSpacing: Theme.sysCapSpacing
    }

    // text and links: the whole content, scrollable when it does not fit.
    Flickable {
      width: parent.width
      height: Math.min(contentHeight, Theme.clipPreviewTextMax)

      visible: root.kind === "text" || root.kind === "link"
      contentHeight: full.implicitHeight
      clip: true
      boundsBehavior: Flickable.StopAtBounds

      Text {
        id: full

        width: parent.width

        text: Clipboard.previewText
        wrapMode: Text.Wrap
        color: Theme.clipPreviewText
        font.family: Theme.monoFont
        font.pixelSize: Theme.clipPreviewTextSize
        lineHeight: Theme.clipPreviewTextLine
        lineHeightMode: Text.FixedHeight
      }
    }

    // a colour is worth seeing rather than reading.
    Row {
      visible: root.kind === "color"
      spacing: Theme.clipPreviewSwatchGap

      Rectangle {
        width: Theme.clipPreviewSwatch
        height: Theme.clipPreviewSwatch
        radius: Theme.clipPreviewSwatchRadius
        color: root.row?.swatch ?? "transparent"

        // the design's inset hairline, which is what keeps a dark swatch from
        // disappearing into a dark well.
        border.width: 1
        border.color: Theme.clipPreviewRing
      }

      Text {
        anchors.verticalCenter: parent.verticalCenter

        text: root.row?.name ?? ""
        color: Theme.text
        font.family: Theme.monoFont
        font.pixelSize: Theme.clipPreviewValueSize
        font.weight: Font.Medium
      }
    }

    // an image. the design draws a placeholder on the chequered ground, because a
    // mockup has no real clipboard to read; here the ground is what shows through
    // a transparent one.
    Rectangle {
      width: parent.width
      height: Theme.clipPreviewImageHeight

      visible: root.kind === "image"
      radius: Theme.clipPreviewImageRadius
      color: "transparent"

      border.width: 1
      border.color: Theme.clipPreviewImageRing

      Checkerboard {
        anchors.fill: parent
        anchors.margins: 1
      }

      Image {
        anchors.fill: parent
        anchors.margins: 1

        visible: Clipboard.previewImage !== ""
        source: Clipboard.previewImage
        fillMode: Image.PreserveAspectFit
        asynchronous: true

        // decoded at the size it is shown, not the size it was copied at: a
        // screenshot of this display is 2560 wide and this box is not.
        sourceSize.height: Theme.clipPreviewImageHeight * 2
      }

      // until it is decoded, and if it cannot be: the design's own placeholder.
      Column {
        anchors.centerIn: parent

        visible: Clipboard.previewImage === ""
        spacing: Theme.clipPreviewFootGap

        Glyph {
          anchors.horizontalCenter: parent.horizontalCenter

          icon: "image"
          size: Theme.clipPreviewImageGlyph
          iconColor: Theme.notifDim
        }

        Text {
          anchors.horizontalCenter: parent.horizontalCenter

          text: root.row?.name ?? ""
          color: Theme.clipPreviewName
          font.family: Theme.monoFont
          font.pixelSize: Theme.clipPreviewNameSize
          font.weight: Font.Medium
        }
      }
    }

    Item {
      width: parent.width
      height: Math.max(meta.implicitHeight, enter.height)

      Text {
        id: meta

        anchors.left: parent.left
        anchors.right: enter.left
        anchors.rightMargin: Theme.clipPreviewFootGap
        anchors.verticalCenter: parent.verticalCenter

        // what is actually known: an image announces its size and type in the
        // listing, and text is measured once it has been decoded. the design also
        // names a mime type, which cliphist does not record.
        text: {
          if (root.kind === "image") return root.row?.detail ?? ""
          if (Clipboard.previewBytes === 0) return ""

          return `${Clipboard.previewBytes} B`
        }
        elide: Text.ElideRight
        color: Theme.clipPreviewMeta
        font.family: Theme.monoFont
        font.pixelSize: Theme.clipPreviewMetaSize
      }

      KeyCap {
        id: enter

        anchors.right: hint.left
        anchors.rightMargin: Theme.clipPreviewFootGap
        anchors.verticalCenter: parent.verticalCenter

        label: "ENTER"
      }

      Text {
        id: hint

        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter

        text: "copy"
        color: Theme.clipPreviewHint
        font.family: Theme.monoFont
        font.pixelSize: Theme.clipPreviewMetaSize
      }
    }
  }
}
