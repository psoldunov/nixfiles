# Public halves of the SSH keys Whopper and BigMac share. Each identity is a
# sops secret in secrets/shared.yaml named SSH_KEY_<NAME> (upper-cased, `-`
# as `_`), which modules/home/workstation/ssh.nix links to ~/.ssh/<name> and
# pairs with ~/.ssh/<name>.pub written from this file.
rec {
  identities = {
    # GitHub, GitLab and the LAN hosts.
    github = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIM7NenR9CsniwhiBws/G5h7ODtPFraJQ//C2DtPqs3R1 philipp@theswisscheese.com whopper";
    id_ed25519 = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIAL6DdwEtXKcuyvpB5jn1yn5HBdDRnVmbCBcDtQwypBL philipp@theswisscheese.com";
    # Legacy RSA key, the fallback until it is retired.
    id_rsa = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQDtoWo+B3cr+8WzNi719pyoxlR72LTrZoU6YGmFZdDpgV2cKkRZnzw4pnERl7qXtOxkQ5BWtqffT83Uq0+ErDAD7jnRFAxS4o5cqTqnHOIfrtm5BflJel1ovho3M4YDfmyFfmxxepyBiMXaYq2G/3xyZek1fnvXq/Ds91aDHCh56BIgCCXxYbr9VxSyMbU0pu/W3MoDxTwKJb2jlTE5R78jeY3sLHaEzURooGtNulbYP1+3XziiqldrA4ZcW1IRGKFRK83zVX9Wjx7nCCinJhkAK0yCEYqQKpdx2twALoXr/iF9jt9Ss/juG2NqiqKZMJRy5I5bJqMSBpaJSYfM4/pXj26FzBpt/UXDxxOPOQrOdBjCIhNvYhnAgh5vi5xqGh/sK/go7GUVKZXVvWnHyUxkS8e75If5z+nyTNe6S+RFHHrV4snJWSFDDTSk4wk2jRDwzhusCYtX1aCoet37DjJENLMcu7ZTRnqqpC7hPLn4OVnjynVWczj+vtrbKlVq8agPEX9rjEsWu4GHZVNm2ZXmWcJWFIwHeWcnQEHX/NnpbxmyoQ1jXuZXTMiq/7z1Dlrx3+lmNmPIeTnxJWef2r2jxyrHF00W1ZJJ4hsHCKlbXTpGR4wkwAQF2CPWRyuzbdUSRFu2eu2KotyMlVchL2u2bH9qyEqr/BXf6jYwsuP5zQ== psoldunov@BigMac";
    agency-vps = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAINN4JNvA4rBhnM3qOXbcvNhVEWLTFpUUQSVcTt6tA7Uz agency-vps";
    # Both carry a passphrase. On BigMac `UseKeychain` keeps it in the macOS
    # Keychain; Whopper asks for it on first use.
    flywheel = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIAHGDKlLrEfy4bTIU0x2S8paIfwqEfueFd0WmuEJXTEe psoldunov@BigMac";
    secrets = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIDIMAhXWVgdNszKi5tHVWcSShMWGmalM+dqwHFVZ8XoU philipp@theswisscheese.com";
    # YubiKey 19662979 (FIDO2). The private half is only a key handle, so it
    # works on either machine with the YubiKey plugged in. Kept out of the
    # agent and the ssh config: every use needs a touch.
    git_sk = "sk-ssh-ed25519@openssh.com AAAAGnNrLXNzaC1lZDI1NTE5QG9wZW5zc2guY29tAAAAINUPStKGRvJ7CQqdjeOvaU/RcMvqfnXzpBoKW6CXH1aBAAAAB3NzaDpnaXQ= philipp@theswisscheese.com yubikey-19662979";
    # sudo over a forwarded agent (pam_ssh_agent_auth): each host's sudo
    # accepts only its own key, and only the other workstation loads it, by
    # logging in with it (modules/home/workstation/ssh.nix). A host never
    # holds its own sudo key in its agent, so local sudo keeps asking.
    "sudo-whopper" = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIGcGQNj2vpu3jexJbmwhyYfOuCI7Bb3oJfq6nLDEra28 philipp@theswisscheese.com sudo-whopper";
    "sudo-bigmac" = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIP9m7qk1/y4UpHjmg9ZFcnnVbpXoXBDyUvRD7u2iagfi philipp@theswisscheese.com sudo-bigmac";
  };

  # Keys every managed host accepts for psoldunov.
  authorized = [
    identities.github
    identities.id_rsa
    identities."sudo-whopper"
    identities."sudo-bigmac"
  ];

  # The one key each host's sudo accepts from a forwarded agent.
  sudo = {
    whopper = identities."sudo-whopper";
    bigmac = identities."sudo-bigmac";
  };
}
