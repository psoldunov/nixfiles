# Install PiHome on a spare card

PiHome now runs NixOS on the spare card. The initial ARM image was built, flashed, and booted, then the boot fixes were built and activated in place. The original Debian/AdGuard microSD card remains intact for rollback; do not overwrite it. The steps below describe a fresh spare-card installation.

## Source config and backup warning

The initial host-side snapshot was stale: the Docker bind mount at `/opt/AdGuardHome/conf/AdGuardHome.yaml` is not the config used by the running process. The active config was recovered read-only from the container's writable layer at lowercase `/opt/adguardhome/conf/AdGuardHome.yaml`. Before recreating or replacing that container, back up both this active config and the container's work data from its writable layer. The original microSD card remains a rollback path, but that is not a substitute for backing up the live container data. Keep the original card untouched while preparing a replacement.

## Prepare

1. Build the image with `nix build .#nixosConfigurations.PiHome.config.system.build.sdImage --out-link result-pihome-image`. This needs an **aarch64-linux** builder, local or remote. An ARM Mac runs aarch64 Darwin, not Linux, and cannot build it by itself. The current x86 Linux host is not configured for aarch64-linux builds. The initial migration used a temporary ARM Linux VM on BigMac; that builder was removed after the DNS cutover passed verification.
2. Flash the image to a verified spare microSD card. Flashing erases the selected device, so identify it carefully first. Leave the current card untouched. Do not use `nixos-anywhere` or target the existing card.
3. Make sure no other device is using `10.24.24.9`. PiHome configures `eth0` as `10.24.24.9/24`, with gateway `10.24.24.1`.
4. Shut down the Pi cleanly and disconnect power before swapping cards. Keep the original card intact. Both installations use `10.24.24.9`, so never run them at once.

## Check the new system

For a fresh installation, rebuild the workstation configuration before cutover so it installs `~/.ssh/sudo-pihome`, the `pihome` alias, and the remote CLI. This changes only the workstation, not PiHome. SSH in as `psoldunov` through that alias. The Pi accepts normal GitHub and `id_ed25519` keys for SSH, but only the dedicated forwarded `sudo-pihome` key authorizes sudo. The SSH host key changes on first NixOS boot. Verify its fingerprint at the local console before updating `known_hosts`; do not disable host-key checking or blindly remove the old key. The AdGuard UI/API bind is `127.0.0.1:3000`, unlike the original Debian container's `0.0.0.0:80`, and nothing proxies it: `adguard.theswisscheese.com` is gone. Configuration is declarative (`mutableSettings = false`): UI/API changes are not persistent, and each restart rewrites the settings from Nix. Nothing goes on the card besides the image. The Pi holds no age key: it makes a new random password for the CLI at every boot, under `/run/adguard-credentials`. Use the local CLI with sudo:

```sh
sudo adguard status
sudo adguard pause             # default 5 minutes
sudo adguard pause 15m
sudo adguard resume
sudo adguard flush
```

Check the services and query DNS directly before changing client settings:

```sh
systemctl --no-pager --full status unbound adguardhome
sudo adguard status
dig @127.0.0.1 example.org
dig @127.0.0.1 doubleclick.net
dig @127.0.0.1 portainer.theswisscheese.com
dig @127.0.0.1 dnssec-failed.org
```

Normal lookups should work, an active filter should block a domain confirmed against the current active filter list (for example, check whether `doubleclick.net` is currently blocked), and the rewrite should return `10.24.24.2`. The DNSSEC-invalid test should fail validation, usually with `SERVFAIL`. Do not treat an unverified sample domain as proof that filtering works. The rewrites continue to point at the LAN server `10.24.24.2`.

AdGuard DHCP remains disabled. DNS flows from devices to AdGuard on port 53, then Unbound at `127.0.0.1:5335`; Unbound resolves with DNSSEC and QNAME minimisation, without public forwarders or fallback. The Pi uses `127.0.0.1` for DNS. The active policy has two filter subscriptions, two allow rules, a Firefox DoH canary rule, and 15 local rewrites (`syncthing.theswisscheese.com` was added when it became LAN-only); it includes `*.local.theswisscheese.com`. At cutover there were 15, and `adguard.theswisscheese.com` was dropped later along with its BigTasty proxy. All 15 live A-record rewrite queries were checked against the expected `10.24.24.2`, including the wildcard using `nixos-rewrite-check.local.theswisscheese.com`. The evaluated NixOS settings were also compared with the active configuration after schema migration: all 15 rules match, with the new schema merely making `enabled = true` explicit. Pause leaves DNS serving queries. Flush clears Unbound before AdGuard to avoid refilling its cache from stale upstream data. The old card's data and query logs are not migrated; they remain on that card. Point clients at the Pi only after normal lookup, rewrite (`10.24.24.2`), blocked-domain, and DNSSEC-failure checks pass.

## Roll back

Power off the Pi, put the original card back, and boot. Do not run both cards at once; both use `10.24.24.9`. Verify the old SSH host key before reconnecting. The original Debian/AdGuard system and its data remain the rollback path.

Rolling back to an older NixOS generation on the new card is not a rollback path for AdGuard. Generations built before the Pi stopped holding an age key read their AdGuard credentials through SOPS, so AdGuard fails to start on them, and BigTasty's standby answers instead.
