import Quickshell
import Quickshell.Wayland
import QtQuick
import qs.modules
import qs.services

// the lock, and a way of looking at it without being locked.
//
// the lock is ext-session-lock: while it holds, hyprland draws nothing but these
// surfaces, one per output, and gives them the keyboard. it is not a window on
// top of the desktop, and killing the shell does not reveal anything -- hyprland
// keeps the session locked until another client takes the lock over, which with
// misc:allow_session_lock_restore is the shell restarting and reading its state
// file.
Scope {
  id: root

  WlSessionLock {
    id: session

    locked: Lock.locked

    onSecureChanged: {
      Lock.secure = session.secure
      Lock.confirm()
    }

    WlSessionLockSurface {
      id: surface

      // the surface fades on the way out, and what shows through it is whatever
      // hyprland draws under a lock.
      color: "transparent"

      LockSurface {
        anchors.fill: parent
        screenName: surface.screen?.name ?? ""
      }
    }
  }

  // the preview: the same surface on an overlay window per screen. overlay rather
  // than top, and taking the keyboard on the screen with the prompt, so it
  // behaves like the lock in every way but the one that matters.
  Variants {
    model: Lock.previewing ? Quickshell.screens : []

    PanelWindow {
      id: preview

      required property var modelData

      screen: preview.modelData

      anchors {
        top: true
        bottom: true
        left: true
        right: true
      }

      exclusionMode: ExclusionMode.Ignore
      color: "transparent"

      WlrLayershell.layer: WlrLayer.Overlay
      WlrLayershell.namespace: "qs-lock-preview"
      WlrLayershell.keyboardFocus: preview.modelData.name === Lock.primary ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

      LockSurface {
        anchors.fill: parent
        screenName: preview.modelData.name
      }
    }
  }
}
