pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
import Quickshell.Services.Pam
import Quickshell.Wayland
import qs.services
import qs.theme

// the lock screen: whether the session is locked, what the prompt is doing, and
// everything that decides when it locks.
//
// three things lock it. the desktop sitting idle for Theme.lockIdle; the lid, a
// sleep or `loginctl lock-session`, which kuori-lockd reports from logind; and a
// keybind, over ipc. once locked, the screen goes off after Theme.lockBlank more
// of nobody touching anything, and comes back on the first key or movement.
//
// windows/LockScreen.qml owns the WlSessionLock itself, because a reloadable
// belongs in the root tree. this owns the flag it follows.
Singleton {
  id: root

  // the compositor is showing nothing but the lock.
  property bool locked: false

  // the lock screen on ordinary overlay windows, with nothing locked: how its
  // states are looked at without anybody's session being at stake. its password
  // field still talks to pam, so a wrong one is a real wrong one.
  property bool previewing: false

  readonly property bool shown: root.locked || root.previewing

  // the right answer arrived and the screen is fading back to the desktop.
  property bool leaving: false

  // WlSessionLock.secure: every output is covered. only then may a sleep that is
  // waiting on the lock go ahead.
  property bool secure: false

  // the design's resting state is the clock alone. the field comes up on the
  // first key or click, and escape puts it away again.
  property bool prompt: false

  // "", "busy" or "error".
  property string status: ""
  property string message: ""

  // bumped on each failure, so a second wrong password shakes the field again
  // rather than leaving it where the first one did.
  property int failures: 0

  property bool caps: false
  property bool revealed: false

  // the fingerprint line only appears once fprintd is actually listening. with
  // nothing enrolled pam_fprintd gives up at once and says nothing, and a line
  // offering a sensor that will never answer is worse than no line.
  property bool fingerReady: false
  property bool fingerMissed: false
  property int fingerMisses: 0
  property bool fingerOk: false

  // preview only: draw every screen as a secondary one, and caps lock as on
  // whatever the keyboard says.
  property bool previewSecondary: false
  property bool previewCaps: false

  // the screen the prompt is on: the one the keyboard is on.
  readonly property string primary: Screens.focused?.name ?? ""

  // the name on the prompt, from the passwd entry, and the initial on its tile.
  property string realName: Quickshell.env("USER") ?? ""
  readonly property string initial: root.realName.length > 0 ? root.realName[0].toUpperCase() : ""

  // this shell turned the screen off, and owes turning it back on.
  property bool blanked: false

  // the password waiting for pam to ask for it. pam asks after start(), not
  // before, so it has to sit somewhere for the length of one round trip.
  property var secret: null

  // a surface's field has text in it that the service needs gone: after a wrong
  // password, on escape, or for a preview scene that types something.
  signal fill(string text)

  function lock(reason: string): void {
    if (root.locked) {
      if (reason === "sleep") root.confirm()
      return
    }

    // a lock with no pam service behind it has no way back out of it but a tty.
    // that is a machine before its rebuild, or after a config change dropped the
    // service, and either way the lock that cannot open is the worse failure.
    pamService.reload()
    if (pamService.text().length === 0) {
      console.error(`lock: not locking (${reason}): /etc/pam.d/${password.config} is missing, and nothing could unlock it`)
      return
    }

    // a preview in the way of the real thing gives way to it.
    root.previewing = false
    root.reset()

    Launcher.close()
    Notches.close()
    Wallpapers.refresh()

    root.locked = true
    root.save()
    helper.tell("hint on")
    root.listen()

    console.info(`lock: locked (${reason})`)
  }

  // the lock is on every screen. a sleep held for it can go.
  function confirm(): void {
    if (root.locked && root.secure) helper.tell("locked")
  }

  function reset(): void {
    root.leaving = false
    root.prompt = false
    root.status = ""
    root.message = ""
    root.revealed = false
    root.secret = null
    root.fingerReady = false
    root.fingerMissed = false
    root.fingerOk = false
    root.previewSecondary = false
    root.previewCaps = false
    root.fill("")
    root.probeCaps()
  }

  function rest(): void {
    if (root.leaving) return

    if (!root.prompt && root.previewing) {
      root.endPreview()
      return
    }

    root.prompt = false
    root.status = ""
    root.message = ""
    root.revealed = false
    root.fill("")
  }

  function submit(text: string): void {
    if (text.length === 0 || root.status === "busy" || root.leaving) return

    root.secret = text
    root.status = "busy"
    root.message = ""

    if (!password.start()) root.fail("Could not start authentication.")
  }

  function fail(text: string): void {
    password.abort()
    root.secret = null
    root.status = "error"
    root.message = text
    root.prompt = true
    root.failures += 1
    root.fill("")
  }

  function unlock(): void {
    if (root.leaving) return

    root.leaving = true
    root.secret = null
    password.abort()
    finger.abort()
    fingerRetry.stop()
    leave.restart()
  }

  // one conversation for the password and another for a finger, side by side. a
  // single pam stack asks them in turn, and pam_fprintd waits up to half a minute
  // for a finger before the password is ever read.
  function listen(): void {
    root.fingerReady = false
    root.fingerOk = false
    fingerRetry.stop()
    finger.abort()
    finger.start()
  }

  function preview(scene: string): void {
    if (root.locked) return

    if (scene === "close") {
      root.endPreview()
      return
    }

    if (!root.previewing) {
      Launcher.close()
      Notches.close()
      Wallpapers.refresh()
      root.previewing = true
      root.listen()
    }

    root.reset()

    switch (scene) {
    case "typing":
      root.prompt = true
      root.fill("hunter")
      break
    case "verifying":
      root.prompt = true
      root.fill("hunter22")
      root.status = "busy"
      break
    case "wrong":
      root.fail("Authentication failure.")
      break
    case "long":
      root.fail("The account is locked due to 3 failed logins. It will unlock in 9 minutes 42 seconds, or ask your administrator to run faillock --reset.")
      break
    case "caps":
      root.prompt = true
      root.fill("HUNT")
      root.previewCaps = true
      root.caps = true
      break
    case "finger":
      root.prompt = true
      root.fingerReady = true
      break
    case "fingerfail":
      root.prompt = true
      root.fingerReady = true
      root.missed()
      break
    case "fingerok":
      root.prompt = true
      root.fingerReady = true
      root.fingerOk = true
      break
    case "secondary":
      root.previewSecondary = true
      break
    }
  }

  // a preview that goes away takes its conversations with it, or fprintd goes on
  // holding the reader for a lock that is not there.
  function endPreview(): void {
    root.previewing = false
    root.secret = null
    password.abort()
    finger.abort()
    fingerRetry.stop()
  }

  function missed(): void {
    root.prompt = true
    root.fingerMissed = true
    root.fingerMisses += 1
    fingerHold.restart()
  }

  // the state file is what lets a crashed or reloaded shell lock again before
  // anyone gets to the desktop. hyprland keeps the session locked when its lock
  // client dies (misc:allow_session_lock_restore lets the next one take over),
  // but a new shell starts with locked false and would release it. the boot id
  // keeps a lock from surviving a reboot, where it would only be in the way.
  function save(): void {
    state.setText(JSON.stringify({ locked: root.locked, boot: bootId.text().trim() }))
  }

  // the screen, off and on. hyprland's dispatch is the whole of it -- and
  // `hl.dsp.dpms()` with no argument is a toggle, which is not what anything here
  // ever means.
  function blank(): void {
    if (root.blanked) return

    root.blanked = true
    Hyprland.dispatch(`hl.dsp.dpms({ action = "off" })`)
  }

  function wake(): void {
    if (!root.blanked) return

    root.blanked = false
    Hyprland.dispatch(`hl.dsp.dpms({ action = "on" })`)
  }

  // qt reports no lock keys, and hyprland does: every keyboard it knows carries
  // its own capsLock. asked on each key, a beat after the last one, rather than on
  // a timer that would run all the while the screen is locked.
  function probeCaps(): void {
    capsSettle.restart()
  }

  function heard(event: var): void {
    if (event.type === "ready") {
      // a lock restored at startup was taken before the helper was listening.
      if (root.locked) helper.tell("hint on")
    } else if (event.type === "lock") {
      root.lock(event.reason)
    } else if (event.type === "wake") {
      // hyprland brings the outputs back on resume, and the reader may have gone
      // away under a conversation that is still waiting on it.
      root.blanked = false
      if (root.shown && !root.leaving) root.listen()
    }
  }

  // what the fade is for. the lock comes off when it has finished rather than
  // when it starts, so the desktop is never seen through a half-drawn prompt.
  Timer {
    id: leave

    interval: Theme.lockExit + 30

    onTriggered: {
      const wasLocked = root.locked

      root.locked = false
      root.previewing = false
      root.reset()
      root.wake()

      if (wasLocked) {
        root.save()
        helper.tell("hint off")
        console.info("lock: unlocked")
      }
    }
  }

  Timer {
    id: capsSettle

    interval: Theme.lockCapsDelay

    onTriggered: capsProbe.running = true
  }

  Process {
    id: capsProbe

    command: ["hyprctl", "devices", "-j"]

    stdout: StdioCollector {
      id: capsReply

      onStreamFinished: {
        try {
          const keyboards = JSON.parse(capsReply.text).keyboards ?? []
          const main = keyboards.find(keyboard => keyboard.main) ?? null

          root.caps = root.previewCaps || (main ? main.capsLock === true : keyboards.some(keyboard => keyboard.capsLock === true))
        } catch (err) {
          root.caps = root.previewCaps
        }
      }
    }
  }

  // idle, then locked, then dark. both respect inhibitors: a video playing or
  // stay awake switched on keeps the screen as it is, locked or not.
  IdleMonitor {
    id: idle

    enabled: !root.shown && Theme.lockIdle > 0
    timeout: Theme.lockIdle
    respectInhibitors: true

    onIsIdleChanged: if (idle.isIdle) root.lock("idle")
  }

  IdleMonitor {
    id: dark

    enabled: root.locked && !root.leaving && Theme.lockBlank > 0
    timeout: Theme.lockBlank
    respectInhibitors: true

    onIsIdleChanged: {
      if (dark.isIdle) root.blank()
      else root.wake()
    }
  }

  PamContext {
    id: password

    config: "kuori"

    onResponseRequiredChanged: {
      if (!password.responseRequired) return

      // pam asking a second question would be asking something the prompt has no
      // way to put to anyone -- a new password, an otp. better said than guessed.
      if (root.secret === null) {
        root.fail(password.message || "Authentication needs more than a password.")
        return
      }

      password.respond(root.secret)
      root.secret = null
    }

    onCompleted: result => {
      if (result === PamResult.Success) {
        root.unlock()
        return
      }

      if (result === PamResult.MaxTries) {
        root.fail("Too many attempts.")
        return
      }

      // pam_unix says nothing on a wrong password; faillock and friends do, and
      // what they say is the thing worth reading.
      root.fail(password.messageIsError && password.message.length > 0 ? password.message : "Authentication failure.")
    }

    onError: error => root.fail(`Could not check the password: ${PamError.toString(error)}.`)
  }

  PamContext {
    id: finger

    config: "kuori-fingerprint"

    // pam_fprintd talks in info and error messages and never asks for anything.
    // "place your finger" is the reader listening; an error is a finger it did not
    // know.
    // a miss is "Failed to match fingerprint" as an error, followed at once by
    // the next "place your finger"; "Verification timed out" is info.
    onPamMessage: {
      if (finger.messageIsError) root.missed()
      else root.fingerReady = true
    }

    // anything that does ask is not a fingerprint reader, and has no field here.
    onResponseRequiredChanged: if (finger.responseRequired) finger.abort()

    onCompleted: result => {
      // a finger on the sensor is an answer like a key is, and its answer is only
      // seen if the prompt is up to show it.
      if (result === PamResult.Success) {
        root.fingerOk = true
        root.prompt = true
        fingerUnlock.restart()
        return
      }

      // a reader that was listening and gave up -- three misses, or thirty
      // seconds of nothing -- is asked again. one that never started listening
      // has nothing enrolled, or no reader, and is left alone until next time.
      if (root.fingerReady && root.shown && !root.leaving) fingerRetry.restart()
      else root.fingerReady = false
    }

    onError: root.fingerReady = false
  }

  Timer {
    id: fingerRetry

    interval: Theme.lockFingerRetry

    onTriggered: if (root.shown && !root.leaving) finger.start()
  }

  // the design's "fingerprint recognised" is there to be read before it goes.
  Timer {
    id: fingerUnlock

    interval: Theme.lockFingerOk

    onTriggered: root.unlock()
  }

  Timer {
    id: fingerHold

    interval: Theme.lockFingerHold

    onTriggered: root.fingerMissed = false
  }

  Helper {
    id: helper

    script: "kuori-lockd"
    name: "lock helper"

    onEvent: message => root.heard(message)
  }

  Process {
    id: passwd

    command: ["getent", "passwd", Quickshell.env("USER") ?? ""]
    running: true

    stdout: StdioCollector {
      id: passwdReply

      onStreamFinished: {
        // the gecos field is "Full Name,room,phone,..." and only the name is a name.
        const gecos = (passwdReply.text.split(":")[4] ?? "").split(",")[0].trim()

        if (gecos.length > 0) root.realName = gecos
      }
    }
  }

  FileView {
    id: pamService

    path: `/etc/pam.d/${password.config}`
    blockLoading: true
    printErrors: false
  }

  FileView {
    id: bootId

    path: "/proc/sys/kernel/random/boot_id"
    blockLoading: true
  }

  // read before anything binds to `locked`: blockLoading makes the read happen as
  // the path is set, so a reloaded shell comes up already locked instead of
  // releasing the lock for a frame and taking it back.
  FileView {
    id: state

    path: Quickshell.statePath("lock.json")
    blockLoading: true
    blockWrites: true

    // a machine that has never locked has no file, and that is not news.
    printErrors: false
  }

  Component.onCompleted: {
    let saved = {}

    try {
      saved = JSON.parse(state.text() || "{}")
    } catch (err) {
      saved = {}
    }

    if (saved.locked === true && saved.boot === bootId.text().trim()) {
      root.locked = true
      root.listen()
      console.info("lock: still locked from before the restart")
    }
  }
}
