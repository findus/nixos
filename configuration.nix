# Edit this configuration file to define what should be installed on
# your system. Help is available in the configuration.nix(5) man page, on
# https://search.nixos.org/options and in the NixOS manual (`nixos-help`).

{ config, lib, pkgs, ... }:

{
  imports =
    [ # Include the results of the hardware scan.
      ./hardware-configuration.nix
    ];

  nix.settings.experimental-features = [ "nix-command" "flakes" ];

  networking.firewall = {
  enable = true;
  allowedTCPPortRanges = [
     { from = 1714; to = 1764; }
  ];
  allowedUDPPortRanges = [
    { from = 47998; to = 48000; }
    { from = 8000; to = 8010; }
    { from = 1714; to = 1764; } 
  ];
  allowedTCPPorts = [ 53317 ];
  allowedUDPPorts = [ 53317 ];
};
boot.kernelPackages = pkgs.linuxPackagesFor (pkgs.linux_6_12.override {
    argsOverride = rec {
      src = pkgs.fetchurl {
            url = "mirror://kernel/linux/kernel/v6.x/linux-${version}.tar.xz";
            sha256 = "sha256-Flyhw3xGB7kOcxmWt8HjMRKFFn0T3u7fCPPx8LnSVBo=";
      };
      version = "6.12.57";
      modDirVersion = "6.12.57";
      };
  });


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

services = {
  desktopManager.plasma6.enable = true;

  displayManager.sddm.enable = true;

  displayManager.sddm.wayland.enable = true;
  
  # Ensure the NVIDIA card is used for rendering
  displayManager.sddm.extraPackages = with pkgs; [
    kdePackages.kirigami
    kdePackages.layer-shell-qt
  ];
  
};


  hardware.bluetooth.enable = true;
  services.blueman.enable = true;

  environment.variables = {
  __GL_SYNC_TO_VBLANK = "1";        # sync with monitor
  __GL_MaxFramesAllowed = "1";      # reduce frame queue
  __GL_GSYNC_ALLOWED = "0";         # disable G-SYNC if present
  LIBVA_DRIVER_NAME = "nvidia";     # Use nvidia for VA-API acceleration
  XDG_SESSION_TYPE = "wayland";     # Force wayland session
  CLUTTER_BACKEND = "wayland";      # Use wayland for clutter (KDE uses this)
  GBM_BACKEND = "nvidia-drm";       # Use NVIDIA's GBM backend for wayland
  __GLX_VENDOR_LIBRARY_NAME = "nvidia"; # Direct glx to nvidia
  NVIDIA_MIG_MONITOR_DEVICES = "all"; # Enable all GPU devices
  KWIN_DRM_THREAD_WORKER_ONLY = "0"; # Allow KWin to use GPU properly
  ENABLE_NVIDIA_MODESET = "1";       # Ensure NVIDIA modeset is enabled
  # NVIDIA Wayland-specific fixes for refresh rate
  NVIDIA_PRESERVE_VIDEO_MEMORY_ALLOCATIONS = "1"; # Preserve VRAM allocations
  KWIN_NO_SCALE_FROM_EDID = "1";     # Don't use EDID for scaling
};



  environment.etc."sway/config".text = pkgs.lib.mkForce ''
  exec sunshine
  exec alacritty
  exec steam -bigpicture
  output HDMI-A-1 pos 0 0 res 3840x2160@60Hz
  for_window [app_id=".*"] exec /home/findus/stfd
'';

  environment.systemPackages = with pkgs; [
    # Flakes clones its dependencies through the git command,
    # so git must be installed first
    vscode
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
    bluetui
    ncpamixer
    pipenv
    pyenv
    gcc
    gnumake
    thunderbird
    nvtopPackages.nvidia
    python311
    cudaPackages.cudnn
    cudaPackages.cudatoolkit
    (pkgs.python311.withPackages (ps: with ps; [ tkinter ]))
    ffmpeg
    kdePackages.discover # Optional: Install if you use Flatpak or fwupd firmware update sevice
    kdePackages.kcalc # Calculator
    kdePackages.kcharselect # Tool to select and copy special characters from all installed fonts
    kdePackages.kclock # Clock app
    kdePackages.kcolorchooser # A small utility to select a color
    kdePackages.kolourpaint # Easy-to-use paint program
    kdePackages.ksystemlog # KDE SystemLog Application
    kdePackages.sddm-kcm # Configuration module for SDDM
    kdiff3 # Compares and merges 2 or 3 files or directories
    kdePackages.isoimagewriter # Optional: Program to write hybrid ISO files onto USB disks
    kdePackages.partitionmanager # Optional: Manage the disk devices, partitions and file systems on your computer
    kdePackages.kscreen # KDE display configuration tool
    # Non-KDE graphical packages
    hardinfo2 # System information and benchmarks for Linux systems
    vlc # Cross-platform media player and streaming server
    wayland-utils # Wayland utilities
    wl-clipboard # Command-line copy/paste utilities for Wayland
    telegram-desktop
    fractal
    spotify
    nextcloud-client
    cudaPackages.cudatoolkit
    (blender.override { cudaSupport = true; })
    flatpak
    keepassxc
    kdePackages.kdenlive 
    (ghidra.withExtensions (p: with p; [ ret-sync ]))
    gdb
    krita
    gimp

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
   };

  
  programs.firefox.enable = true;

  # Some programs need SUID wrappers, can be configured further or are
  # started in user sessions.
  programs.mtr.enable = true;

 programs.kdeconnect.enable = true;


  # Enable Flatpak support and add the Flathub repository

 services.flatpak.enable = true;
 systemd.services.flatpak-repo = {
    wantedBy = [ "multi-user.target" ];
    path = [ pkgs.flatpak ];
    script = ''
      flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo
    ''; 
 };

 systemd.user.services.add_ssh_keys = {
    script = ''
      eval `${pkgs.openssh}/bin/ssh-agent -s`
      export SSH_ASKPASS="${pkgs.kdePackages.ksshaskpass}/bin/ksshaskpass"
      export SSH_ASKPASS_REQUIRE="prefer"
      ${pkgs.openssh}/bin/ssh-add $HOME/.ssh/key
    '';
    wantedBy = [ "default.target" ];
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

hardware.nvidia.package = config.boot.kernelPackages.nvidiaPackages.beta;   # Latest beta driver

hardware.nvidia = {
  modesetting.enable = true;
  powerManagement.enable = true;
  nvidiaSettings = true;
  open = true;
};

boot.kernelModules = [ "nvidia" "nvidia_modeset" "nvidia_uvm" "nvidia_drm"];


programs = {
  gamescope = {
    #enable = true;
    capSysNice = true;
  };
  steam = {
    enable = true;
   # gamescopeSession.enable = true;
  };
};
hardware.xone.enable = true; # support for the xbox controller USB dongle
services.getty.autologinUser = "findus";
#environment = {
#  loginShellInit = ''
#    [[ "$(tty)" = "/dev/tty1" ]] && ./gs.sh
#  '';
#sessionVariables = {
#      LD_LIBRARY_PATH = "${pkgs.stdenv.cc.cc.lib}/lib";
#    };
#};

}

