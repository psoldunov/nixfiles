# Installing BigKing

BigKing came with ASUSTOR's ADM. These steps replace it with NixOS over SSH, using [nixos-anywhere](https://github.com/nix-community/nixos-anywhere). They write to the two NVMe drives and nothing else. The data array on the WD Reds and ADM on the internal eMMC stay as they are, so ADM can still be booted from the eMMC afterwards.

## Before you start

- The SSD cache is gone: `ssh root@10.24.24.3 dmsetup ls` prints `No devices found`.
- Whopper's key logs in as root: `ssh root@10.24.24.3 id`.
- Nothing is writing to BigKing. Stop Plex in ADM's App Central and anything on BigTasty or Whopper that copies to the shares. The installer replaces ADM's kernel without unmounting `/volume1` first. btrfs survives that, but writes still in flight do not.
- BigKing's two switch ports are out of their LAG. The installer comes up on one port without the bond, and a LAG member that sees no LACP may pass no traffic.
- A monitor (HDMI) and a USB keyboard are within reach, in case the firmware keeps booting ADM.

## 1. Boot the installer

From the repository root on Whopper:

```sh
nix run github:nix-community/nixos-anywhere -- --flake .#BigKing --target-host root@10.24.24.3 --phases kexec
```

This switches the running system to the NixOS installer, in RAM. Nothing is written to disk yet. If BigKing does not answer on 10.24.24.3 within a few minutes, power-cycle it: it boots ADM as before.

## 2. Check the installer

The installer has its own host key, so skip the known_hosts check for this session:

```sh
ssh -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no root@10.24.24.3
ls -l /dev/disk/by-id/ | grep nvme-CT1000
cat /proc/mdstat
```

- Both `nvme-CT1000P5PSSD8_22343ABE1CCC` and `nvme-CT1000P5PSSD8_22343ABF8F10` must be listed. If the names differ, correct them in [disko.nix](disko.nix) before going on.
- Arrays built from `sd*` partitions in `/proc/mdstat` are ADM's and can stay. An array built from `nvme*` partitions is left over from the cache: stop it with `mdadm --stop /dev/mdN`, or disko cannot wipe the drives.
- Run nothing else against the `sd*` disks.

## 3. Install

```sh
nix run github:nix-community/nixos-anywhere -- --flake .#BigKing --target-host root@10.24.24.3 --phases disko,install,reboot
```

disko partitions and formats the two NVMe drives listed in [disko.nix](disko.nix), nixos-anywhere installs the system, and BigKing reboots.

## 4. First boot

If BigKing comes back as ADM, the firmware booted the eMMC. Connect the monitor and keyboard, open the firmware setup at power-on (F2 or Del), and move `Linux Boot Manager` on the first NVMe to the top of the boot order.

On Whopper, drop ADM's host key and log in. `-A` forwards the agent, which is what sudo authenticates with. Whopper gets the `bigking` alias with its next rebuild from this branch.

```sh
ssh-keygen -R 10.24.24.3
ssh -A psoldunov@10.24.24.3
```

On BigKing:

```sh
cat /proc/mdstat                  # the md root mirror shows [UU]; ADM's RAID 0 is listed too
findmnt /volume1                  # btrfs, subvol=/base
sudo btrfs device stats /volume1  # every counter 0
showmount -e localhost            # Media, Camera, Backup, Games
sudo passwd psoldunov             # a password for the console, if the network ever fails
```

Put BigKing's switch ports back in their LAG. `cat /proc/net/bonding/bond0` should then show both ports up with the same aggregator ID.

## 5. Move ADM's services over

Samba keeps its own password database:

```sh
sudo smbpasswd -a psoldunov
```

Copy Plex's library from ADM's location to the NVMe (2.7 GB). The copy at `/volume1/Plex/Library` stays as a backup. Plex keeps its server ID and claim, and the media paths are the same `/volume1` paths as before.

```sh
sudo systemctl stop plex
sudo rsync -a --delete "/volume1/Plex/Library/Plex Media Server/" "/var/lib/plex/Plex Media Server/"
sudo chown -R plex:plex /var/lib/plex
sudo systemctl start plex
```

Home-manager decrypts `SHELL_SECRETS` with the age key, which has to be copied over once, from Whopper:

```sh
ssh psoldunov@10.24.24.3 mkdir -p .config/sops/age
scp ~/.config/sops/age/keys.txt psoldunov@10.24.24.3:.config/sops/age/keys.txt
```

The next rebuild picks it up.

If an NFS mount on BigTasty or Whopper reports `Stale file handle`, unmount and mount it again. If a Mac stops backing up, choose the Time Machine share on BigKing again in its Time Machine settings; macOS offers to keep using the existing backup.

## 6. Check the front panel

The fan, LED and button drivers list the AS6604T as supported but untested, so check each part once:

```sh
lsmod | grep asustor          # asustor, asustor_it87, asustor_gpio_it87
sensors                       # it8625 with fan1 RPM; drivetemp for each disk; coretemp
systemctl status asustor-fan asustor-leds openlcmd
ls /sys/class/leds            # sata1:green:disk ... blue:lan, green:status
```

- `asustor-fan` sets the fan speed every 10 seconds from the hottest disk and the CPU. Watch `sensors` for a few minutes: the RPM should follow the temperatures, and the disks should stay under about 45 °C. The curve is in [modules/asustor/default.nix](modules/asustor/default.nix). When the service stops, it leaves the fan at full speed under firmware control.
- The disk LEDs blink with disk activity (all four together), the LAN LED follows `bond0`, and the status LED turns steady green.
- The LCD shows the hostname and IP address. If it still shows ADM's last message, check `journalctl -u openlcmd`.

If `asustor` does not load or an LED stays dark, `sudo dmesg | grep -i asustor` shows why. Disabling `hardware.asustor.enable` and the three services in [modules/asustor/default.nix](modules/asustor/default.nix) returns the box to firmware fan control.

## 7. From now on

Merge this branch. `rebuild_system BigKing` and the `rebuild-bigking` Ensemblr script then work as they do for BigTasty: the build runs on BigKing, and sudo authenticates with the forwarded agent.

## Going back to ADM

ADM is still on the eMMC. Put the eMMC first in the firmware's boot order and ADM boots with the data volume as it was, minus the SSD cache and with NixOS on the NVMe drives.
