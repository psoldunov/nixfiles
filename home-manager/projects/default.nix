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
      name = "fullsteam";
      path = "${boundary}/fullsteam-next";
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
    {
      name = "viteflow";
      path = "${personal}/viteflow";
    }
    {
      name = "fanfuel";
      path = "${boundary}/fanfuel";
    }
    {
      name = "app.beltbase.io";
      path = "${personal}/app.beltbase.io";
    }
  ];
}
