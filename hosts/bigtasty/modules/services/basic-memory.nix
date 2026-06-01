{
  config,
  pkgs,
  ...
}: let
  basicMemoryAuthProxy = pkgs.writeText "basic-memory-auth-proxy.py" ''
    import hmac
    import socket
    import socketserver
    import threading

    LISTEN = ("127.0.0.1", 8001)
    TARGET = ("127.0.0.1", 18001)
    TOKEN_FILE = "${config.sops.secrets.BASIC_MEMORY_MCP_TOKEN.path}"
    MAX_HEADER_BYTES = 65536

    def read_token():
        with open(TOKEN_FILE, "r", encoding="utf-8") as token_file:
            return token_file.read().strip()

    def pipe(src, dst):
        try:
            while True:
                chunk = src.recv(65536)
                if not chunk:
                    break
                dst.sendall(chunk)
        except OSError:
            pass
        finally:
            try:
                dst.shutdown(socket.SHUT_WR)
            except OSError:
                pass

    class Handler(socketserver.BaseRequestHandler):
        def reject(self, status, body):
            body_bytes = (body + "\n").encode("utf-8")
            response = (
                "HTTP/1.1 %s\r\n"
                "WWW-Authenticate: Bearer\r\n"
                "Content-Type: text/plain; charset=utf-8\r\n"
                "Connection: close\r\n"
                "Content-Length: %d\r\n"
                "\r\n"
            ) % (status, len(body_bytes))
            self.request.sendall(response.encode("ascii") + body_bytes)

        def handle(self):
            self.request.settimeout(15)
            buffered = b""

            while b"\r\n\r\n" not in buffered and len(buffered) < MAX_HEADER_BYTES:
                chunk = self.request.recv(4096)
                if not chunk:
                    return
                buffered += chunk

            if b"\r\n\r\n" not in buffered:
                self.reject("431 Request Header Fields Too Large", "request headers too large")
                return

            header_blob = buffered.split(b"\r\n\r\n", 1)[0].decode("iso-8859-1", "replace")
            authorization = ""
            for line in header_blob.split("\r\n")[1:]:
                if line.lower().startswith("authorization:"):
                    authorization = line.split(":", 1)[1].strip()
                    break

            expected = "Bearer " + read_token()
            if not hmac.compare_digest(authorization, expected):
                self.reject("401 Unauthorized", "missing or invalid bearer token")
                return

            try:
                with socket.create_connection(TARGET, timeout=15) as upstream:
                    upstream.sendall(buffered)
                    self.request.settimeout(None)
                    upstream.settimeout(None)
                    client_to_upstream = threading.Thread(
                        target=pipe,
                        args=(self.request, upstream),
                        daemon=True,
                    )
                    client_to_upstream.start()
                    pipe(upstream, self.request)
            except OSError:
                self.reject("502 Bad Gateway", "basic-memory upstream unavailable")

    class Server(socketserver.ThreadingTCPServer):
        allow_reuse_address = True

    if __name__ == "__main__":
        with Server(LISTEN, Handler) as server:
            server.serve_forever()
  '';
in {
  services.cloudflared.tunnels."CFD_MAIN_TUNNEL".ingress = {
    "memory.theswisscheese.com" = {
      service = "http://localhost:8001";
    };
  };

  users.groups.basic-memory-auth-proxy = {};
  users.users.basic-memory-auth-proxy = {
    isSystemUser = true;
    group = "basic-memory-auth-proxy";
  };

  systemd.tmpfiles.rules = [
    "d /RAID/apps/basic-memory 0750 psoldunov users -"
  ];

  systemd.services.basic-memory-auth-proxy = {
    description = "Bearer-token proxy for Basic Memory MCP";
    after = ["docker-basic-memory.service"];
    requires = ["docker-basic-memory.service"];
    wantedBy = ["multi-user.target"];
    serviceConfig = {
      ExecStart = "${pkgs.python3}/bin/python3 ${basicMemoryAuthProxy}";
      Restart = "always";
      RestartSec = "5s";
      User = "basic-memory-auth-proxy";
      Group = "basic-memory-auth-proxy";
      NoNewPrivileges = true;
      PrivateTmp = true;
      ProtectHome = true;
      ProtectSystem = "strict";
    };
  };

  virtualisation.oci-containers.containers = {
    basic-memory = {
      image = "ghcr.io/basicmachines-co/basic-memory:latest";
      ports = ["127.0.0.1:18001:8000"];
      volumes = [
        "/RAID/apps/basic-memory:/app/data"
      ];
      environment = {
        BASIC_MEMORY_HOME = "/app/data/basic-memory";
        BASIC_MEMORY_PROJECT_ROOT = "/app/data";
      };
      cmd = [
        "basic-memory"
        "mcp"
        "--transport"
        "streamable-http"
        "--host"
        "0.0.0.0"
        "--port"
        "8000"
        "--path"
        "/mcp"
      ];
      extraOptions = [
        "--health-cmd=basic-memory --version"
        "--health-interval=30s"
        "--health-timeout=10s"
        "--health-retries=3"
      ];
    };
  };
}
