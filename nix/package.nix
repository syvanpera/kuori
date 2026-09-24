# kuori: the config tree, plus `kuori` and `kuori-calendar` to run it.
#
# Built with whoever calls it's pkgs -- the module uses the consumer's -- because
# qtimageformats has to be the same Qt as quickshell: a plugin built against a
# different Qt refuses to load, and says nothing.
{
  lib,
  stdenvNoCC,
  quickshell,
  qt6,
  python3,
  grim,
  slurp,
  grimblast,
  wf-recorder,
  hyprpicker,
  libnotify,
  wl-clipboard,
  brightnessctl,

  # where the shell's files are read from. null is this package's own copy;
  # anything else is written into the wrappers inside double quotes, so
  # "$HOME/.config/kuori" names a live checkout. the module sets it.
  configPath ? null,

  # more tools for the shell's PATH, ahead of the system's.
  extraPackages ? [ ],
}:

let
  # what the shell runs that talks to no daemon, so any version will do and the
  # user need not have installed it. awww and cliphist are deliberately absent:
  # each client has to match a daemon or a database the user runs, so those, and
  # hyprctl, nmcli, uwsm and ping, come from the system PATH the unit keeps.
  runtime = [
    # the d-bus helpers under scripts/ are started as `python3`, so this python
    # is the one they get.
    (python3.withPackages (ps: [ ps.jeepney ]))
    grim
    slurp
    grimblast
    wf-recorder
    hyprpicker
    libnotify
    wl-clipboard
    brightnessctl
  ]
  ++ extraPackages;

  # the directories quickshell reads. docs, the readme and these notes are left
  # out, so editing them rebuilds nothing.
  src = lib.fileset.toSource {
    root = ../.;
    fileset = lib.fileset.unions [
      ../shell.qml
      ../components
      ../modules
      ../services
      ../theme
      ../windows
      ../scripts
    ];
  };
in
stdenvNoCC.mkDerivation (finalAttrs: {
  pname = "kuori";
  version = "0-unstable";

  inherit src;

  dontBuild = true;

  installPhase =
    let
      config = if configPath == null then "${placeholder "out"}/share/kuori" else configPath;
    in
    ''
      runHook preInstall

      mkdir -p $out/share/kuori $out/bin
      cp -r . $out/share/kuori

      # QS_CONFIG_PATH is quickshell's own spelling of -p, so `kuori ipc call ...`
      # and `kuori log` name the same config as `kuori` does, with nothing to
      # remember. ipc finds an instance by the literal path it was started with,
      # which is why every caller should go through this one script.
      cat > $out/bin/kuori <<'EOF'
      #!${stdenvNoCC.shell}
      : "''${QS_CONFIG_PATH:=${config}}"
      export QS_CONFIG_PATH
      export PATH="${lib.makeBinPath runtime}''${PATH:+:$PATH}"
      export QT_PLUGIN_PATH="${qt6.qtimageformats}/${qt6.qtbase.qtPluginPrefix}''${QT_PLUGIN_PATH:+:$QT_PLUGIN_PATH}"
      exec ${lib.getExe' quickshell "quickshell"} "$@"
      EOF

      # the calendar needs nothing outside the standard library. it follows the
      # same QS_CONFIG_PATH, so a live checkout runs its own copy of the script.
      cat > $out/bin/kuori-calendar <<'EOF'
      #!${stdenvNoCC.shell}
      : "''${QS_CONFIG_PATH:=${config}}"
      exec ${lib.getExe python3} -B "$QS_CONFIG_PATH/scripts/kuori-calendar" "$@"
      EOF

      chmod +x $out/bin/kuori $out/bin/kuori-calendar

      runHook postInstall
    '';

  passthru = { inherit runtime; };

  meta = {
    description = "A Quickshell desktop shell for Hyprland";
    homepage = "https://github.com/syvanpera/kuori";
    platforms = lib.platforms.linux;
    mainProgram = "kuori";
  };
})
