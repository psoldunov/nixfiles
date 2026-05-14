# SSH daemon baseline. Hosts add their own ports / extra settings
# (`PermitRootLogin`, `PrintMotd`, etc.) — settings is an attrset so
# multiple modules merge per-key.
{...}: {
  services.openssh = {
    enable = true;
    settings.AllowUsers = ["psoldunov"];
  };
}
