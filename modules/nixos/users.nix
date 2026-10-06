# Baseline psoldunov account. Hosts append extra groups, ssh keys,
# `linger`, etc. — `extraGroups` is a list type so values concat across
# modules.
{pkgs, ...}: {
  users.users.psoldunov = {
    isNormalUser = true;
    description = "Philipp Soldunov";
    shell = pkgs.fish;
    extraGroups = ["wheel" "docker" "libvirtd" "video"];
    # BigMac's own key; it logs in to every host. Its private half belongs on
    # BigMac only.
    openssh.authorizedKeys.keys = [
      "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQDtoWo+B3cr+8WzNi719pyoxlR72LTrZoU6YGmFZdDpgV2cKkRZnzw4pnERl7qXtOxkQ5BWtqffT83Uq0+ErDAD7jnRFAxS4o5cqTqnHOIfrtm5BflJel1ovho3M4YDfmyFfmxxepyBiMXaYq2G/3xyZek1fnvXq/Ds91aDHCh56BIgCCXxYbr9VxSyMbU0pu/W3MoDxTwKJb2jlTE5R78jeY3sLHaEzURooGtNulbYP1+3XziiqldrA4ZcW1IRGKFRK83zVX9Wjx7nCCinJhkAK0yCEYqQKpdx2twALoXr/iF9jt9Ss/juG2NqiqKZMJRy5I5bJqMSBpaJSYfM4/pXj26FzBpt/UXDxxOPOQrOdBjCIhNvYhnAgh5vi5xqGh/sK/go7GUVKZXVvWnHyUxkS8e75If5z+nyTNe6S+RFHHrV4snJWSFDDTSk4wk2jRDwzhusCYtX1aCoet37DjJENLMcu7ZTRnqqpC7hPLn4OVnjynVWczj+vtrbKlVq8agPEX9rjEsWu4GHZVNm2ZXmWcJWFIwHeWcnQEHX/NnpbxmyoQ1jXuZXTMiq/7z1Dlrx3+lmNmPIeTnxJWef2r2jxyrHF00W1ZJJ4hsHCKlbXTpGR4wkwAQF2CPWRyuzbdUSRFu2eu2KotyMlVchL2u2bH9qyEqr/BXf6jYwsuP5zQ== psoldunov@BigMac"
    ];
  };
}
