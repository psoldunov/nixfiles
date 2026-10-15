# Not a module: an nginx access list that LAN-only vhosts splice into
# `extraConfig`. Nginx's access module checks the socket peer, with no
# real_ip/X-Forwarded-For trust, so a request through Cloudflare (peer is a
# Cloudflare edge) and a direct hit on the WAN IP both get 403. The home LAN,
# this host and its Docker networks (172.17-172.25 today) get through.
''
  allow 10.24.24.0/24;
  allow 127.0.0.1;
  allow ::1;
  allow 172.16.0.0/12;
  deny all;
''
