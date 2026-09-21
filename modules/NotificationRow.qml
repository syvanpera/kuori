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

  // the design's three states, in its own words.
  value: {
    if (Notifications.dnd) return "Silenced"
    if (Notifications.history.length === 0) return "None"

    return `${Notifications.history.length} recent`
  }

  // the icon is accented unless the whole thing is muted, which is the only state
  // the collapsed row can show.
  lit: !Notifications.dnd

  // opening the section is what counts as having seen it, and the bell on the
  // strip goes out.
  onExpandedChanged: if (root.expanded) Notifications.markSeen()

  Column {
    width: root.bodyWidth
    spacing: Theme.sysBodyGap

    Item {
      width: parent.width
      height: Math.max(dndLabel.implicitHeight, dnd.height)

      Text {
        id: dndLabel

        anchors.left: parent.left
        anchors.verticalCenter: parent.verticalCenter

        text: "DO NOT DISTURB"
        color: Theme.sysCap
        font.family: Theme.monoFont
        font.pixelSize: Theme.sysCapSize
        font.weight: Font.Medium
        font.letterSpacing: Theme.sysCapSpacing
      }

      Switch {
        id: dnd

        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter

        checked: Notifications.dnd

        onToggled: Notifications.toggleDnd()
      }
    }

    Rectangle {
      width: parent.width
      height: 1
      color: Theme.sysLine
    }

    Item {
      width: parent.width
      height: Math.max(historyLabel.implicitHeight, clear.implicitHeight)

      Text {
        id: historyLabel

        anchors.left: parent.left
        anchors.verticalCenter: parent.verticalCenter

        text: "HISTORY"
        color: Theme.sysCap
        font.family: Theme.monoFont
        font.pixelSize: Theme.sysCapSize
        font.weight: Font.Medium
        font.letterSpacing: Theme.sysCapSpacing
      }

      Text {
        id: clear

        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter

        // no confirmation, like the clipboard's wipe: what it throws away is a
        // record of things that have already happened.
        visible: Notifications.history.length > 0
        text: "CLEAR"
        color: clearHover.containsMouse ? Theme.notifClearHover : Theme.notifClear
        font.family: Theme.monoFont
        font.pixelSize: Theme.sysCapSize
        font.weight: Font.Medium
        font.letterSpacing: Theme.sysCapSpacing

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
      font.pixelSize: Theme.notifEmptySize
    }

    // a bare ListView, not a Flickable in a ScrollView: it is already one, and it
    // builds only the delegates it can show.
    ListView {
      width: parent.width
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
}
