self: super: {
  openldap = super.openldap.overrideAttrs (old: {
    doCheck = false;
  });
}
