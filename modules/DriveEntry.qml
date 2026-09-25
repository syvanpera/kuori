import QtQuick
import qs.components
import qs.services
import qs.theme

// one drive in the drives row: what it is, how full, and whatever it needs from
// you -- the folder and eject buttons while it is mounted, a choice while
// something holds it busy, a passphrase while it is locked.
Rectangle {
  id: root

  // the row this card is showing, looked up by the id its delegate was made for.
  property var drive: ({})

  // whether the row this card is in is folded out: a locked drive takes the
  // keyboard for its passphrase only then.
  property bool shown: false

  readonly property string st: root.drive.st
  readonly property bool locked: root.st === "locked" || root.st === "unlocking"
  readonly property bool actionable: root.st === "mounted" || root.st === "unmounted"

  // the panel's keyboard lands on the card, and return does its main thing: open
  // it, or go to the passphrase.
  readonly property bool keyTarget: true
  property bool keyed: false

  function press(): void {
    if (root.st === "unmounted") Drives.mount(root.drive.id)
    else if (root.actionable) Drives.open(root.drive.id)
    else root.takeFocus()
  }

  function takeFocus(): void {
    lock.item?.take()
  }

  // the design writes sizes in GB, and its 29.4 for a 32 GB stick is binary.
  function gb(bytes: real): string {
    return `${(bytes / 1024 ** 3).toFixed(1)} GB`
  }

  readonly property string sub: {
    const drive = root.drive

    switch (root.st) {
      // the design's sentence, unless the helper could tell who: then it names them.
      case "busy": {
        const holders = drive.holders ?? []
        if (holders.length === 0) return `Target is busy. Close files open on ${drive.label} and try again.`

        const who = holders.length === 1
          ? holders[0]
          : `${holders.slice(0, -1).join(", ")} and ${holders[holders.length - 1]}`
        const have = holders.length === 1 ? "has" : "have"
        return `${who} ${have} files open on ${drive.label}. Close them and try again.`
      }
      case "unlocking": return "Unlocking…"
      case "locked": return `Encrypted · ${drive.crypto} · ${root.gb(drive.size)}`
      // past a moment it is the kernel writing out what was copied, and that is
      // worth saying: pulling the drive now is what loses it. not in the design.
      case "unmounting":
        if (drive.flushing) return "Writing data… Don't unplug"
        return drive.encrypted ? "Unmounting and locking…" : "Unmounting…"
      case "safe": return "Safe to remove"
      case "mounting": return "Mounting…"
      // not in the design, which only has drives it mounted itself: one already
      // plugged in when the shell started is left as it was found, and one ejected
      // stays here, unmounted, until it is pulled out.
      case "unmounted": return `Not mounted · ${root.gb(drive.size)} · ${drive.fs}`
    }

    const luks = drive.encrypted ? " · LUKS" : ""
    return `${root.gb(drive.size - drive.used)} free of ${root.gb(drive.size)} · ${drive.fs}${luks}`
  }

  width: parent?.width ?? 0
  implicitHeight: column.implicitHeight + Theme.drvCardPaddingV * 2

  radius: Theme.drvCardRadius
  color: Theme.drvCard
  opacity: root.st === "safe" ? Theme.drvSafeOpacity : 1

  Behavior on opacity {
    NumberAnimation { duration: Theme.controlMoveDuration }
  }

  KeyWash {
    shown: root.keyed
    inset: 0
    radius: root.radius
  }

  Column {
    id: column

    x: Theme.drvCardPaddingH
    y: Theme.drvCardPaddingV
    width: parent.width - Theme.drvCardPaddingH * 2
    spacing: Theme.drvCardGap

    Item {
      width: parent.width
      height: Math.max(texts.implicitHeight, Theme.drvActionSize)

      Glyph {
        id: icon

        anchors.verticalCenter: parent.verticalCenter

        size: Theme.drvIcon
        icon: {
          if (root.st === "safe") return "check_circle"
          return root.locked ? "lock" : root.drive.glyph
        }
        iconColor: {
          if (root.st === "busy") return Theme.drvBusy
          return root.locked ? Theme.drvLockedIcon : Theme.accent
        }
      }

      Column {
        id: texts

        anchors.left: icon.right
        anchors.leftMargin: Theme.drvRowGap
        anchors.right: side.left
        anchors.rightMargin: side.width > 0 ? Theme.drvRowGap : 0
        anchors.verticalCenter: parent.verticalCenter
        spacing: Theme.drvTextGap

        Text {
          width: parent.width

          text: root.drive.name
          color: Theme.drvName
          elide: Text.ElideRight
          font.family: Theme.monoFont
          font.pixelSize: Theme.drvNameSize
          font.weight: Font.Medium
        }

        Text {
          width: parent.width

          text: root.sub
          color: {
            if (root.st === "busy") return Theme.drvBusy
            if (["unmounting", "mounting", "safe", "unlocking"].includes(root.st)) return Theme.accent
            return Theme.drvSub
          }
          wrapMode: Text.Wrap
          font.family: Theme.monoFont
          font.pixelSize: Theme.drvSubSize
          lineHeightMode: Text.FixedHeight
          lineHeight: Theme.drvSubLine
        }
      }

      // the buttons, or the spinner while it unmounts. one slot on the right, so
      // the text beside it never has to know which is there.
      Item {
        id: side

        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        width: {
          if (root.actionable) return buttons.width
          return spinner.visible ? spinner.width : 0
        }
        height: Theme.drvActionSize

        Row {
          id: buttons

          visible: root.actionable
          spacing: Theme.drvActionGap

          IconButton {
            width: Theme.drvActionSize
            height: Theme.drvActionSize
            radius: Theme.drvActionRadius

            icon: "folder_open"
            iconSize: Theme.drvActionIcon
            iconColor: Theme.drvOpenGlyph
            fill: Theme.drvOpenFill
            hoverFill: Theme.drvOpenHover

            onClicked: Drives.open(root.drive.id)
          }

          // an unmounted drive has nothing left to eject, unless ejecting would
          // power it off.
          IconButton {
            visible: root.st === "mounted" || Theme.drvPowerOff
            width: Theme.drvActionSize
            height: Theme.drvActionSize
            radius: Theme.drvActionRadius

            icon: "eject"
            iconSize: Theme.drvActionIcon
            iconColor: Theme.accent
            fill: Theme.drvEjectFill
            hoverFill: Theme.drvEjectHover

            onClicked: Drives.eject(root.drive.id, false)
          }
        }

        Glyph {
          id: spinner

          anchors.right: parent.right
          anchors.verticalCenter: parent.verticalCenter
          visible: root.st === "unmounting" || root.st === "mounting"

          size: Theme.drvIcon
          icon: "progress_activity"
          iconColor: Theme.accent

          RotationAnimation on rotation {
            running: spinner.visible
            loops: Animation.Infinite
            from: 0
            to: 360
            duration: Theme.noteSpin
            onStopped: spinner.rotation = 0
          }
        }
      }
    }

    Meter {
      width: parent.width
      implicitHeight: Theme.drvBarHeight
      radius: Theme.drvBarRadius
      color: Theme.drvRail

      value: root.locked || root.drive.size <= 0 ? 0 : root.drive.used / root.drive.size
      tint: root.st === "safe" ? Theme.drvBarSafe : Theme.accent
    }

    // not mounted: the design has no such card, and a folder button that quietly
    // mounts first was too clever by half. Mount sits where a locked card's
    // Unlock does.
    Row {
      anchors.right: parent.right
      visible: root.st === "unmounted"
      spacing: Theme.drvButtonGap

      PillButton {
        label: "Mount"
        fill: Theme.drvEjectFill
        hoverFill: Theme.drvEjectHover
        textColor: Theme.accent
        textSize: Theme.drvButtonSize
        paddingH: Theme.drvButtonPaddingH
        paddingV: Theme.drvButtonPaddingV
        radius: Theme.drvButtonRadius

        onClicked: Drives.mount(root.drive.id)
      }
    }

    // something has a file open on it: leave it, or pull it out from under them.
    Row {
      anchors.right: parent.right
      visible: root.st === "busy"
      spacing: Theme.drvButtonGap

      PillButton {
        label: "Keep mounted"
        fill: Theme.drvQuietFill
        hoverFill: Theme.drvQuietHover
        textColor: Theme.drvQuietText
        textSize: Theme.drvButtonSize
        paddingH: Theme.drvButtonPaddingH
        paddingV: Theme.drvButtonPaddingV
        radius: Theme.drvButtonRadius

        onClicked: Drives.keep(root.drive.id)
      }

      PillButton {
        label: "Unmount anyway"
        fill: Theme.drvForceFill
        hoverFill: Theme.drvForceHover
        textColor: Theme.drvBusy
        textSize: Theme.drvButtonSize
        paddingH: Theme.drvButtonPaddingH
        paddingV: Theme.drvButtonPaddingV
        radius: Theme.drvButtonRadius

        onClicked: Drives.eject(root.drive.id, true)
      }
    }

    // loaded only while locked. a field that held the keyboard and was merely
    // hidden would keep it from everything else, and one destroyed hands it back.
    Loader {
      id: lock

      width: parent.width
      active: root.locked

      // a Loader keeps the size of the last item it held after that item is gone,
      // and a visible one still takes the column's spacing: without these an
      // unlocked card kept the whole height of the field under it, empty.
      visible: lock.active
      height: lock.item ? lock.item.implicitHeight : 0

      sourceComponent: Column {
        id: unlocker

        // the eye's choice, per drive and only while it is locked.
        property bool revealed: false

        // the wrong tries already answered with a shake.
        property int shook: 0

        function take(): void {
          field.take()
        }

        function tryIt(): void {
          Drives.unlock(root.drive.id, field.text)
        }

        spacing: Theme.drvCardGap

        Component.onCompleted: {
          unlocker.shook = root.drive.errN
          if (root.shown) field.take()
        }

        // the frame's key sink is what hears escape once this is gone, and it will
        // not take the keyboard back on its own.
        Component.onDestruction: Notches.refocus()

        SecretField {
          id: field

          width: parent.width

          fieldHeight: Theme.drvFieldHeight
          fieldRadius: Theme.drvFieldRadius
          paddingH: Theme.drvFieldPaddingH
          iconGap: Theme.drvFieldIconGap
          glyphSize: Theme.drvFieldGlyph
          textSize: Theme.drvFieldSize
          eyeSize: Theme.drvEyeSize

          placeholder: "Passphrase"
          revealed: unlocker.revealed
          busy: root.st === "unlocking"
          busyBorder: Theme.drvFieldBusyBorder
          busyOpacity: Theme.drvInputBusyOpacity
          errored: root.drive.err !== ""

          onRevealToggled: unlocker.revealed = !unlocker.revealed
          onKeyPressed: Drives.retyping(root.drive.id)
          onAccepted: unlocker.tryIt()
          onEscaped: Notches.refocus()
        }

        StatusNote {
          width: parent.width
          visible: root.drive.err !== ""

          icon: "error"
          text: root.drive.err
          shade: Theme.drvBusy
          wraps: true
          line: Theme.drvNoteLine
        }

        Row {
          anchors.right: parent.right
          spacing: Theme.drvButtonGap

          PillButton {
            label: "Eject"
            fill: Theme.drvQuietFill
            hoverFill: Theme.drvQuietHover
            textColor: Theme.drvQuietText
            textSize: Theme.drvButtonSize
            paddingH: Theme.drvButtonPaddingH
            paddingV: Theme.drvButtonPaddingV
            radius: Theme.drvButtonRadius

            onClicked: Drives.eject(root.drive.id, false)
          }

          PillButton {
            label: "Unlock"
            fill: Theme.drvEjectFill
            hoverFill: Theme.drvEjectHover
            textColor: Theme.accent
            textSize: Theme.drvButtonSize
            paddingH: Theme.drvButtonPaddingH
            paddingV: Theme.drvButtonPaddingV
            radius: Theme.drvButtonRadius
            opacity: field.text !== "" && root.st !== "unlocking" ? 1 : Theme.drvUnlockDisabledOpacity

            onClicked: unlocker.tryIt()
          }
        }

        // a wrong passphrase empties the field and shakes it, as the lock does.
        Connections {
          target: root

          function onDriveChanged(): void {
            if (root.drive.errN !== unlocker.shook) {
              unlocker.shook = root.drive.errN
              field.setText("")
              field.shake()
              field.take()
            }
          }
        }
      }
    }
  }
}
