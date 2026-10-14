{pkgs, ...}: let
  sshKeys = import ../../../lib/ssh-keys.nix;
in {
  services.pcscd.enable = true;

  # sudo accepts BigMac's forwarded agent when it holds Whopper's sudo key,
  # so rebuilds from BigMac need no password. Whopper never loads that key
  # itself, so local sudo still wants the YubiKey (lib/ssh-keys.nix).
  environment.etc."ssh/sudo_authorized_keys" = {
    text = sshKeys.sudo.whopper + "\n";
    mode = "0444";
  };
  security.pam.sshAgentAuth = {
    enable = true;
    authorizedKeysFiles = ["/etc/ssh/sudo_authorized_keys"];
  };
  security.sudo.extraConfig = ''
    Defaults env_keep += "SSH_AUTH_SOCK"
  '';

  security = {
    polkit.enable = true;
    rtkit.enable = true;
    pam = {
      yubico = {
        enable = true;
        debug = false;
        mode = "challenge-response";
        id = ["19662979"];
      };
      services = {
        login.u2fAuth = true;
        sudo = {
          u2fAuth = true;
          sshAgentAuth = true;
        };
      };
    };
    pki.certificateFiles = ["${pkgs.cacert}/etc/ssl/certs/ca-bundle.crt"];
  };

  programs.gnupg.agent = {
    enable = true;
    enableSSHSupport = true;
  };
}
