# programs.kuori: the shell as a user unit, and what only kuori needs from the
# system -- its pam services, its fonts, its calendar timer.
#
# what is useful without kuori stays out on purpose: hyprland, the wallpaper,
# night light and clipboard daemons, bluetooth, upower, networkmanager. kuori
# hides what it cannot drive when one of those is missing (see README).
{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.programs.kuori;

  # "~/" becomes $HOME, which the wrapper's shell expands. the unit runs that same
  # wrapper, so the shell and every `kuori ipc` call spell the path alike -- ipc
  # finds the running shell by the literal path it was started with.
  home = path: if lib.hasPrefix "~/" path then "$HOME" + lib.removePrefix "~" path else path;

  # a store copy is served from /etc/kuori rather than from its store path: the
  # path has to be the same on every generation, or a bind rebuilt against the
  # new one would find no instance of the old one still running.
  configPath = if cfg.configDir == null then "/etc/kuori" else home cfg.configDir;

  package = cfg.package.override {
    inherit configPath;
    inherit (cfg) extraPackages;
  };
in
{
  options.programs.kuori = {
    enable = lib.mkEnableOption "kuori, a Quickshell desktop shell for Hyprland";

    package = lib.mkOption {
      type = lib.types.package;
      default = pkgs.callPackage ./package.nix { };
      defaultText = lib.literalExpression "pkgs.callPackage ./package.nix { }";
      description = ''
        The kuori package. Built from this system's pkgs by default, so that
        quickshell and the Qt image format plugins it loads are the same Qt.
      '';
    };

    configDir = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = null;
      example = "~/.config/kuori";
      description = ''
        Where the shell's QML is read from. null runs the copy in the package,
        served from /etc/kuori. A path runs a checkout instead, which Quickshell
        reloads on every save; a leading `~/` means the user's home.
      '';
    };

    extraPackages = lib.mkOption {
      type = lib.types.listOf lib.types.package;
      default = [ ];
      description = "More programs for the shell's PATH, ahead of the system's.";
    };

    calendar.enable = lib.mkEnableOption ''
      the Google Calendar sync timer. It needs an OAuth client first; see
      `kuori-calendar auth` in the README
    '';

    lock.enable = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = ''
        The two PAM services the lock screen authenticates against. kuori
        refuses to lock without them.
      '';
    };

    fonts.enable = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "The fonts kuori's theme names: Material Symbols, Manrope and JetBrainsMono Nerd Font.";
    };
  };

  config = lib.mkIf cfg.enable (
    lib.mkMerge [
      {
        environment.systemPackages = [ package ];

        environment.etc = lib.mkIf (cfg.configDir == null) {
          kuori.source = "${package}/share/kuori";
        };

        # a unit rather than an exec-once in hyprland's config, because it is
        # load-bearing: the shell is the session's polkit agent and notification
        # server, Restart=on-failure means a crash does not silently leave the
        # session without either, and the journal gets its output for free.
        systemd.user.services.kuori = {
          description = "kuori desktop shell";
          partOf = [ "graphical-session.target" ];
          after = [ "graphical-session.target" ];
          wantedBy = [ "graphical-session.target" ];
          unitConfig.ConditionEnvironment = "WAYLAND_DISPLAY";
          serviceConfig = {
            Type = "simple";
            ExecStart = lib.getExe package;

            # systemd hands a unit a minimal PATH and nothing of the session's. the
            # wrapper adds what the package carries; this is for the rest -- uwsm,
            # nmcli, hyprctl, awww, cliphist, ping -- and for the applications the
            # launcher starts, each of which fails silently when it is missing. the
            # session's own directories rather than store paths, so something the
            # shell picks up later does not have to be added here too.
            Environment = [ "PATH=/run/wrappers/bin:/run/current-system/sw/bin" ];

            Slice = "session.slice";
            TimeoutStopSec = "5sec";
            Restart = "on-failure";
          };
        };

        warnings =
          lib.optional (!config.programs.hyprland.enable) ''
            programs.kuori: programs.hyprland.enable is false. kuori only runs on Hyprland; ignore this if Hyprland comes from elsewhere.
          ''
          ++ lib.optional (!config.security.polkit.enable) ''
            programs.kuori: security.polkit.enable is false, so kuori's authentication dialog has nothing to answer for.
          '';
      }

      (lib.mkIf cfg.lock.enable {
        # one service per way in. kuori runs both conversations at once, so a
        # finger and a typed password each answer the same lock; one stack cannot,
        # because pam_fprintd holds the conversation for up to 30 seconds and
        # three tries before pam_unix is ever asked.
        security.pam.services.kuori = {
          fprintAuth = false;
        };

        security.pam.services.kuori-fingerprint = {
          unixAuth = false;
          fprintAuth = true;
        };
      })

      (lib.mkIf cfg.fonts.enable {
        fonts.packages = [
          pkgs.material-symbols
          (pkgs.google-fonts.override { fonts = [ "Manrope" ]; })
          pkgs.nerd-fonts.jetbrains-mono
        ];
      })

      (lib.mkIf cfg.calendar.enable {
        # a unit of its own rather than a process in the shell, so the oauth tokens
        # never pass through qml and a shell restart fetches nothing. the script
        # reads $STATE_DIRECTORY and $CACHE_DIRECTORY, which name the same
        # ~/.local/state/kuori and ~/.cache/kuori it falls back to from a terminal.
        # the shell also starts this itself when the tab opens on a stale file.
        systemd.user.services.kuori-calendar = {
          description = "Sync Google Calendar events for kuori";
          serviceConfig = {
            Type = "oneshot";
            ExecStart = "${lib.getExe' package "kuori-calendar"} sync";
            StateDirectory = "kuori";
            CacheDirectory = "kuori";
            Slice = "session.slice";
          };
        };

        # every 15 minutes, and once shortly after login. a run that fails offline
        # leaves the last file in place until the next one.
        systemd.user.timers.kuori-calendar = {
          description = "Sync Google Calendar events for kuori every 15 minutes";
          wantedBy = [ "timers.target" ];
          timerConfig = {
            OnStartupSec = "1min";
            OnUnitActiveSec = "15min";
          };
        };
      })
    ]
  );
}
