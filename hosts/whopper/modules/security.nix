{pkgs, ...}: {
  services.pcscd.enable = true;

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
        sudo.u2fAuth = true;
      };
    };
    pki.certificateFiles = ["${pkgs.cacert}/etc/ssl/certs/ca-bundle.crt"];
  };

  programs.gnupg.agent = {
    enable = true;
    enableSSHSupport = true;
  };
}
