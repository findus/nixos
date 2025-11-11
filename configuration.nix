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

services = {
  desktopManager.plasma6.enable = true;

  displayManager.sddm.enable = true;

  displayManager.sddm.wayland.enable = true;
  
  # Ensure the NVIDIA card is used for rendering
  displayManager.sddm.extraPackages = with pkgs; [
    kdePackages.kirigami
    kdePackages.layer-shell-qt
  ];
  
  # Use Wayland by default for the display manager
  displayManager.sddm.session = "plasmawayland";
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
    # Non-KDE graphical packages
    hardinfo2 # System information and benchmarks for Linux systems
    vlc # Cross-platform media player and streaming server
    wayland-utils # Wayland utilities
    wl-clipboard # Command-line copy/paste utilities for Wayland
  ];

  nixpkgs.config.allowUnfree = true;

  nixpkgs.overlays = [  
    (self: super: {  
    python311 = super.python311.override {  
    x11Support = true;  
    };  
    })  
      ];  

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

  # Set kernel packages first (before NVIDIA config)
  boot.kernelPackages = pkgs.linuxPackages; # (this is the default) some amdgpu issues on 6.10

  # Kernel parameters for NVIDIA 4K@60Hz support on Wayland
  boot.kernelParams = [
    "nvidia-drm.modeset=1"  # Required for DRM modesetting
    "nvidia-drm.fbdev=1"    # Enable framebuffer device for better display handling
  ];

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

    # Enable explicit Wayland support (critical for proper refresh rates)
    forceFullCompositionPipeline = false;

    # Using a stable driver version - 550+ has improved Wayland support
    # Change to .stable for stable releases or .beta for latest features
    package = config.boot.kernelPackages.nvidiaPackages.stable;
  };


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
environment = {
  loginShellInit = ''
    [[ "$(tty)" = "/dev/tty1" ]] && ./gs.sh
  '';
sessionVariables = {
      LD_LIBRARY_PATH = "${pkgs.stdenv.cc.cc.lib}/lib";
    };
};

}

