{ config, pkgs, ... }:

{
  # This value determines the Home Manager release that your
  # configuration is compatible with. This helps avoid breakage
  # when a new Home Manager release introduces backwards
  # incompatible changes.
  #
  # You can update Home Manager without changing this value. See
  # the Home Manager release notes for a list of state version
  # changes in each release.
  home.stateVersion = "25.05";

  # KDE Plasma 6 display configuration for 4K@60Hz
  home.file.".config/kscreen/kscreenrc".text = ''
    [OutputOrder]
    outputs=HDMI-A-1

    [HDMI-A-1]
    enabled=true
    mode=3840x2160@60
    position=0x0
    scale=1
    rotation=Normal
  '';



services.kdeconnect.enable = true;

home.packages = [ 
  pkgs.darktable
      (pkgs.writeShellScriptBin "tgx" ''
        #!/usr/bin/env bash
        set -x
        id=$(swaymsg -s /var/run/user/1000/sway* -t get_tree | jq -r "recurse(.nodes[]?, .floating_nodes[]?) | select( .name | test(\"^$1\") )  | .id ")
        shift
        swaymsg -s /var/run/user/1000/sway*.sock "[con_id=$id]" "$@"
      '')
      (pkgs.writeShellScriptBin "sound" ''
        #!/usr/bin/env bash
        pactl set-default-sink $(pactl list short sinks | grep hdmi-stereo | awk '{ print $1  }')
      '')
    ];
    programs.bash.enable = true;
     # Add a shell hook for all login shells
    programs.bash.profileExtra = ''
        if [[ -z $DISPLAY && $(tty) == /dev/tty1 ]]; then
          exec sway --unsupported-gpu
          #exec niri
          #exec bash
          echo "nothing"
        fi
        echo "lol"

        rm ~/.ssh/ssh_auth_sock
killall ssh-agent
if [ ! -S ~/.ssh/ssh_auth_sock ]; then
	eval `ssh-agent`
	ln -sf "$SSH_AUTH_SOCK" ~/.ssh/ssh_auth_sock
fi
    '';

    home.file."bin/stfd" = {
      text = ''
        #!/usr/bin/env bash
        id=$(swaymsg -s /var/run/user/1000/sway* -t get_tree | jq -r 'recurse(.nodes[]?, .floating_nodes[]?) | select( .name == "Steam Big Picture Mode" ) |  .id ')
        swaymsg -s /var/run/user/1000/sway*.sock "[con_id=$id]" fullscreen disable
      '';
      executable = true;
    };


    home.file.".config/niri/config.kdl" = {
      text = ''
        spawn-at-startup "alacritty"
        spawn-at-startup "sunshine"
        spawn-at-startup "steam" "-bigpicture"

        output "HDMI-A-1" {
          mode "3840x2160@59.940"
          scale 1
        }

        output "DP-1" {
          mode "2560x1440@59.951"
          scale 1
        }

        window-rule {
          open-maximized true
          open-fullscreen true
          open-floating false
          open-focused true
          max-width 2560
          max-height 1440
        } 

        binds {
          Mod+T { spawn "alacritty"; }
          Mod+A { focus-column-left; }
          Mod+S { focus-window-or-workspace-down; }
          Mod+W { focus-window-or-workspace-up; }
          Mod+D { focus-column-right; }
        }
      '';
      executable = true;
    };

    home.file."bin/sttf" = {
      text = ''
        #!/usr/bin/env bash
        id=$(swaymsg -s /var/run/user/1000/sway* -t get_tree | jq -r 'recurse(.nodes[]?, .floating_nodes[]?) | select( .name == "Steam Big Picture Mode" ) |  .id ')
        swaymsg -s /var/run/user/1000/sway*.sock "[con_id=$id]" fullscreen
      '';
      executable = true;
    };

    home.file."bin/tgf" = {
      text = ''
        #!/usr/bin/env bash
        id=$(swaymsg -s /var/run/user/1000/sway* -t get_tree | jq -r "recurse(.nodes[]?, .floating_nodes[]?) | select( .name | test(\"^$1\") ) | .id ")
        swaymsg -s /var/run/user/1000/sway*.sock "[con_id=$id]" fullscreen
      '';
      executable = true;
    };

}