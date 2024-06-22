# NixOS Flake
This is my flake for a multi-system NixOS installation. I've tried to craft it to be as secure as possible without being a complete inconvenience to the average user. I run GNOME on my laptop(s) because I feel like it is the most integrated way of fully utilizing the system's features. This means declaring nearly all settings via nix or dconfs to achieve reproducability.

---
## Installation
While you can clone this repo and build on your system, I created a guided install script which prepares the system for NixOS:

* Scans and prompts for disk selection to use for installation
* Prompts for creating either a file or partition for swap, based on system RAM, or no swap at all
* Prompts for what user name is declared in the flake
* Prompts to set the user password and then generates a hashed password file named after the user
* Prompts to set a GRUB2 password and then generates a hashed password file (systemd is used by default, but is set for future use)
* Creates boot, swap (if used), and root partitions
* Prompts for encryption, and if selected:
  * Prompts for cryptkey and cryptroot passwords (cryptkey is used at every boot; cryptroot is a backup in the case cryptkey gets corrupted.)
  * Creates a key partition and generates a random key for unlocking
  * Encrypts key, swap (if used), and root partitions
  * Backs up LUKS headers for key & root partitions
* Clones this repo into the /etc/nixos config directory
* Select an existing system hostname based off of entries in the flake
* Generates and commits a swap.nix file to the local repo before install (if used)
* Install NixOS

Now for the fun part! To start the installation script from within the NixOS installer, run the following as root:

`nix run github:JaysFreaky/nixos#setup-system --experimental-features "nix-command flakes"`

---
## Breakdown
The main flake.nix contains all your typical inputs/outputs, nixosConfigurations, some custom variables, as well as the setup package that is used for formatting/preparing/installing the system.

### Hosts
Inside /hosts:

* common.nix is the base system configuration that is imported with each system, alongside their specific configs. Base programs, fonts, nix settings, users, etc are set here.
* Each system will then have its own directory with their configuration file(s) inside of it. If swap was setup during install, there will also be a swap.nix file generated inside the deployed system's directory.

### Modules
This is where all modules imported via directory through /hosts/common.nix live. Each directory has a default.nix that declares/imports the individual modules. You'll notice that some of these utilize custom options to easily enable them with boolean values in the system configurations - others are enabled just by being imported initially.

Inside /modules:

* /desktops contain the individual desktop environments and their requirements (GNOME/Hyprland)
* /hardware contains the configs to enable individual hardware on systems (audio, bluetooth, fingerprint reader)
* /programs contain apps that can be enabled/disabled or the contents didn't seem like a good fit and/or are too long to go inside /hosts/common.nix

I'm not very experienced with neovim yet, so I haven't bothered to translate (and not sure that I will) [Kickstart.nvim](https://github.com/nvim-lua/kickstart.nvim) into Nix's format; I'm just importing the lua files/directories via Home Manager's xdg.configFile.<name>.source feature.

### Packages
This is where the setup script lives. If there were any future scripts/packages I would want to call individually, they would go into their own respective directory.

Inside /packages:

* /framework-plymouth creates a derivation for a custom framework boot logo
* /setup-system contains the package declaration and setup script used for initial install

---
## Credits
The actual flake itself was based off of [Matthias Benaets' config](https://github.com/MatthiasBenaets/nixos-config). When I was first looking into converting my config into a flake, a lot of the flakes I came across would use a separate system and home file for the same module. I finally came across Matthia's config, and after looking through their repo, I decided to replicate their setup. I liked the idea of a base configuration.nix for all hosts, and most importantly, modules declared in a single file, instead of spread throughout the repo.

The installation script was based off of [Hoverbear-Consulting's unsafe-bootstrap](https://github.com/Hoverbear-Consulting/flake/tree/root/packages/unsafe-bootstrap). My original script was your typical bash script that simply partitioned, encrypted, and formatted the drive. Then I came across their method, and I really liked the idea of being able to call the script as a flake package, as well as the use of Gum to make the script look better and be more interactive. I converted all my typical echos and reads into Gum's way of doing things. Over time, I modified and added to it from being a simple formatting script into a full-blown install script.

I'm sure there are plenty more repos I took inspiration from, but they allude me at this time.
