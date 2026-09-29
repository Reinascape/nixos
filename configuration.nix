# Edit this configuration file to define what should be installed on
# your system. Help is available in the configuration.nix(5) man page, on
# https://search.nixos.org/options and in the NixOS manual (`nixos-help`).

{ config, lib, pkgs, inputs, ... }:

{
  imports =
    [ # Include the results of the hardware scan.
      ./hardware-configuration.nix
    ];

  boot = {
    initrd = {
      # Systemd
      systemd.enable = true;

      # To get Plymouth worked on new Intel Xe-driver.
      availableKernelModules = [ "xe" ];
    };

    # KVMFR Kernel Modules
    initrd.kernelModules = [ "kvmfr" ];
    extraModulePackages = [ config.boot.kernelPackages.kvmfr ];

    # Lanzaboote
    lanzaboote = {
      enable = true;
      pkiBundle = "/var/lib/sbctl";
    };   

    loader = {
      efi.canTouchEfiVariables = true;
      systemd-boot.enable = lib.mkForce false; # Conflict with Lanzaboote.
    };

    # Quiet boot
    consoleLogLevel = lib.mkForce 3;
    initrd.verbose = false;
    loader.timeout = 0;
    plymouth.enable = true;
    loader.systemd-boot = {
      editor = false;
      configurationLimit = 10;
      consoleMode = "2";
    };

    kernelParams = [
      # Disable all mitigations
      "mitigations=off"
      "nopti"
      "tsx=on"
      "kernel.split_lock_mitigate=0"

      # Disable Watchdog
      "nowatchdog"      

      # Quiet boot
      "quiet"
      "splash"
      "loglevel=3"
      "rd.udev.log_level=3"
      "boot.shell_on_fail"
      "udev.log_priority=3"
      "rd.systemd.show_status=auto"
      "vt.global_cursor_default=0"
      
      # KVMFR
      "kvmfr.static_size_mb=64"

      # Xe-driver
      "i915.force_probe=!46a3"
      "xe.force_probe=46a3"

      # Zswap
      "zswap.enabled=0"
    ];
        
    # Fucking annoying
    blacklistedKernelModules = [ "nouveau" "iTCO_wdt" ];

    # Sysctl
    kernel.sysctl = {
      # Dirty Pages
      "vm.dirty_background_bytes" = 67108864;
      "vm.dirty_bytes" = 1073741824;
      "vm.dirty_expire_centisecs" = 1500;
      "vm.dirty_writeback_centisecs" = 500;

      # Memory mapping
      "vm.max_map_count" = 2147483642;

      # Enable all SysRq shortcuts
      "kernel.sysrq" = 1;

      # Disable Watchdog
      "kernel.watchdog" = 0;

      # Disable Split Lock
      "kernel.split_lock_mitigate" = 0;

      # MGLRU Page Trashing
      "vm.lru_gen_min_ttl_ms" = 2000;
    };
                             
    # Kernel
    kernelPackages = pkgs.linuxPackages_cachyos;
  }; 

  # MGLRU Page Trashing
  systemd.tmpfiles.settings."10-mglru" = {
    "/sys/kernel/mm/lru_gen/min_ttl_ms"."w!" = {
      argument = "2000";
    };
  };

  # Disable I/O scheduler for NVMe disks.
  services.udev.extraRules = ''
    ACTION=="add|change", KERNEL=="nvme[0-9]*n[0-9]*", ATTR{queue/rotational}=="0", ATTR{queue/scheduler}="none"
  '';
      
  # Impermanence
  boot.initrd.systemd.services.rollback-root = {
    description = "Rollback / subvolume to pristine state";
    wantedBy = [ "initrd.target" ];
    after = [ "dev-disk-by\\x2dlabel-NIXOS.device" ];
    before = [ "sysroot.mount" ];
    path = [ pkgs.btrfs-progs pkgs.coreutils ];
    unitConfig.DefaultDependencies = "no";
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
    };

    script = ''
      MNT="/tmp/btrfs-root"
      mkdir -p "$MNT"
      mount -t btrfs -o subvol=/ /dev/disk/by-label/NIXOS "$MNT"

      if [ -e "$MNT/@" ]; then
        echo "--> Deleting old @ subvolume..."
        btrfs subvolume delete "$MNT/@"
      fi

      echo "--> Restoring blank / from @-blank..."
      btrfs subvolume snapshot "$MNT/@-blank" "$MNT/@"

      umount "$MNT"
      rmdir "$MNT"
    '';
  };

  # Persistence
  environment.persistence."/persist" = {
    hideMounts = true;
    directories = [
      "/etc/nixos"
      "/etc/ssh"
      "/etc/NetworkManager/system-connections"
      "/var/lib/nixos"     
      "/var/lib/systemd"
      "/var/lib/bluetooth"
      "/var/lib/sbctl"
      "/var/lib/flatpak"
      "/var/lib/containers"
      "/var/lib/cups"
      { directory = "/var/lib/iwd"; mode = "u=rwx,g=,o="; }
    ];
    files = [
      "/etc/machine-id"
    ];
    users.root = {
      directories = [
        { directory = ".android"; mode = "0700"; } # adb keys
        { directory = ".gnupg"; mode = "0700"; }
        { directory = ".ssh"; mode = "0700"; }
      ];
    };
  };
  
  # OpenSSH
  services.openssh.hostKeys = [
    {
      path = "/persist/etc/ssh/ssh_host_rsa_key";
      type = "rsa";
      bits = 4096;
    }  
  ];

  # MachineID
  environment.etc."machine-id".source = "/persist/etc/machine-id";


  hardware = {
    # Intel microcode
    cpu.intel.updateMicrocode = true;

    # Graphics
    graphics = {
      enable = true;
      extraPackages = with pkgs; [
	intel-media-driver
	intel-compute-runtime
      ];
    };
  };

  # LIBVA
  environment.sessionVariables = { LIBVA_DRIVERS_NAME = "iHD"; };
  

  # GNOME
  services = {
    displayManager.gdm.enable = true;
    desktopManager.gnome.enable = true;
  };

  # To fix GDM scaling.
  systemd.tmpfiles.settings."10-gdm-monitors" = {
    "/run/gdm/.config/monitors.xml"."L+" = {
      argument = "${pkgs.writeText "gdm-monitors.xml" ''
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
                  <vendor>CS0</vendor>
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
      ''}";
    };
  };


  # Locales
  i18n = {
    defaultLocale = "en_US.UTF-8";
    supportedLocales = [ "all" ];
  };

  # Fonts
  fonts.packages = with pkgs; [
    noto-fonts
    font-awesome
    liberation_ttf
    noto-fonts-cjk-sans
    noto-fonts-cjk-serif
    noto-fonts-color-emoji
    corefonts
    vista-fonts
  ];

  # Timezone
  time.timeZone = "Europe/Moscow";


  # Networking
  networking = {
    # Hostname
    hostName = "NixOS";

    # NetworkManager
    networkmanager = {
      enable = true;
      #wifi.backend = "iwd";
      dns = "systemd-resolved";
    };
    #wireless.iwd.enable = true;
    nftables.enable = true;

    # Disable non-NetworkManager.
    useDHCP = false;

    # Firewall
    firewall = {
      enable = true;
      trustedInterfaces = [ "virbr0" ];
    };
  };

  # DNS
  services.resolved.enable = true;

  # Bluetooth
  hardware.bluetooth = {
    enable = true;
    package = pkgs.bluez5-experimental;
    settings.General.Experimental = true;
  };
  services.blueman.enable = true;

  # CUPS
  services.printing.enable = true;

  # iOS Connection
  services.usbmuxd.enable = true;

  # OpenSSH
  services.openssh.enable = true;

  # KDEconnect
  programs.kdeconnect = {
    enable = true;
    package = pkgs.gnomeExtensions.gsconnect;
  };

  # Happ
  programs.happ = {
    enable = true;
    tunMode.enable = true;
  };


  # Virtualisation
  virtualisation = {
    # Podman
    podman = {
      enable = true;
      dockerCompat = true; 
    };

    # Libvirt
    libvirtd = {
      enable = true;
      onBoot = "ignore";
      onShutdown = "shutdown";
      firewallBackend = "nftables";
      # KVMFR
      qemu.verbatimConfig = ''
        namespaces = []
        cgroup_device_acl = [
          "/dev/null", "/dev/full", "/dev/zero",
          "/dev/random", "/dev/urandom",
          "/dev/ptmx", "/dev/kvm", "/dev/kqemu",
          "/dev/rtc", "/dev/hpet", "/dev/vfio/vfio",
          "/dev/kvmfr0"
        ];
      '';
    };
 
    # Spice
    spiceUSBRedirection.enable = true;
  };

  # Virt-Manager
  programs.virt-manager.enable = true; 
 
  # KVMFR
  services.udev.packages = lib.singleton (pkgs.writeTextFile
    {
      name = "kvmfr";
      text = ''
        SUBSYSTEM=="kvmfr", GROUP="kvm", MODE="0660", TAG+="uaccess"
      '';
      destination = "/etc/udev/rules.d/70-kvmfr.rules";
    }
  );


  # PipeWire
  services = {
    pipewire = {
      enable = true;
      pulse.enable = true;
      alsa.enable = true;
      audio.enable = true;
      wireplumber.enable = true;
      extraConfig.pipewire = {
        # Disable resampling to get better quality.
        "20-no-resampling" = {
          "context.properties" = {
            "default.clock.rate" = 48000;
            "default.clock.allowed-rates" = [ 44100 48000 96000 192000 ];
          };
        };
        # Adjust min buffer size to eliminate noise under load.
        "10-sound" = {
          "context.properties" = {
            "default.clock.quantum" = 4096;
            "default.clock.min-quantum" = 512;
            "default.clock.max-quantum" = 8192;
          };
        };
      };
    };
    pulseaudio.enable = false;
  };
  security.rtkit.enable = true;
  environment.variables.AE_SINK = "ALSA";
  environment.variables.SDL_AUDIODRIVER = "pipewire";
  environment.variables.ALSOFT_DRIVERS = "pipewire";


  # Security
  security = {
    # AppArmor
    apparmor.enable = true;
    # Google Authenticator
    pam.services.sshd.googleAuthenticator.enable = true;
    # Sudo
    polkit.enable = true;
    sudo = {
      enable = true;
      execWheelOnly = true;
      wheelNeedsPassword = false;
    };
  };

  # Keyring
  programs.seahorse.enable = true;
  programs.gnupg.agent = {
    enable = true;
    enableSSHSupport = true;
  };

  # Services
  services = {
    # OOM Killer
    earlyoom.enable = true;
    # irqbalance
    irqbalance.enable = true;
    # DBus
    dbus.implementation = "broker";
    # Ananicy
    ananicy = {
      enable = true;
      package = pkgs.ananicy-cpp;
      rulesProvider = pkgs.ananicy-rules-cachyos_git; # Change to _git if using chaotic-nyx.
    };
  };

  # ZRAM
  zramSwap = {
    enable = true;
    algorithm = "zstd";
    memoryPercent = 25;
    priority = 100;
  };

  boot.kernel.sysctl = {
    "vm.swappiness" = 60;
    "vm.page-cluster" = 0;
  };

  # OpenTabletDriver
  hardware.opentabletdriver.enable = true;


  # Users
  users.users.rscape = {
    isNormalUser = true;
    description = "Reinascape";
    uid = 1000;
    extraGroups = [ 
      "wheel"
      "users" 
      "input" 
      "storage" 
      "video"
      "audio"
      "networkmanager" 
      "adbusers"
      "systemd-journal"

      # Virtualisation
      "docker"
      "libvirt"
      "libvirtd"
      "kvm"
    ];
  };


  # Packages
  environment = {
    systemPackages = with pkgs; [
      # GNOME-related
      adw-gtk3
      morewaita-icon-theme

      # Android-related
      android-tools
      payload-dumper-go

      # Files
      unzip
      unrar
      zip
      p7zip

      # Tools
      gh
      wget

      # System
      sbctl
      libsecret
    ];
  };

  # User packages
  users.users.rscape.packages = with pkgs; [
    tree
    gnome-tweaks
    fastfetch
    looking-glass-client
    libreoffice    

    # Development
    github-desktop
    python3
    zed-editor
    distrobox

    # Media
    file-roller
    clapper
    clapper-enhancers

    # Web
    telegram-desktop
    tor-browser

    # Chrome
    (google-chrome.override { commandLineArgs = [ 
      "--enable-features=TouchpadOverscrollHistoryNavigation,WebRtcHideLocalIpsWithMdns,Vulkan,SkiaGraphite,VaapiVideoEncoder,AcceleratedVideoDecodeLinuxGL,VaapiIgnoreDriverChecks"
      "--enable-zero-copy"
      "--enable-gpu-rasterization"
      "--ignore-gpu-blocklist"
      "--use-vulkan"
      "--use-angle=vulkan"
      "--enable-skia-graphite" 
    ]; })
  ];

  programs = {
    # ccache
    ccache.enable = true;
    # GameMode
    gamemode.enable = true;
    # Firefox
    firefox.enable = true;
    # Git
    git.enable = true;
    git.lfs.enable = true;
    # Neovim
    neovim.enable = true;
  };

  # Flatpak
  services.flatpak.enable = true;

  # NixOS/Nix
  nixpkgs.config.allowUnfree = true;
  nix.package = pkgs.nixVersions.latest;
  # Tank more of my internet connection.
  nix.extraOptions = ''
    max-substitution-jobs = 30
    http-connections = 50
  '';
  # Automatically removes NixOS' older builds.
  nix.gc = {
    automatic = true;
    dates = "weekly";
    options = "--delete-older-than 7d";
  };
  nix.settings = {
    experimental-features = [ "nix-command" "flakes" ];
    trusted-users = [ "root" "rscape" ];
    
    # More caches
    substituters = [ "https://nix-community.cachix.org/" ];
    trusted-public-keys = [
      "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
    ];

    # Deduplication
    auto-optimise-store = true;

    # Use all cores for building.
    max-jobs = "auto";
  };
  environment.sessionVariables.NIXOS_OZONE_WL = "1";


  # This option defines the first version of NixOS you have installed on this particular machine,
  # and is used to maintain compatibility with application data (e.g. databases) created on older NixOS versions.
  #
  # Most users should NEVER change this value after the initial install, for any reason,
  # even if you've upgraded your system to a new NixOS release.
  #
  # This value does NOT affect the Nixpkgs version your packages and OS are pulled from,
  # so changing it will NOT upgrade your system - see https://nixos.org/manual/nixos/stable/#sec-upgrading for how
  # to actually do that.
  #
  # This value being lower than the current NixOS release does NOT mean your system is
  # out of date, out of support, or vulnerable.
  #
  # Do NOT change this value unless you have manually inspected all the changes it would make to your configuration,
  # and migrated your data accordingly.
  #
  # For more information, see `man configuration.nix` or https://nixos.org/manual/nixos/stable/options#opt-system.stateVersion .
  system.stateVersion = "26.05"; # Did you read the comment?

}
