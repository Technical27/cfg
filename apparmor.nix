device: pkgs:

let
  isLaptop = device == "laptop";
  mkLaptop = obj: pkgs.lib.mkIf (isLaptop) obj;
in with pkgs;[
  (mkLaptop (writeText "teams" ''
    #include <tunables/global>
    ${teams}/bin/teams {
      #include <abstractions/audio>
      #include <abstractions/base>
      #include <abstractions/fonts>
      #include <abstractions/freedesktop.org>
      #include <abstractions/ibus>
      #include <abstractions/nameservice>
      #include <abstractions/user-tmp>
      #include <abstractions/X>
      #include <abstractions/ssl_certs>
      #include <abstractions/private-files-strict>

      @{HOME}/{.local/share/applications,.config}/mimeapps.list r,

      owner @{HOME}/.config/teams/** rwk,
      owner @{HOME}/.config/Microsoft/Microsoft\ Teams/** rwk,
      owner @{HOME}/.config/Microsoft/Microsoft\ Teams rwk,
      owner @{HOME}/.cache/** rwk,
      @{HOME}/Downloads/** rw,
      @{HOME}/.local/share/.org.chromium.Chromium.* rw,
      @{HOME}/** r,
      @{HOME}/.pki/nssdb/** rwk,

      # WHY DOES TEAMS DOWNLOAD TO HOME AND NOT DOWNLOADS
      @{HOME}/* rw,

      audit deny @{HOME}/{git,cfg,pkgs} rw,

      /dev/video* mrw,
      /dev/snd/* mr,

      ${teams}/opt/teams/*.so* mr,

      unix (send, receive, connect),

      /dev/** r,
      /dev/ r,
      /dev/tty rw,
      owner /dev/shm/* mrw,

      @{PROC}/** r,
      owner @{PROC}/*/setgroups w,
      owner @{PROC}/*/gid_map rw,
      owner @{PROC}/*/uid_map rw,
      owner @{PROC}/*/oom_score_adj rw,
      owner @{PROC}/*/fd/** rw,
      @{PROC}/ r,
      /sys/** r,

      /etc/machine-id r,

      /nix/store/*/lib/*.so* mr,
      /nix/store/*/lib/**/*.so* mr,
      /nix/store/** r,
      /run/opengl-driver{,-32}/lib/*.so* mr,

      ${teams}/** r,
      ${teams}/**/*.node mr,
      ${teams}/bin/* ix,
      ${teams}/opt/teams/* ix,
      ${glibc.bin}/bin/locale ix,
      ${bashInteractive}/bin/bash ix,
      capability sys_admin,
      capability sys_chroot,
      capability sys_ptrace,

      ${xdg_utils}/bin/* Cx -> xdg_utils,

      profile xdg_utils {
        ${bash}/bin/bash rix,

        ${gnugrep}/bin/{,e,f}grep ix,
        ${coreutils}/bin/* ix,
        ${gnused}/bin/sed ix,
        ${dbus}/bin/dbus-send ix,
        ${gawk}/bin/{,g}awk ix,
        ${xdg_utils}/bin/* ix,
        ${cpkgs.firefox-with-extensions}/bin/firefox Ux,

        @{HOME}/.config/mimeapps.list r,
        @{HOME}/.local/share/applications/mimeapps.list r,
        @{HOME}/.local/share/applications/ r,

        /nix/store/*/lib/*.so* mr,
        /nix/store/*/lib/**/*.so* mr,
        /nix/store/** r,

        /dev/null rw,
        /dev/tty rw,
      }

      /dev/null rw,

      owner /tmp/** rw,
    }
  ''))
  (writeText "discord" ''
    #include <tunables/global>
    ${discord}/bin/Discord {
      #include <abstractions/audio>
      #include <abstractions/base>
      #include <abstractions/fonts>
      #include <abstractions/freedesktop.org>
      #include <abstractions/ibus>
      #include <abstractions/nameservice>
      #include <abstractions/user-tmp>
      #include <abstractions/X>
      #include <abstractions/ssl_certs>
      #include <abstractions/private-files-strict>

      owner @{HOME}/.config/discord/** rwk,
      owner @{HOME}/.config/discord rk,
      @{HOME}/.icons/** r,
      @{HOME}/.pki/** r,
      owner @{HOME}/.cache/** rwk,

      /dev/video* mrw,
      /dev/snd/* mr,

      ${discord}/opt/Discord/*.so* mr,

      /dev/** r,
      /dev/ r,
      owner /dev/shm/* mrw,

      @{PROC}/** r,
      owner @{PROC}/*/setgroups w,
      owner @{PROC}/*/gid_map rw,
      owner @{PROC}/*/uid_map rw,
      owner @{PROC}/*/fd/** rw,
      @{PROC}/ r,
      /sys/** r,

      /etc/machine-id r,

      /nix/store/*/lib/*.so* mr,
      /nix/store/*/lib/**/*.so* mr,
      /nix/store/** r,
      /run/opengl-driver{,-32}/lib/*.so* mr,

      ${discord}/** r,
      ${discord}/**/*.node mr,
      ${discord}/bin/* ix,
      ${discord}/opt/Discord/* ix,

      /dev/null rw,

      owner /tmp/** rw,
    }
  '')
]
