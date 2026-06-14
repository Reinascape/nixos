{ config, lib, pkgs, inputs, ... }:

{
  imports = [
      ./hardware-configuration.nix
    ];

  ##############
  # Bootloader #
  ##############
  boot = {
    lanzaboote = {
      enable = true;
      pkiBundle = "/var/lib/sbctl";
    };
    blacklistedKernelModules = [ "nouveau" ];
    kernelPackages = pkgs.linuxPackages_cachyos-lto;
    consoleLogLevel = 3;
    initrd.verbose = false;
    kernelParams = [
      "quiet"
      "splash"
      "loglevel=3"
      "rd.udev.log_level=3"
      "boot.shell_on_fail"
      "udev.log_priority=3"
      "rd.systemd.show_status=auto"
      "i915.force_probe=!46a3"
      "xe.force_probe=46a3"
    ];
    loader = {
      timeout = 0; 
      systemd-boot.enable = lib.mkForce false;
      systemd-boot.consoleMode = "max";
      efi.canTouchEfiVariables = true;
    };
    plymouth = {
      enable = true;
      theme = "bgrt";
    };
  };

  systemd.tmpfiles.rules = [
    "L+ /run/gdm/.config/monitors.xml - - - - ${pkgs.writeText "gdm-monitors.xml" ''
      <monitors version="2">
        <configuration>
          <layoutmode>logical</layoutmode>
          <logicalmonitor>
            <x>0</x>
            <y>0</y>
            <scale>1.25</scale>
            <primary>yes</primary>
            <monitor>
              <monitorspec>
                <connector>eDP-1</connector>
                <vendor>CSO</vendor>
                <product>0x1616</product>
                <serial>0x00000000</serial>
              </monitorspec>
              <mode>
                <width>2560</width>
                <height>1600</height>
                <rate>165.019</rate>
              </mode>
            </monitor>
          </logicalmonitor>
        </configuration>
      </monitors>
    ''}"
  ];


  ############
  # Graphics #
  ############
  #services = {
  #  xserver.videoDrivers = [ "nvidia" ];
  #  switcherooControl.enable = true;
  #};
         
  hardware = {
    cpu.intel.updateMicrocode = true;
    #nvidia-container-toolkit.enable = true;
    graphics = {
      enable = true;
      extraPackages = with pkgs; [
        #nvidia-vaapi-driver
        intel-media-driver
        intel-ocl
        intel-vaapi-driver
      ];
    };

    #nvidia = {
    #  modesetting.enable = true;
    #  dynamicBoost.enable = true;
    #  open = false;
    #  nvidiaSettings = true;
    #  package = config.boot.kernelPackages.nvidiaPackages.stable;
    #  powerManagement = {
    #    enable = true;
    #    finegrained = true;
    #  };
    #  prime = {
    #    offload = {
    #      enable = true;
    #      enableOffloadCmd = true;
    #    };
    #    intelBusId = "PCI:0:2:0"; 
    #    nvidiaBusId = "PCI:1:0:0";
    #  };
    #};
  };  




  #########
  # GNOME #
  #########
  services = {
    displayManager.gdm = {
      enable = true;
      wayland = true;
    };

    desktopManager.gnome = {
      enable = true;
      extraGSettingsOverridePackages = [ pkgs.mutter ];
      extraGSettingsOverrides = ''
        [org.gnome.mutter]
        experimental-features=['scale-monitor-framebuffer', 'variable-refresh-rate', 'xwayland-native-scaling']
      '';
    };
  };




  ###########
  # Locales #
  ###########
  i18n = {
    defaultLocale = "en_US.UTF-8";
    supportedLocales = [ "all" ];
  };
    
  #console = {
  #  font = "Lat2-Terminus16";
  #  keyMap = "us";
  #  useXkbConfig = true;
  #};

  fonts.packages = with pkgs; [
    noto-fonts
    font-awesome
    liberation_ttf
    noto-fonts-cjk-sans
    noto-fonts-cjk-serif
    noto-fonts-color-emoji
  ];




  ########
  # Time #
  ########
  time.timeZone = "Europe/Moscow";
 



  ##############
  # Networking #
  ##############
  networking = {
    hostName = "NixOS";
    networkmanager.enable = true;
    useDHCP = lib.mkForce true;
    firewall.checkReversePath = false;
    hosts = {
      "127.0.0.1" = [ "localhost" ];
      "::1" = [ "localhost" ];
      "127.0.02" = [ "ms7996" ];
      "50.7.85.219" = [ "inference.codeium.com" ];
      "50.7.87.83" = [ "proxy.individual.githubcopilot.com" ];
      "142.54.189.106" = [ "web.archive.org" ];
      "204.12.192.220" = [ "developer.nvidia.com" ];
      "50.7.85.222" = [ "www.canva.com" ];
      "204.12.192.222" = [
        "chatgpt.com"
        "ab.chatgpt.com"
        "auth.openai.com"
        "auth0.openai.com"
        "platform.openai.com"
        "cdn.oaistatic.com"
        "files.oaiusercontent.com"
        "cdn.auth0.com"
        "tcr9i.chat.openai.com"
        "webrtc.chatgpt.com"
        "api.openai.com"
        "x.ai"
        "www.x.ai"
        "sora.com"
        "gemini.google.com"
        "aistudio.google.com"
        "generativelanguage.googleapis.com"
        "alkalimakersuite-pa.clients6.google.com"
        "aitestkitchen.withgoogle.com"
        "webchannel-alkalimakersuite-pa.clients6.google.com"
        "o.pki.goog"
        "labs.google"
        "notebooklm.google"
        "notebooklm.google.com"
        "copilot.microsoft.com"
        "sydney.bing.com"
        "edgeservices.bing.com"
        "api.spotify.com"
        "xpui.app.spotify.com"
        "appresolve.spotify.com"
        "login5.spotify.com"
        "gew1-spclient.spotify.com"
        "spclient.wg.spotify.com"
        "api-partner.spotify.com"
        "aet.spotify.com"
        "www.spotify.com"
        "accounts.spotify.com"
        "claude.ai"
        "www.notion.so"
        "www.intel.com"
      ];
      "204.12.192.219" = [
        "android.chat.openai.com"
        "aisandbox-pa.googleapis.com"
      ];
      "204.12.192.221" = [
        "operator.chatgpt.com"
        "alkalimakersuite-pa.clients6.google.com"
        "assistant-s3-pa.googleapis.com"
        "rewards.bing.com"
      ];
      "50.7.87.85" = [
        "proactivebackend-pa.googleapis.com"
        "codeium.com"
      ];
      "50.7.85.221" = [
        "xsts.auth.xboxlive.com"
        "api.individual.githubcopilot.com"
      ];
      "138.201.204.218" = [
        "encore.scdn.co"
        "ap-gew1.spotify.com"
      ];
      "50.7.87.84" = [
        "login.app.spotify.com"
        "api.github.com"
      ];
    };
  };



  ##################
  # Virtualisation #
  ##################
  programs.virt-manager.enable = true;
  virtualisation = {
    spiceUSBRedirection.enable = true;
    docker = {
      enable = true;
      storageDriver = "zfs";
    };
    libvirtd = {
      enable = true;
    };
  };  




  #########
  # Sound #
  #########
  services = {
    pulseaudio.enable = false;
    pipewire = {
      enable = true;
      pulse.enable = true;
      alsa.enable = true;
      audio.enable = true;
      jack.enable = true;
      wireplumber.enable = true;
    };
  };




 ############
 # Security #
 ############
 security = {
    apparmor = {
      enable = true;
    };
    polkit.enable = true;
    sudo = {
      enable = true;
      execWheelOnly = true; 
      wheelNeedsPassword = false;
    };
  };
 
 programs = {
    #mtr.enable = true;
    #gnupg.agent.enable = true;
    seahorse.enable = true;
  };



  
  ############
  # Services #
  ############
  services = {
    flatpak.enable = true;
    printing.enable = true;
    irqbalance.enable = true;
    fwupd.enable = true; 
    dbus.implementation = "broker";   
    ananicy = {
      enable = true;
      package = pkgs.ananicy-cpp;
      rulesProvider = pkgs.ananicy-rules-cachyos_git;
    };
    zfs = {
      autoScrub.enable = true;
      trim.enable = true;
    };
  };

  zramSwap = {
    enable = true;
    algorithm = "zstd";
    memoryPercent = 25;
  };

  hardware.opentabletdriver.enable = true;

  systemd.oomd = {
    enable = true;
    enableRootSlice = true;
    enableSystemSlice = true;
    enableUserSlices = true;
  };



  ########
  # User #
  ########
  users.users.wenemous = {
    isNormalUser = true;
    description = "Wenemous Turnip";
    uid = 1000;
    extraGroups = [ "wheel" "docker" "input" "kvm" "libvirt" "storage" "video" "audio"  "networkmanager" ];
    packages = with pkgs; [
      tree
      fastfetch
      telegram-desktop
      google-chrome
      github-desktop
      easyeffects
      gnome-tweaks
      clapper
      firefox    
    ];
  };

  nixpkgs.overlays = [
    (final: prev: {
      google-chrome = prev.google-chrome.override {
        commandLineArgs = [
          "--enable-features=TouchpadOverscrollHistoryNavigation"
        ];
      };
    })
  ];


  #################
  # Nixos-related #
  #################
  nixpkgs.config.allowUnfree = true;
  nix.settings.experimental-features = [ "nix-command" "flakes" ];
  environment.sessionVariables.NIXOS_OZONE_WL = "1";



  ############
  # Packages #
  ############
  environment = {
    systemPackages = with pkgs; [

    # # # # # #
    # Non-gui #
    # # # # # #
    vim
    sbctl
    adw-gtk3
    morewaita-icon-theme
    libsecret
    wget
    git
    zfs_cachyos
    android-tools
    payload-dumper-go
    unzip
    zip

    # # # #
    # Gui #
    # # # #
  
    ];
  };




  ##################
  # Do not touch!! #
  ##################
  system.stateVersion = "25.05"; # Do not touch!!

}

