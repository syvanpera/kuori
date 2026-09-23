import QtQuick
import qs.components
import qs.services
import qs.theme

// the system panel's notification section: the do-not-disturb switch, and
// everything that has arrived since it was last cleared.
PanelRow {
  id: root

  icon: Notifications.dnd ? "notifications_off" : "notifications"
  label: "Notifications"

  value: Notifications.summary

  // the icon is accented unless the whole thing is muted, which is the only state
  // the collapsed row can show.
  lit: !Notifications.dnd

  SectionSwitch {
    width: root.bodyWidth
    label: "DO NOT DISTURB"
    checked: Notifications.dnd

    onToggled: Notifications.toggleDnd()
  }

  Rule {
    width: root.bodyWidth
  }

  Item {
    width: root.bodyWidth
    height: Math.max(historyLabel.implicitHeight, clear.implicitHeight)

    Caption {
      id: historyLabel

      anchors.left: parent.left
      anchors.verticalCenter: parent.verticalCenter

      text: "HISTORY"
    }

    Caption {
      id: clear

      anchors.right: parent.right
      anchors.verticalCenter: parent.verticalCenter

      // no confirmation, like the clipboard's wipe: what it throws away is a
      // record of things that have already happened.
      visible: Notifications.history.length > 0
      text: "CLEAR"
      color: clearHover.containsMouse ? Theme.notifClearHover : Theme.notifClear

      Behavior on color {
        ColorAnimation { duration: Theme.notchFadeDuration }
      }

      MouseArea {
        id: clearHover

        anchors.fill: parent
        hoverEnabled: true

        onClicked: Notifications.clear()
      }
    }
  }

  Text {
    visible: Notifications.history.length === 0

    text: "No notifications"
    color: Theme.notifEmpty
    font.family: Theme.uiFont
    font.variableAxes: Theme.uiAxesRegular
    font.pixelSize: Theme.notifEmptySize
  }

  // a bare ListView, not a Flickable in a ScrollView: it is already one, and it
  // builds only the delegates it can show.
  ListView {
    width: root.bodyWidth
    height: Math.min(contentHeight, Theme.notifListMax)

    visible: Notifications.history.length > 0
    model: Notifications.history
    spacing: Theme.notifEntryGap

    clip: true
    boundsBehavior: Flickable.StopAtBounds

    delegate: NotificationEntry {
      required property var modelData

      width: ListView.view.width
      entry: modelData
    }
  }
}
