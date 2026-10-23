# Installing ShackStack

ShackStack is the living-room PC. It ran Bazzite until NixOS replaced it on 2026-10-19. These steps wipe its NVMe and install NixOS over the network with [nixos-anywhere](https://github.com/nix-community/nixos-anywhere): the running system kexecs into the installer, so no USB stick is needed. Steam downloads the games again afterwards.

The saves were copied off before the wipe, to BigKing's `/volume1/Backup/ShackStack-bazzite` (about 1.7 GB):

- `userdata/`: Steam's per-account folder (controller layouts, shortcuts, local saves).
- `steamapps/compatdata/<appid>/pfx/drive_c/users/steamuser/{Documents,Saved Games,AppData}`: saves inside each game's Proton prefix.
- `steamapps/appmanifest_<appid>.acf`: which app ID is which game.

## Before you start

- The backup is there: `ssh bigking du -sh /volume1/Backup/ShackStack-bazzite`.
- Optional, on Bazzite: the CEC standby test under [TV and HDMI-CEC](#tv-and-hdmi-cec). It tells you before the wipe whether CEC can wake the TV.
- Whopper has been rebuilt from this branch. The install itself doesn't need that, but `rebuild_system ShackStack` afterwards needs the `shackstack` SSH alias and `~/.ssh/sudo-shackstack` it brings.
- Bazzite allows kexec: `cat /proc/sys/kernel/kexec_load_disabled` prints `0` and `/sys/kernel/security/lockdown` shows `[none]`. With Secure Boot off, both are the default.

## 1. Give nixos-anywhere root

nixos-anywhere logs in as root. Bazzite has no root key, so copy yours over once. sudo asks for the Bazzite password:

```sh
ssh -t psoldunov@10.24.24.7 'sudo install -d -m 700 /root/.ssh && sudo install -m 600 -o root -g root ~/.ssh/authorized_keys /root/.ssh/authorized_keys && sudo restorecon -R /root/.ssh'
```

`restorecon` gives the files their SELinux labels; without it sshd ignores the key.

## 2. Boot the installer

From the repository root on Whopper:

```sh
nix run github:nix-community/nixos-anywhere -- --flake .#ShackStack --target-host root@10.24.24.7 -i ~/.ssh/sudo-whopper --ssh-option UserKnownHostsFile=/dev/null --ssh-option StrictHostKeyChecking=no --phases kexec
```

Bazzite kexecs into the NixOS installer, in RAM, with the same address and host key. Nothing is written to disk yet; a power cycle boots Bazzite again. Then check the installer:

```sh
ssh -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no root@10.24.24.7 'ls -l /dev/disk/by-id/ | grep nvme-Samsung; ip -br link'
```

- `nvme-Samsung_SSD_980_PRO_2TB_S69ENX0TA25215J` must be listed. If the name differs, correct it in [disko.nix](disko.nix) before going on.
- The wired port must be `enp7s0`. If it isn't, change `interface-name` in [modules/networking.nix](modules/networking.nix).

If kexec ever fails, a USB stick with the NixOS minimal ISO does the same job: boot it in UEFI mode, `sudo passwd root`, `ssh-copy-id` from Whopper, and use its DHCP address below.

## 3. Install

```sh
nix run github:nix-community/nixos-anywhere -- --flake .#ShackStack --target-host root@10.24.24.7 -i ~/.ssh/sudo-whopper --ssh-option UserKnownHostsFile=/dev/null --ssh-option StrictHostKeyChecking=no --phases disko,install,reboot
```

Whopper builds the system, so the HTPC compiles nothing. disko wipes and partitions the 980 PRO as [disko.nix](disko.nix) describes, nixos-anywhere copies the system over, and ShackStack reboots. The first time this took under three minutes.

## 4. First boot

ShackStack boots straight into Gaming Mode, where Steam updates itself and then asks you to sign in. The network is already up (static `10.24.24.7`). Bluetooth pairings did not survive the wipe: pair the controllers again in Steam's Bluetooth settings.

On Whopper, drop the old host key and log in. `-A` forwards the agent, which is what sudo authenticates with:

```sh
ssh-keygen -R 10.24.24.7
ssh -A shackstack
```

The account starts with a locked password, so plain `passwd` has no current password to check. Set one through sudo, which accepts the forwarded agent, for local sudo and Plasma's prompts:

```sh
sudo passwd psoldunov
```

From then on, update it like any other host: `rebuild_system ShackStack`, or the `rebuild-shackstack` run script. When it is asleep, `rebuild_system all` and the `-all` run scripts skip it with a warning.

`shackstack-sleep` suspends it from Whopper or a Mac over ssh, and the TV goes to standby with it. `shackstack-wake` sends a Wake-on-LAN packet to `cc:28:aa:86:dd:6a` to bring it back. Wake-on-LAN from suspend has not been tested yet.

### Restore saves

Steam Cloud brings most saves back by itself. For the rest, run these on ShackStack after `ssh -A shackstack`, so the forwarded agent opens BigKing too. ShackStack has no `bigking` alias, so the commands use its address.

1. Switch to Desktop. Steam starts there in the tray: quit it from the tray icon.
2. Copy Steam's per-account folder back:

   ```sh
   rsync -a psoldunov@10.24.24.3:/volume1/Backup/ShackStack-bazzite/userdata/ ~/.local/share/Steam/userdata/
   ```

3. Copy the saves from each game's Proton prefix back, whether the game is installed yet or not. Steam Cloud does the same: it wrote Silent Hill 2's saves into a prefix Proton had not created yet. The command skips prefixes that already exist and files already in place, and leaves out the installer logs in `Temp`:

   ```sh
   cd ~/.local/share/Steam/steamapps/compatdata
   rsync -a -m --ignore-existing $(for d in */; do echo "--exclude=/$d"; done) --exclude=/0/ --exclude='/*/pfx/drive_c/users/steamuser/AppData/Local/Temp/' psoldunov@10.24.24.3:/volume1/Backup/ShackStack-bazzite/steamapps/compatdata/ ./
   ```

   `grep '"name"' /volume1/Backup/ShackStack-bazzite/steamapps/appmanifest_<appid>.acf` on BigKing shows which game an app ID is.

4. Return to Gaming Mode.

Done on 2026-10-19: 818 files (213 MB) of `userdata`, and Proton saves for 23 games (3,072 files, 1.5 GB). Silent Hill 2 was already installed with its cloud saves, so its prefix was left alone. Not checked yet: that each of the 23 games finds its saves on its first launch.

### Decky Loader

Open the Quick Access menu, then Decky's store, and install SteamGridDB. Bazzite Buddy depended on Bazzite and is gone. If Decky's tab is missing, check that `~/.local/share/Steam/.cef-enable-remote-debugging` exists (Home Manager creates it) and restart Steam.

## TV and HDMI-CEC

The TV is on HDMI 4 (CEC physical address `4.0.0.0`). CEC goes through the DP→HDMI adapter: amdgpu tunnels it over DisplayPort and exposes it as `/dev/cec0`.

On Bazzite the CEC hooks existed (`cec-onboot`, `cec-onsleep`, `cec-onpoweroff`) but all three were disabled, and Valve's `cecd` was masked, so nothing ever sent a CEC message. ShackStack runs its own version of those hooks ([modules/tv-cec](modules/tv-cec/default.nix)):

| Unit | When | What |
|---|---|---|
| `shackstack-tv-on` | Boot and every resume | TV on (Image View On), then switch it to this input (Active Source) |
| `shackstack-tv-sleep` | Before suspend | TV to standby |
| `shackstack-tv-poweroff` | Power-off, not reboot | TV to standby |

The TV remote's arrows, OK and Back reach Steam as Enter, the arrow keys and Esc ([steam-remote.toml](modules/tv-cec/steam-remote.toml)).

### TV settings

On the Bravia, under External inputs, then BRAVIA Sync settings: turn on BRAVIA Sync control, Device auto power off and TV auto power on. Set HDMI 4's signal format to the enhanced one, which 4K@120 and VRR need.

### Tests

Run these on ShackStack. The ones marked (Bazzite) also work before the wipe, since Bazzite has `cec-ctl`.

1. (Bazzite) With the TV on: `cec-ctl -d0 | grep 'Physical Address'` shows `4.0.0.0`.
2. (Bazzite) The standby test. Put the TV in standby with its remote, wait 10 seconds, then run `ls /dev/cec*; cec-ctl -d0 | grep 'Physical Address'`.
   - Still `4.0.0.0`: CEC can wake the TV. Check with `cec-ctl -d0 --to 0 --image-view-on`.
   - `f.f.f.f`, or no device: the TV drops hotplug in standby, and the adapter can't send anything until it comes back. The TV then has to be turned on with its remote. `shackstack-tv-on` logs this and gives up after 15 seconds; everything else still works. Waking the TV over the network (Sony IP control) is in the backlog for this case, as THE-300 in Linear.
3. (Bazzite) With the TV on, run `cec-ctl -d0 -M` and press the remote's arrows and OK. `USER_CONTROL_PRESSED` lines must appear.
4. `shackstack-tv standby`, then `shackstack-tv on`. The TV turns off, then on, and switches to HDMI 4.
5. Suspend from Steam's power menu five times and wake with a controller each time. The TV goes to standby and comes back on HDMI 4, and the controller stays on. Then power off and on twice. `journalctl -b -u 'shackstack-tv-*' -u shackstack-pad-wake` shows what each run did.
6. `sudo ir-keytable -t -s rc0` prints the keys as you press the remote (`ir-keytable` alone lists the rc devices, if the CEC one isn't `rc0`). Steam's menus move with the arrows and OK.

### When the TV stops answering after a suspend

The adapter loses power in suspend and forgets that its CEC tunnel is on. The kernel keeps `/dev/cec0` and its addresses across the suspend, so nothing switches the tunnel back on, and the TV acknowledges nothing. The journal then shows `Tx, Not Acknowledged (1), Max Retries` under every message. Claiming the CEC address again switches the tunnel back on, and `shackstack-tv` does that on every run. By hand:

```sh
cec-ctl -d0 --to 0 --give-device-power-status   # Not Acknowledged while the tunnel is off
cec-ctl -d0 --clear
cec-ctl -d0 --playback --osd-name ShackStack
cec-ctl -d0 --to 0 --give-device-power-status   # the TV answers with REPORT_POWER_STATUS
```

### Waking with a controller

On resume the kernel can drop the controller's first Bluetooth packet. `journalctl -k` then shows `ACL packet for unknown connection handle`, and the controller switches itself off a few seconds after waking the system. It happened on two of three resumes on 2026-10-19. `shackstack-pad-wake` runs after every resume: when a wake-allowed controller is linked but has no HID device after 0.6 seconds, it opens the HID connection from ShackStack's side. Its journal says when it had to, and whether the controller came up.

## Bazzite reference

What the old install looked like, read from it before the wipe:

| | |
|---|---|
| Image | `bazzite-deck:stable` 44.20260919, kernel `7.2.4-ogc3.1.fc44`, gamescope 3.16.29, Mesa 26.2.2. No layered packages, no `/etc` changes |
| Session | `gamescope-session-plus ogui-steam`: ChimeraOS's gamescope-session-plus with OpenGamepadUI's overlay. Its Steam environment matches Valve's session that Jovian runs (HDR, VRR, tearing, mangoapp) |
| Display | `modes.cfg`: Sony at 3840x2160@120. EDID: VRR 48–120 Hz, HDR10 and HLG |
| CEC | `/etc/default/cec-control`: `CEC_MODE=dgpu`, wake, set source, standby on sleep and power-off, but every unit disabled |
| CEC test (2026-10-19) | Standby sent over CEC, and the TV reported `standby`. `/dev/cec0` kept `4.0.0.0` for the 60 s it stayed off. Image View On woke it within 2 s. So the adapter keeps the link up in standby and CEC can wake the TV. Not tested: hours-long standby, and the remote keys |
| Firmware | AMI BIOS 1656 (2024-04-18), UEFI, Secure Boot off |
| Network | `enp7s0`, MAC `cc:28:aa:86:dd:6a`, static `10.24.24.7` from NetworkManager |
