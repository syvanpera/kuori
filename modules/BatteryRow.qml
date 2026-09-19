import QtQuick
import Quickshell.Services.UPower
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
  Grid {
    width: root.bodyWidth

    columns: 2
    columnSpacing: Theme.sysStatGapH
    rowSpacing: Theme.sysStatGapV

    readonly property real cell: (width - Theme.sysStatGapH) / 2

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

  // power-profiles-daemon is not installed on this machine, so the whole section
  // stays away rather than offering buttons that quietly do nothing.
  Column {
    width: root.bodyWidth
    visible: Power.profilesAvailable
    spacing: Theme.sysBodyGap

    Rectangle {
      width: parent.width
      height: 1
      color: Theme.sysLine
    }

    Text {
      text: "POWER PROFILE"
      color: Theme.sysCap
      font.family: Theme.monoFont
      font.pixelSize: Theme.sysCapSize
      font.weight: Font.Medium
      font.letterSpacing: Theme.sysCapSpacing
    }

    Row {
      id: profiles

      width: parent.width
      spacing: Theme.sysProfileGap

      // performance is not offered on every machine, and a button that cannot be
      // chosen is worse than one that is not there.
      readonly property var choices: {
        const all = [
          { label: "Power-saver", profile: PowerProfile.PowerSaver },
          { label: "Balanced", profile: PowerProfile.Balanced },
          { label: "Performance", profile: PowerProfile.Performance }
        ]

        return Power.hasPerformance ? all : all.filter(c => c.profile !== PowerProfile.Performance)
      }

      readonly property real cell: (width - Theme.sysProfileGap * (choices.length - 1)) / choices.length

      Repeater {
        model: profiles.choices

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
