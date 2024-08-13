{config, ...}: let
  home = config.home.homeDirectory;
  projects = "${home}/Projects";
  personal = "${projects}/Personal";
  boundary = "${projects}/Boundary";
in {
  items = [
    {
      name = "ags";
      path = "${personal}/ags";
    }
    {
      name = "nixfiles";
      path = "${home}/.nixfiles";
    }
    {
      name = "promise";
      path = "${boundary}/promise";
    }
    {
      name = "weho-news";
      path = "${boundary}/weho-news";
    }
    {
      name = "ESAW";
      path = "${boundary}/esaw";
    }
    {
      name = "express";
      path = "${personal}/express";
    }
  ];
}
