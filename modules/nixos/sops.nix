# sops-nix preamble: format + age key path. Hosts provide
# `defaultSopsFile` and their own `secrets` attrset.
{...}: {
  sops = {
    defaultSopsFormat = "yaml";
    age.keyFile = "/home/psoldunov/.config/sops/age/keys.txt";
  };
}
