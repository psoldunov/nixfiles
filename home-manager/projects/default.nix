{config, ...}: let
  home = config.home.homeDirectory;
  projects = "${home}/Projects";
  tsc = "${projects}/TSC";
  personal = "${projects}/Personal";
  boundary = "${projects}/Boundary";
  amalgam = "${projects}/Amalgam";
in {
  items = [
    {
      name = "snippets";
      path = "${projects}/Snippets";
    }
    {
      name = "plated";
      path = "${personal}/plated";
    }
    {
      name = "digiskies";
      path = "${tsc}/digiskies";
    }
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
      name = "toca-madera-2025";
      path = "${boundary}/toca-madera-2025";
    }
    {
      name = "haartz";
      path = "${boundary}/haartz";
    }
    {
      name = "toca-sanity-temp";
      path = "${boundary}/toca-sanity-temp";
    }
    {
      name = "fullsteam-sanity";
      path = "${boundary}/fullsteam-sanity";
    }
    {
      name = "fullsteam-app";
      path = "${boundary}/fullsteam-app";
    }
    {
      name = "fullsteam-onboarding";
      path = "${boundary}/fullsteam-onboarding";
    }
    {
      name = "fullsteam-portal";
      path = "${boundary}/fullsteam-portal";
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
