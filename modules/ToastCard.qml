import QtQuick
import qs.components
import qs.services
import qs.theme

// one toast: who sent it, what it said, and whatever it wants you to do about it.
// it is handed the record the service keeps, not a Notification, so the only thing
// it ever calls into is the service.
ToastFrame {
  id: root

  required property var popup

  // how far back in the stack this card sits. the design fades the ones behind the
  // first, which is what makes four cards read as a stack rather than a list.
  property int depth: 0

  readonly property var notification: root.popup?.notification ?? null

  // the image a client sent, already resolved by quickshell -- an icon name given
  // to notify-send arrives here as "image://icon/firefox", which Image can load.
  readonly property string image: root.notification?.image ?? ""

  readonly property color accent: Notifications.urgencyColour(root.notification?.urgency ?? -1, root.notification?.hints?.["x-kuori-tone"] ?? "")

  app: root.notification?.appName ?? ""

  // re-read every minute, which is what a toast's whole life is. passing the clock
  // in is what makes this a binding rather than a one-off.
  when: Time.ago(root.popup?.at ?? 0, Time.date)

  opacity: 1 - root.depth * Theme.toastFadeStep

  onClicked: Notifications.dismiss(root.popup.key)

  tile: [
    Image {
      anchors.fill: parent

      visible: root.image !== ""
      source: root.image
      fillMode: Image.PreserveAspectFit
      // logical pixels; qt scales for the screen itself. both sides, because the
      // image://icon provider takes a height alone as a width of nothing and hands
      // back a 2x2 pixmap -- which every icon and screenshot toast was drawn from.
      // with both, it fits the picture inside the square and keeps its shape.
      sourceSize.width: Theme.toastChipSize
      sourceSize.height: Theme.toastChipSize
      asynchronous: true
    },

    Glyph {
      anchors.centerIn: parent

      // the fallback when a client sent no icon at all, which is most of them. this
      // shell's own notifications can name a material symbol instead, through a
      // vendor hint, so a device toast wears the glyph its panel row does.
      visible: root.image === ""
      icon: root.notification?.hints?.["x-kuori-glyph"] ?? "notifications"
      iconColor: root.accent
      size: Theme.toastChipIcon
    }
  ]

  ToastFrame.BodyText {
    // the summary and the body are one sentence in the design, and the service
    // joins them before anything here sees them.
    text: Notifications.textOf(root.notification)

    // clients send pango markup whether or not a server claims to take it, and
    // StyledText understands the small subset the spec allows.
    textFormat: Text.StyledText
  }

  Item {
    width: parent.width
    height: actions.implicitHeight + Theme.toastActionsTop
    visible: (root.notification?.actions?.length ?? 0) > 0

    // a Flow, not a Row: a client may send as many actions as it likes, and a row
    // of them only grows leftwards, over the icon and then off the card, where the
    // surface cuts it. these wrap instead. the flow is as wide as the buttons in
    // one line, up to the card, so a line that fits sits on the right as before --
    // a right-to-left flow would do that too, and put the first action last.
    Flow {
      id: actions

      // bumped per button made, so the sum below is taken again once each exists.
      property int built: 0

      readonly property real natural: {
        let width = Math.max(0, repeater.count - 1) * actions.spacing
        for (let i = 0; i < actions.built && i < repeater.count; i++) width += repeater.itemAt(i)?.implicitWidth ?? 0
        return width
      }

      anchors.right: parent.right
      anchors.bottom: parent.bottom
      width: Math.min(parent.width, actions.natural)

      spacing: Theme.toastActionsGap

      Repeater {
        id: repeater

        model: root.notification?.actions ?? []

        onItemAdded: actions.built += 1

        PillButton {
          id: button

          required property int index
          required property var modelData

          // the design accents the first action and leaves the rest quiet: the
          // one a notification lists first is the one it wants you to take.
          readonly property bool primary: button.index === 0

          width: Math.min(button.implicitWidth, actions.width)

          label: button.modelData.text
          fill: button.primary ? Theme.toastPrimaryFill : Theme.toastActionFill
          hoverFill: button.primary ? Theme.toastPrimaryHover : Theme.toastActionHover
          textColor: button.primary ? Theme.accent : Theme.toastActionText
          textSize: Theme.toastActionSize
          paddingH: Theme.toastActionPaddingH
          paddingV: Theme.toastActionPaddingV
          radius: Theme.toastActionRadius

          onClicked: Notifications.activate(root.popup.key, button.modelData)
        }
      }
    }
  }
}
