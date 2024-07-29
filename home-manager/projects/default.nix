{config, ...}: let
  home = config.home.homeDirectory;
  projects = "${home}/Projects";
  personal = "${projects}/Personal";
  boundary = "${projects}/Boundary";
in {
  items = [
    {
      name = "nixfiles";
      path = "${home}/.nixfiles";
    }
    {
      name = "promise";
      path = "${boundary}/promise";
    }
    {
      name = "express";
      path = "${personal}/express";
    }
  ];
}
