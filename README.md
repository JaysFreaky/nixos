# NixOS Flake
This is my flake for a multi-system NixOS installation. I've tried to craft it to be as secure as possible without being a complete inconvenience to the average user. I run GNOME on my laptop(s) because I feel like it is the most integrated way of fully utilizing the system's features; This means declaring nearly all settings via nix or dconfs to achieve reproducability.

## Installation
The system's are entirely declarative, even using [disko](https://github.com/nix-community/disko) to format & partition the drives before installing the OS. Be sure to setup/remove [sops-nix](https://github.com/Mic92/sops-nix) prior to building the system, or else you won't be able to login, as the user password is stored as a secret.

To deploy this flake, I'm booting from an .iso I built (hosts/iso), which includes the tools I need, and running these commands as root:

```
nix run github:nix-community/disko -- --mode disko --flake github:JaysFreaky/nixos#HOST
mkdir -p /mnt/etc/ssh
ssh-keygen -t ed25519 -f /mnt/etc/ssh/ssh_host_ed25519_key -C "root@HOST"
ssh-to-age -i /mnt/etc/ssh/ssh_host_ed25519_key.pub
```

* If this is an additional system being deployed:
    * From an existing, established sops system, add the newly generated age key to .sops.yaml, run `sops updatekeys secrets/secrets.yaml`, commit those files, and then proceed with the below commands.
* If this is the first time sops is being setup:
    * .sops.yaml and secrets/secrets.yaml will need to be initialized after cloning the repo - refer to [sops-nix's instructions](https://github.com/Mic92/sops-nix?tab=readme-ov-file#usage-example) - then come back here.

```
mkdir -p /mnt/etc/nixos && cd $_
git clone --origin nixos https://github.com/JaysFreaky/nixos.git /mnt/etc/nixos
git remote set-url nixos git@github.com:JaysFreaky/nixos.git
nixos-install --no-root-passwd --flake .#HOST
```

## Breakdown
```
.
├── .sops.yaml
├── assets
│  └── wallpapers
├── flake.lock
├── flake.nix
├── hosts
│  ├── common.nix
│  ├── iso
├── modules
│  ├── desktops
│  ├── hardware
│  └── programs
└── secrets
   └── secrets.yaml
```

### Hosts
* common.nix is the base system configuration that is imported with each system, alongside their specific configs. Base programs, fonts, nix settings, users, etc are set here.
* Each system has its own directory with its independent configuration file(s) inside of it.
* The iso directory is used to define & build a custom, bootable .iso file.

### Modules
This is where all modules imported via their directory through /hosts/common.nix live. Each directory has a default.nix that declares/imports the individual modules. You'll notice that some of these utilize custom options to easily enable them with boolean values in the system configurations - others are enabled just by being imported initially.

* /desktops: contain the individual desktop environments and their requirements (GNOME/Hyprland/KDE)
* /hardware: contain the configs to enable individual hardware on systems (audio, bluetooth, fingerprint reader, dedicated GPU hardware)
* /programs: contain apps that:
    * can be enabled/disabled
    * the contents didn't seem like a good fit and/or the code was too long to be inside /hosts/common.nix

I'm not very experienced with neovim yet, so I haven't bothered to translate (and I'm not sure that I will) [Kickstart.nvim](https://github.com/nvim-lua/kickstart.nvim) into Nix's format; I'm just importing the lua files & directories via Home Manager's xdg.configFile."directory/file".source feature.

# Credits
The flake itself was based off of [Matthias Benaets' config](https://github.com/MatthiasBenaets/nixos-config). When I was first looking into converting my config into a flake, practically all of the flakes I came across were using separate system and home directories/files for the same module (I understand it makes more sense to separate them, especially with a non-NixOS system using the Nix package manager, but I wasn't a fan of it). I finally came across Matthias' config, and after looking through their repo, I decided to follow suite. I liked the idea of a base configuration for all hosts, and most importantly, modules declared in a single file, instead of spread throughout both the hosts and home directories.

I'm sure there are plenty more repos I took inspiration from, but they allude me at this time.
