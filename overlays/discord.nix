# The official Discord client with Vencord injected and OpenASAR in place of
# Discord's own app.asar. OpenASAR honours --start-minimized and names its
# autostart entry discord.desktop, which the Whopper autostart module reuses.
self: super: {
  discord = super.discord.override {
    withVencord = true;
    withOpenASAR = true;
  };
}
