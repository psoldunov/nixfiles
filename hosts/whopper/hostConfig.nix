# Per-host knobs for Whopper. Threaded into every module via specialArgs
# as `hostConfig`. Add new flags here and consume them in modules/nixos or
# modules/home as needed.
#
# Schema:
#   enableHyprland :: bool   Desktop session toggle (disables SDDM/Plasma6).
#   ollamaDocker   :: bool   Run Ollama inside a container rather than as
#                            a native NixOS service.
{
  enableHyprland = true;
  ollamaDocker = false;
}
