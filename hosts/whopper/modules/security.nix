{pkgs, ...}: {
  services.pcscd.enable = true;

  security = {
    polkit.enable = true;
    polkit.extraConfig = ''
      polkit.addRule(function(action, subject) {
        if (action.id == "org.freedesktop.systemd1.manage-units" &&
            subject.user == "psoldunov" &&
            action.lookup("unit") == "ollama.service" &&
            (action.lookup("verb") == "start" || action.lookup("verb") == "stop")) {
          return polkit.Result.YES;
        }
      });
    '';
    rtkit.enable = true;
    pam = {
      yubico = {
        enable = true;
        debug = false;
        mode = "challenge-response";
        id = ["19662979"];
      };
      services = {
        hyprlock = {};
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
