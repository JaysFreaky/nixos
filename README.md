# NixOS Flake
This is my flake for a multi-system NixOS installation. I've tried to craft it to be as secure as possible without being a complete inconvenience to the average user. I run GNOME on my laptop(s) because I feel like it is the most integrated way of fully utilizing the system's features; This means declaring nearly all settings via nix or dconfs to achieve reproducability.

---
## Installation
The system's are entirely declarative, even using [disko](https://github.com/nix-community/disko) to format & partition the drives before installing the OS. Be sure to setup/remove [sops-nix](https://github.com/Mic92/sops-nix) prior to building the system, or else you won't be able to login, as the user password is stored as a secret.

To deploy this flake, boot the installer image and run these commands as root:

```
nix --experimental-features 'nix-command flakes' run github:nix-community/disko -- --mode disko --flake github:JaysFreaky/nixos#<HOST>
mkdir -p /mnt/etc/nixos && cd $_
git clone --origin nixos https://github.com/JaysFreaky/nixos.git /mnt/etc/nixos
git remote set-url nixos git@github.com:JaysFreaky/nixos.git
```

* If this is the first system being setup, you'll need to initialize your .sops.yaml and secrets/secrets.yaml - check [sops-nix's github](https://github.com/Mic92/sops-nix) for instructions.

* If this is an additional system being added, from an already established system, you'll need to add the new system's ssh-to-age key to your .sops.yaml and run `sops updatekeys secrets/secrets.yaml` and then transfer those files to the new system's '/mnt/etc/nixos' via scp.

Because this is git repo, you'll need to run the installer command from a nix-shell environment:

```
nix-shell -p git
nixos-install --no-root-passwd --flake .#<HOST>
```

---
## Breakdown
The main flake.nix contains all your typical inputs/outputs, nixosConfigurations, and some custom variables.

### Hosts
Inside /hosts:

* common.nix is the base system configuration that is imported with each system, alongside their specific configs. Base programs, fonts, nix settings, users, etc are set here.
* Each system will then have its own directory with its configuration file(s) inside of it.

### Modules
This is where all modules imported via their directory through /hosts/common.nix live. Each directory has a default.nix that declares/imports the individual modules. You'll notice that some of these utilize custom options to easily enable them with boolean values in the system configurations - others are enabled just by being imported initially.

Inside /modules:

* /desktops contain the individual desktop environments and their requirements (GNOME/Hyprland/KDE)
* /hardware contains the configs to enable individual hardware on systems (audio, bluetooth, fingerprint reader, dedicated GPU hardware)
* /programs contain apps that can be enabled/disabled, the contents didn't seem like a good fit, or the code was too long to go inside /hosts/common.nix

I'm not very experienced with neovim yet, so I haven't bothered to translate (and I'm not sure that I will) [Kickstart.nvim](https://github.com/nvim-lua/kickstart.nvim) into Nix's format; I'm just importing the lua files/directories via Home Manager's xdg.configFile.<name>.source feature.

---
## Credits
The flake itself was based off of [Matthias Benaets' config](https://github.com/MatthiasBenaets/nixos-config). When I was first looking into converting my config into a flake, a lot of the flakes I came across would use a separate system and home file for the same module. I finally came across Matthia's config, and after looking through their repo, I decided to replicate their setup. I liked the idea of a base configuration.nix for all hosts, and most importantly, modules declared in a single file, instead of spread throughout the repo.

I'm sure there are plenty more repos I took inspiration from, but they allude me at this time.
