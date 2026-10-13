# Concierge's Sync server. Plain HTTP on loopback; CFD_MAIN_TUNNEL exposes
# it and TLS ends at Cloudflare. The hostname's DNS record is not managed
# here: it is routed once, by hand on BigTasty (~/.cloudflared/cert.pem), with
# `cloudflared tunnel route dns c6f55ee4-168e-4343-8df7-74810ef99d5b concierge.theswisscheese.com`.
{
  config,
  inputs,
  ...
}: {
  imports = [inputs.concierge.nixosModules.concierge-server];

  services.cloudflared.tunnels."CFD_MAIN_TUNNEL".ingress = {
    # 127.0.0.1, not localhost: the server listens on IPv4 loopback only,
    # and localhost can resolve to ::1.
    "concierge.theswisscheese.com".service = "http://127.0.0.1:8470";
  };

  services.concierge-server = {
    enable = true;
    settings = {
      listen = "127.0.0.1:8470";
      # Named in the code email.
      address = "https://concierge.theswisscheese.com";
      # cloudflared connects from loopback, which trusted_proxies trusts by
      # default, so the per-IP rate limits see the real client IP.
      accounts = {
        sign_ups = true;
        allowed_domains = ["theswisscheese.com"];
      };
      mail.smtp = {
        host = "smtp.resend.com";
        port = 2465;
        # Implicit TLS, like Vaultwarden's force_tls.
        security = "tls";
        username = "resend";
        from = "Concierge <concierge@theswisscheese.com>";
      };
    };
    # A Resend API key. systemd's LoadCredential copies it, so only root
    # needs to read the sops file.
    smtpPasswordFile = config.sops.secrets.CONCIERGE_SMTP_PASSWORD.path;
  };
}
