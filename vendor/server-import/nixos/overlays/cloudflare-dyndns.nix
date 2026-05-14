self: super: {
  cloudflare-dyndns = super.cloudflare-dyndns.overrideAttrs (oldAttrs: {
    version = "5.0";
    src = super.fetchFromGitHub {
      owner = "kissgyorgy";
      repo = "cloudflare-dyndns";
      rev = "v5.0";
      hash = "sha256-tI6qdNxIMEuAR+BcqsRi2EBXTQnfdDLKW7Y+fbcmlao=";
    };

    dependencies = with super.python3.pkgs; [
      attrs
      click
      pydantic
      requests
      httpx
      truststore
      (super.python3.pkgs.cloudflare.overridePythonAttrs (old: {
        pname = "cloudflare";
        version = "4.1.0";
        pyproject = true;

        src = super.fetchPypi {
          pname = "cloudflare";
          version = "4.1.0";
          hash = "sha256-a5++mUhW/pQq3GpIgbe+3tIIA03FxT3Wg3UfYy5Hoaw=";
        };

        disabled = pythonOlder "3.7";

        nativeBuildInputs = [
          super.python3.pkgs.hatchling
          super.python3.pkgs."hatch-fancy-pypi-readme"
        ];

        build-system = [
          super.python3.pkgs."hatch-fancy-pypi-readme"
          (super.python3.pkgs.hatchling.overridePythonAttrs (old: {
            version = "1.26.3";
            src = super.fetchPypi {
              pname = "hatchling";
              version = "1.26.3";
              hash = "sha256-tnKpw2pgGgbE6IoauxMwY57o5yHgU1o3U25UamZ+/Ho=";
            };
          }))
        ];

        dependencies = [
          httpx
          pydantic
          typing-extensions
          anyio
          distro
          sniffio
        ];

        doCheck = false;
        pythonImportsCheck = ["cloudflare"];
      }))
    ];
  });
}
