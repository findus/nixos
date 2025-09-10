# Edit this configuration file to define what should be installed on
# your system. Help is available in the configuration.nix(5) man page, on
# https://search.nixos.org/options and in the NixOS manual (`nixos-help`).

{ config, lib, pkgs, ... }:

let
  home-manager = builtins.fetchTarball "https://github.com/nix-community/home-manager/archive/release-25.05.tar.gz";
in

{
  imports =
    [ # Include the results of the hardware scan.
      ./hardware-configuration.nix
      (import "${home-manager}/nixos")
    ];

  nix.settings.experimental-features = [ "nix-command" "flakes" ];

  networking.firewall = {
  enable = true;
  allowedTCPPorts = [ 47984 47989 47990 48010 ];
  allowedUDPPortRanges = [
    { from = 47998; to = 48000; }
    { from = 8000; to = 8010; }
  ];
};

systemd.services."getty@tty1" = {
  overrideStrategy = "asDropin";
  serviceConfig.ExecStart = ["" "@${pkgs.util-linux}/sbin/agetty agetty --login-program ${config.services.getty.loginProgram} --autologin findus --noclear --keep-baud %I 115200,38400,9600 $TERM"];
};

 # rtkit (optional, recommended) allows Pipewire to use the realtime scheduler for increased performance.
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true; # if not already enabled
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
    # If you want to use JACK applications, uncomment the following
    #jack.enable = true;
  };

 services.sunshine.package = pkgs.sunshine.override { cudaSupport = true; };
 services.sunshine = {
    enable = true;
    autoStart = true;
    capSysAdmin = false;
    openFirewall = true;
  };

  environment.variables = {
  __GL_SYNC_TO_VBLANK = "1";        # sync with monitor
  __GL_MaxFramesAllowed = "1";      # reduce frame queue
  __GL_GSYNC_ALLOWED = "0";         # disable G-SYNC if present
};

  environment.etc."sway/config".text = pkgs.lib.mkForce ''
  exec sunshine
  exec alacritty
  exec steam -bigpicture
  output HDMI-A-1 pos 0 0 res 3840x2160@60Hz
  for_window [app_id=".*"] exec /home/findus/stfd
'';

home-manager.users.findus = { pkgs, ... }: {
    home.packages = [ 
      pkgs.atool pkgs.httpie 
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
    # The state version is required and should stay at the version you
    # originally installed.
    home.stateVersion = "25.05";
     # Add a shell hook for all login shells
    programs.bash.profileExtra = ''
        if [[ -z $DISPLAY && $(tty) == /dev/tty1 ]]; then
          #exec sway --unsupported-gpu
          exec niri
          #exec bash
        fi
        echo "lol"
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
 

  };

  environment.systemPackages = with pkgs; [
    # Flakes clones its dependencies through the git command,
    # so git must be installed first
    git
    vim
    pkgs.mangohud
    wget
    curl
    sway
    niri
    xwayland-satellite
    alacritty
    pavucontrol
    pulseaudio
    pstree
    jq
  ];

  nixpkgs.config.allowUnfree = true;

  # Set the default editor to vim
  environment.variables.EDITOR = "vim";

  # Use the GRUB 2 boot loader.
  boot.loader.systemd-boot.enable = true;

  networking.hostName = "chonker";
  networking.networkmanager.enable = true;  # Easiest to use and most distros use this by default.

  # Set your time zone.
  time.timeZone = "Europe/Amsterdam";


  # Define a user account. Don't forget to set a password with ‘passwd’.
   users.users.findus = {
     isNormalUser = true;
    initialPassword = "1234";
     extraGroups = [ "wheel" ]; # Enable ‘sudo’ for the user.
     packages = with pkgs; [
       tree
     ];
   };

  
  programs.firefox.enable = true;

  # Some programs need SUID wrappers, can be configured further or are
  # started in user sessions.
  programs.mtr.enable = true;
  programs.gnupg.agent = {
   enable = true;
   enableSSHSupport = true;
 };

 services.openssh.settings.PermitRootLogin = "yes";

  # List services that you want to enable:

  # Enable the OpenSSH daemon.
  services.openssh.enable = true;

  # For more information, see `man configuration.nix` or https://nixos.org/manual/nixos/stable/options#opt-system.stateVersion .
  system.stateVersion = "25.05"; # Did you read the comment?

    # Enable OpenGL
  hardware.graphics = {
    enable = true;
  };

  # Load nvidia driver for Xorg and Wayland
  services.xserver.videoDrivers = ["nvidia"];

  hardware.nvidia = {

    # Modesetting is required.
    modesetting.enable = true;

    # Nvidia power management. Experimental, and can cause sleep/suspend to fail.
    # Enable this if you have graphical corruption issues or application crashes after waking
    # up from sleep. This fixes it by saving the entire VRAM memory to /tmp/ instead 
    # of just the bare essentials.
    powerManagement.enable = false;

    # Fine-grained power management. Turns off GPU when not in use.
    # Experimental and only works on modern Nvidia GPUs (Turing or newer).
    powerManagement.finegrained = false;

    # Use the NVidia open source kernel module (not to be confused with the
    # independent third-party "nouveau" open source driver).
    # Support is limited to the Turing and later architectures. Full list of 
    # supported GPUs is at: 
    # https://github.com/NVIDIA/open-gpu-kernel-modules#compatible-gpus 
    # Only available from driver 515.43.04+
    open = false;

    # Enable the Nvidia settings menu,
	# accessible via `nvidia-settings`.
    nvidiaSettings = true;

    # Optionally, you may need to select the appropriate driver version for your specific GPU.
    package = config.boot.kernelPackages.nvidiaPackages.stable;
  };


boot.kernelPackages = pkgs.linuxPackages; # (this is the default) some amdgpu issues on 6.10
programs = {
  gamescope = {
    enable = true;
    capSysNice = true;
  };
  steam = {
    enable = true;
    gamescopeSession.enable = true;
  };
};
hardware.xone.enable = true; # support for the xbox controller USB dongle
services.getty.autologinUser = "findus";
#environment = {
#  loginShellInit = ''
#    [[ "$(tty)" = "/dev/tty1" ]] && ./gs.sh
#  '';
#};

}

