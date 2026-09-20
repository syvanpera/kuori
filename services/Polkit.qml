pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

// what the shell is being asked to authenticate, if anything.
//
// the dialog never imports Quickshell.Services.Polkit. it draws whatever
// flow-shaped object this hands it, which is what lets the whole card be built
// and checked against a mock while hyprpolkitagent is still doing the real work.
// the real PolkitAgent goes in here and nowhere else.
Singleton {
  id: root

  // the flow being authenticated, or null. a flow carries:
  //
  //   message, actionId, cookie          what is being asked and by whom
  //   identities, selectedIdentity       who may answer
  //   isResponseRequired, inputPrompt    what pam wants typed, and what to call it
  //   responseVisible                    whether pam wants it echoed
  //   supplementaryMessage/IsError       what pam said about the last attempt
  //   isCompleted/isSuccessful/isCancelled/failed
  //   submit(value), cancelAuthenticationRequest()
  //
  // AuthFlow cannot be constructed and its request/showError methods are private
  // slots, so a mock cannot be a real one -- it has to be a separate object of
  // the same shape. hence `var` rather than a type.
  readonly property var flow: root.mocking ? mock : null

  // whether the mock is standing in for a real request. driven over ipc so every
  // state can be walked from the command line without touching anyone's password.
  property bool mocking: false

  function raise(): void {
    mock.reset()
    root.mocking = true
  }

  function dismiss(): void {
    root.mocking = false
  }

  // the states the design draws, reachable by name for screenshotting.
  QtObject {
    id: mock

    property string message: "An application is attempting to perform an action that requires privileges. Authentication as the super user is required to perform this action."
    property string actionId: "org.freedesktop.systemd1.manage-units"
    property string cookie: "mock-cookie-0000"

    property var identities: [mock.identity]
    property var selectedIdentity: mock.identity

    property bool isResponseRequired: true
    property string inputPrompt: "Password: "
    property bool responseVisible: false

    property string supplementaryMessage: ""
    property bool supplementaryIsError: false

    property bool isCompleted: false
    property bool isSuccessful: false
    property bool isCancelled: false
    property bool failed: false

    // a plain js object rather than a QtObject: polkit's Identity carries a
    // property called "string", and a qml property cannot be declared with a type
    // keyword for a name. the dialog reads it the same either way.
    readonly property var identity: ({
      id: 1000,
      string: "unix-user:tuomo",
      displayName: "tuomo",
      isGroup: false
    })

    function reset(): void {
      mock.isResponseRequired = true
      mock.supplementaryMessage = ""
      mock.supplementaryIsError = false
      mock.isCompleted = false
      mock.isSuccessful = false
      mock.isCancelled = false
      mock.failed = false
    }

    // pam stops asking while it is thinking, which is the only signal a real flow
    // gives that something is in flight. the mock does the same rather than
    // inventing a busy flag the dialog would then have to know about.
    function submit(value: string): void {
      mock.isResponseRequired = false
      mock.supplementaryMessage = ""
      mock.supplementaryIsError = false
      verdict.value = value
      verdict.restart()
    }

    function cancelAuthenticationRequest(): void {
      mock.isCancelled = true
      mock.isCompleted = true
      root.mocking = false
    }
  }

  Timer {
    id: verdict

    property string value: ""

    interval: 600

    onTriggered: {
      // the design's mock password. anything else is a refusal, in pam's own
      // words rather than a counter the real api does not expose.
      if (verdict.value === "toor") {
        mock.supplementaryMessage = ""
        mock.isSuccessful = true
        mock.isCompleted = true
        settle.restart()
        return
      }

      mock.supplementaryMessage = "Authentication failure"
      mock.supplementaryIsError = true
      mock.isResponseRequired = true
    }
  }

  // the design holds the accepted state on screen before the card goes.
  Timer {
    id: settle

    interval: 1100

    onTriggered: root.mocking = false
  }

  // every state the card can be in, addressable from a shell. the dialog is built
  // against these before it is ever pointed at a real request.
  IpcHandler {
    target: "polkit"

    function prompt(): void {
      root.raise()
    }

    function busy(): void {
      root.raise()
      mock.isResponseRequired = false
      verdict.stop()
    }

    function error(): void {
      root.raise()
      mock.supplementaryMessage = "Authentication failure"
      mock.supplementaryIsError = true
    }

    function ok(): void {
      root.raise()
      mock.isSuccessful = true
      mock.isCompleted = true
      settle.stop()
    }

    function close(): void {
      root.dismiss()
    }
  }
}
