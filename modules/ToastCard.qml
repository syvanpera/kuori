import QtQuick
import Quickshell
import Quickshell.Widgets
import Quickshell.Services.Notifications
import qs.components
import qs.services
import qs.theme

// one toast: who sent it, what it said, and whatever it wants you to do about it.
// it is handed the record the service keeps, not a Notification, so the only thing
// it ever calls into is the service.
Rectangle {
  id: root

  required property var popup

  // how far back in the stack this card sits. the design fades the ones behind the
  // first, which is what makes four cards read as a stack rather than a list.
  property int depth: 0

  readonly property var notification: root.popup?.notification ?? null

  // the image a client sent, already resolved by quickshell -- an icon name given
  // to notify-send arrives here as "image://icon/firefox", which Image can load.
  readonly property string image: root.notification?.image ?? ""

  // urgency is the only thing a notification says about itself that belongs in a
  // colour. the design colours each app differently, which it can do because it
  // knows its four mock apps by name.
  readonly property color accent: {
    if (root.notification?.urgency === NotificationUrgency.Critical) return Theme.urgent
    if (root.notification?.urgency === NotificationUrgency.Low) return Theme.notifDim

    return Theme.accent
  }

  width: Theme.toastWidth
  implicitHeight: body.implicitHeight + Theme.toastPaddingV * 2

  radius: Theme.toastRadius
  color: Theme.toastFill

  // the design's `0 0 0 1px rgba(255,255,255,.05)`, which is the only thing
  // separating a dark card from a dark desktop once the blur has softened both.
  border.width: 1
  border.color: Theme.pkOutline

  opacity: 1 - root.depth * Theme.toastFadeStep

  Row {
    id: body

    x: Theme.toastPaddingH
    y: Theme.toastPaddingV
    width: parent.width - Theme.toastPaddingH * 2

    spacing: Theme.toastRowGap

    ClippingRectangle {
      width: Theme.toastChipSize
      height: Theme.toastChipSize
      radius: Theme.toastChipRadius
      color: Theme.toastChipFill

      Image {
        anchors.fill: parent

        visible: root.image !== ""
        source: root.image
        fillMode: Image.PreserveAspectFit
        sourceSize.height: Theme.toastChipSize * 2
        asynchronous: true
      }

      Glyph {
        anchors.centerIn: parent

        // the fallback when a client sent no icon at all, which is most of them.
        visible: root.image === ""
        icon: "notifications"
        iconColor: root.accent
        size: Theme.toastChipIcon
      }
    }

    Column {
      width: parent.width - Theme.toastChipSize - Theme.toastRowGap
      spacing: Theme.toastTextGap

      Item {
        width: parent.width
        height: Math.max(app.implicitHeight, when.implicitHeight)

        Text {
          id: app

          anchors.left: parent.left
          anchors.right: when.left
          anchors.rightMargin: Theme.toastRowGap
          anchors.baseline: when.baseline

          text: root.notification?.appName ?? ""
          elide: Text.ElideRight
          color: Theme.tintBright
          font.family: Theme.monoFont
          font.pixelSize: Theme.toastAppSize
          font.weight: Font.Medium
        }

        Text {
          id: when

          anchors.right: parent.right

          // re-read every minute, which is what a toast's whole life is. passing
          // the clock in is what makes this a binding rather than a one-off.
          text: Notifications.ago(root.popup?.at ?? 0, Time.date)
          color: Theme.toastTime
          font.family: Theme.monoFont
          font.pixelSize: Theme.toastTimeSize
        }
      }

      Text {
        width: parent.width

        // the summary and the body are one sentence in the design, and the service
        // joins them before anything here sees them.
        text: Notifications.textOf(root.notification)

        // clients send pango markup whether or not a server claims to take it, and
        // StyledText understands the small subset the spec allows.
        textFormat: Text.StyledText
        wrapMode: Text.Wrap
        color: Theme.toastBody
        font.family: Theme.uiFont
        font.pixelSize: Theme.toastBodySize
        lineHeight: Theme.toastBodyLine
        lineHeightMode: Text.FixedHeight
      }

      Item {
        width: parent.width
        height: actions.implicitHeight + Theme.toastActionsTop
        visible: (root.notification?.actions?.length ?? 0) > 0

        Row {
          id: actions

          anchors.right: parent.right
          anchors.bottom: parent.bottom

          spacing: Theme.toastActionsGap

          Repeater {
            model: root.notification?.actions ?? []

            Rectangle {
              id: button

              required property int index
              required property var modelData

              // the design accents the first action and leaves the rest quiet: the
              // one a notification lists first is the one it wants you to take.
              readonly property bool primary: button.index === 0

              width: label.implicitWidth + Theme.toastActionPaddingH * 2
              height: label.implicitHeight + Theme.toastActionPaddingV * 2

              radius: Theme.toastActionRadius
              color: {
                if (button.primary) return hover.containsMouse ? Theme.toastPrimaryHover : Theme.toastPrimaryFill

                return hover.containsMouse ? Theme.toastActionHover : Theme.toastActionFill
              }

              Behavior on color {
                ColorAnimation { duration: Theme.notchFadeDuration }
              }

              Text {
                id: label

                anchors.centerIn: parent

                text: button.modelData.text
                color: button.primary ? Theme.accent : Theme.toastActionText
                font.family: Theme.uiFont
                font.pixelSize: Theme.toastActionSize
                font.variableAxes: Theme.uiAxesSemiBold
              }

              MouseArea {
                id: hover

                anchors.fill: parent
                hoverEnabled: true

                onClicked: Notifications.activate(root.popup.key, button.modelData)
              }
            }
          }
        }
      }
    }
  }

  // declared last so the buttons above answer first: a click on an action is not
  // also a click on the card.
  MouseArea {
    anchors.fill: parent
    z: -1

    onClicked: Notifications.dismiss(root.popup.key)
  }
}
