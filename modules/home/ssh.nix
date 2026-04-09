{pkgs, ...}: {
  programs.ssh = {
    enable = true;
    extraConfig = ''
      Host github.com
          HostName github.com
          IdentityFile ~/.ssh/git
          User git
          AddKeysToAgent yes

      Host mynixos.com
          HostName mynixos.com
          IdentityFile ~/.ssh/git
          AddKeysToAgent yes

      Host gitlab.com
          PreferredAuthentications publickey
          IdentityFile ~/.ssh/git
          AddKeysToAgent yes

      Host thinkpad.theswisscheese.com
          ProxyCommand ${pkgs.cloudflared}/bin/cloudflared access ssh --hostname %h
    '';
  };
}
