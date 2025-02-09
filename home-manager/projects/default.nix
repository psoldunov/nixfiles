{config, ...}: let
  home = config.home.homeDirectory;
  projects = "${home}/Projects";
  personal = "${projects}/Personal";
  boundary = "${projects}/Boundary";
  amalgam = "${projects}/Amalgam";
in {
  items = [
    {
      name = "navier";
      path = "${amalgam}/navier";
    }
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
      path = "${boundary}/fullsteam-onboarding";
    }
    {
      name = "angrymob-next";
      path = "${boundary}/angrymob-next";
    }
    {
      name = "weho-news";
      path = "${boundary}/weho-news";
    }
    {
      name = "casa-madera";
      path = "${boundary}/casa-madera";
    }
    {
      name = "eljugo";
      path = "${boundary}/eljugo";
    }
    {
      name = "esaw";
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
