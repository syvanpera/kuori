import QtQuick
import qs.components
import qs.services
import qs.theme

// the battery row: how much is left and how long that is, then what the cell is
// actually like underneath and which profile the machine is running on.
PanelRow {
  id: root

  icon: Power.glyph
  label: "Battery"

  // there is no off state for a battery, and the design paints this one accent
  // whatever it is doing.
  lit: true
  value: Power.summary

  Meter {
    width: root.bodyWidth
    value: Power.level
  }

  // Limit and Cycles in the design have no source on this machine: nothing under
  // /sys exposes a charge threshold, and upower reports charge-cycles as N/A.
  // Health and Rate are both real here, and are the two readings worth the space.
  StatGrid {
    width: root.bodyWidth

    StatPair {
      width: parent.cell
      key: "Capacity"
      value: Power.capacity > 0 ? `${Math.round(Power.capacity)} Wh` : "--"
    }

    StatPair {
      width: parent.cell
      key: "Health"
      value: Power.healthKnown ? `${Math.round(Power.health)}%` : "--"
    }

    StatPair {
      width: parent.cell
      key: "Rate"
      value: Power.rate > 0 ? `${Power.rate.toFixed(1)} W` : "--"
    }

    StatPair {
      width: parent.cell
      key: "State"
      value: Power.stateText
    }
  }

  // the whole section stays away when no daemon answers, rather than offering
  // buttons that quietly do nothing.
  Column {
    width: root.bodyWidth
    visible: Power.hasPerformance
    spacing: Theme.sysBodyGap

    Rule {
      width: parent.width
    }

    Caption {
      text: "POWER PROFILE"
    }

    Row {
      id: profiles

      readonly property real cell: (profiles.width - Theme.sysProfileGap * (Power.profiles.length - 1)) / Power.profiles.length

      width: parent.width
      spacing: Theme.sysProfileGap

      Repeater {
        model: Power.profiles

        Rectangle {
          id: choice

          required property var modelData

          readonly property bool current: Power.profile === choice.modelData.profile

          width: profiles.cell
          height: label.implicitHeight + Theme.sysProfilePaddingV * 2

          radius: Theme.sysProfileRadius
          color: {
            if (hover.containsMouse) return Theme.sysNetHover
            return choice.current ? Theme.sysProfileOn : Theme.sysProfileOff
          }

          Behavior on color {
            ColorAnimation { duration: Theme.notchFadeDuration }
          }

          Text {
            id: label

            anchors.centerIn: parent

            text: choice.modelData.label
            color: choice.current ? Theme.text : Theme.sysValue
            font.family: Theme.monoFont
            font.pixelSize: Theme.sysProfileSize
            font.weight: Font.Medium
          }

          MouseArea {
            id: hover

            anchors.fill: parent
            hoverEnabled: true

            onClicked: Power.setProfile(choice.modelData.profile)
          }
        }
      }
    }
  }
}
