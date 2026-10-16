# Cal.diy, the MIT community edition of Cal.com, at cal.theswisscheese.com.
# nginx proxies it (../services-web.nix) and cloudflare-dyndns keeps its
# proxied record (../services-cloudflare.nix), like Kuma and Jellyfin.
#
# Cal.diy publishes no image (Docker Hub's calcom/cal.diy has no tags, and
# calcom/cal.com stops at v6.2.0, before the fork), so cal-diy-image builds
# one here from a pinned commit. To update, bump `rev` and `hash`: the image
# tag follows them, so the next switch builds a new image (about 8 minutes
# cold) and restarts the container on it.
{
  config,
  pkgs,
  ...
}: let
  domain = "cal.theswisscheese.com";
  url = "https://${domain}";
  # 3000 is Grafana's.
  port = 3010;
  dataDir = "/var/lib/cal-diy-bootstrap";
  docker = "${config.virtualisation.docker.package}/bin/docker";

  src = pkgs.applyPatches {
    name = "cal-diy-src";
    src = pkgs.fetchFromGitHub {
      owner = "calcom";
      repo = "cal.diy";
      rev = "54343aa685ae8f33159d2f485ec4a57bad5c574a";
      hash = "sha256-4CnwMGSyJlyfIjO8Yz8FXmPzWrWnyNsDXYhJFD6ulsU=";
    };
    # `next build` inlines NEXT_PUBLIC_* values, so this one has to be there
    # at build time, and the Dockerfile takes no build argument for it. Next
    # reads apps/web/.env.production by itself. Accounts other than the admin
    # are created in Settings > Admin > Users.
    postPatch = ''
      echo "NEXT_PUBLIC_DISABLE_SIGNUP=true" > apps/web/.env.production
    '';
  };

  # The URL is baked into the static files; when it matches the run-time
  # value, the container's start script skips rewriting them.
  buildArgs = {
    NEXT_PUBLIC_WEBAPP_URL = url;
    CALCOM_TELEMETRY_DISABLED = "1";
  };
  buildArgFlags = toString (
    map (name: "--build-arg ${name}=${buildArgs.${name}}") (builtins.attrNames buildArgs)
  );

  # Changes with the source and the build arguments, nothing else.
  tag = builtins.substring 0 12 (
    builtins.hashString "sha256"
    (builtins.unsafeDiscardStringContext "${src}" + builtins.toJSON buildArgs)
  );
  image = "localhost/cal-diy:${tag}";
in {
  virtualisation.oci-containers.containers = {
    cal-diy = {
      inherit image;
      # No registry has this image: cal-diy-image builds it.
      pull = "never";
      ports = ["127.0.0.1:${toString port}:3000"];
      environment = {
        NEXT_PUBLIC_WEBAPP_URL = url;
        NEXTAUTH_URL = "${url}/api/auth";
        # The start script waits for this before running the migrations.
        DATABASE_HOST = "cal-diy-db:5432";
        CALCOM_TELEMETRY_DISABLED = "1";
        # The start script runs the app through turbo.
        TURBO_TELEMETRY_DISABLED = "1";
        EMAIL_FROM = "cal@theswisscheese.com";
        EMAIL_FROM_NAME = "Cal";
        EMAIL_SERVER_HOST = "smtp.resend.com";
        # 465 makes nodemailer use implicit TLS.
        EMAIL_SERVER_PORT = "465";
        EMAIL_SERVER_USER = "resend";
      };
      # POSTGRES_PASSWORD, DATABASE_URL, DATABASE_DIRECT_URL, NEXTAUTH_SECRET,
      # CALENDSO_ENCRYPTION_KEY, CRON_API_KEY and EMAIL_SERVER_PASSWORD (the
      # Resend key the other services use).
      environmentFiles = [
        config.sops.secrets.CAL_DIY_SETTINGS.path
      ];
      # Watchtower would look for this tag in a registry and find nothing.
      labels."com.centurylinklabs.watchtower.enable" = "false";
      extraOptions = [
        "--network=cal-diy-network"
      ];
      dependsOn = ["cal-diy-db"];
    };
    cal-diy-db = {
      image = "postgres:16.6";
      volumes = [
        "cal-diy_pgdata:/var/lib/postgresql/data"
      ];
      environment = {
        POSTGRES_DB = "caldiy";
        POSTGRES_USER = "caldiy";
      };
      environmentFiles = [
        config.sops.secrets.CAL_DIY_SETTINGS.path
      ];
      extraOptions = [
        "--network=cal-diy-network"
        "--health-cmd=pg_isready -U \"$$POSTGRES_USER\" -d \"$$POSTGRES_DB\""
        "--health-interval=10s"
        "--health-timeout=2s"
        "--health-retries=10"
      ];
    };
  };

  # Builds the image when its tag is missing: after a bump, or after the daily
  # image prune removed it while the container was down. BuildKit's cache
  # makes a rebuild of the same commit quicker.
  systemd.services.cal-diy-image = {
    description = "Build the cal.diy image";
    after = ["docker.service" "network-online.target"];
    requires = ["docker.service"];
    wants = ["network-online.target"];
    before = ["docker-cal-diy.service"];
    requiredBy = ["docker-cal-diy.service"];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      TimeoutStartSec = "2h";
    };
    script = ''
      set -euo pipefail
      if ${docker} image inspect ${image} >/dev/null 2>&1; then
        echo "${image} is already built."
        exit 0
      fi
      # The store copy is read-only; build from a writable one, as a checkout.
      ctx=$(mktemp -d /var/tmp/cal-diy-build.XXXXXX)
      trap 'rm -rf "$ctx"' EXIT
      cp -r ${src}/. "$ctx"
      chmod -R u+w "$ctx"
      ${docker} build --progress=plain --tag ${image} ${buildArgFlags} "$ctx"
    '';
  };

  # On an instance with no users, whoever submits the setup wizard becomes
  # admin. This submits it on loopback as soon as the app answers, and nginx
  # keeps the wizard LAN-only (../services-web.nix). The password is
  # random and stays in ${dataDir}/admin-password (root only); change it in
  # Settings > Security after the first login, and turn on 2FA there: without
  # it cal.diy keeps the admin out of Settings > Admin. If users already
  # exist, this only records that it is done.
  systemd.services.cal-diy-bootstrap = {
    description = "Create cal.diy's first admin";
    after = ["docker-cal-diy.service"];
    requires = ["docker-cal-diy.service"];
    wantedBy = ["multi-user.target"];
    path = [pkgs.curl pkgs.jq pkgs.openssl pkgs.gnugrep pkgs.coreutils];
    unitConfig.ConditionPathExists = "!${dataDir}/done";
    serviceConfig = {
      Type = "oneshot";
      StateDirectory = "cal-diy-bootstrap";
      StateDirectoryMode = "0700";
      UMask = "0077";
      # The first start runs every migration before the app answers.
      TimeoutStartSec = "20min";
    };
    script = ''
      set -euo pipefail
      app=http://127.0.0.1:${toString port}
      until curl -fs -o /dev/null "$app/auth/login"; do
        sleep 5
      done

      pending=${dataDir}/admin-password.pending
      if [ ! -s "$pending" ]; then
        # The admin policy wants 15+ characters with upper, lower and a digit.
        raw=$(openssl rand -base64 48 | tr -d '\n/+=')
        printf '%s' "''${raw:0:24}Aa1" > "$pending"
      fi
      # Through a file, so the password stays out of the process list.
      jq -n --rawfile password "$pending" '{
        username: "philipp",
        full_name: "Philipp Soldunov",
        email_address: "philipp@theswisscheese.com",
        password: $password
      }' > ${dataDir}/request.json
      status=$(curl -sS -o ${dataDir}/response.json -w '%{http_code}' \
        -H 'Content-Type: application/json' \
        --data-binary @${dataDir}/request.json "$app/api/auth/setup")
      rm -f ${dataDir}/request.json

      if [ "$status" = 200 ]; then
        mv "$pending" ${dataDir}/admin-password
        echo "Created admin philipp@theswisscheese.com."
      elif [ "$status" = 400 ] && grep -q 'No setup needed' ${dataDir}/response.json; then
        rm -f "$pending"
        echo "cal.diy already has users; nothing to do."
      else
        echo "Setup failed with HTTP $status:" >&2
        cat ${dataDir}/response.json >&2
        exit 1
      fi
      rm -f ${dataDir}/response.json
      touch ${dataDir}/done
    '';
  };
}
