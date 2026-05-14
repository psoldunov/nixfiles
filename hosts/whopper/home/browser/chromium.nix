{pkgs, ...}: {
  programs.chromium = {
    enable = true;
    package = pkgs.brave;
    dictionaries = with pkgs; [
      hunspellDictsChromium.en_US
      hunspellDictsChromium.fr_FR
      hunspellDictsChromium.de_DE
    ];
    extensions = [
      {id = "kgcjekpmcjjogibpjebkhaanilehneje";}
      {id = "lahhiofdgnbcgmemekkmjnpifojdaelb";}
      {id = "aeblfdkhhhdcdjpifhhbdiojplfjncoa";}
      {id = "bnomihfieiccainjcjblhegjgglakjdd";}
      {id = "padekgcemlokbadohgkifijomclgjgif";}
      {
        id = "oladmjdebphlnjjcnomfhhbfdldiimaf";
        updateUrl = "https://raw.githubusercontent.com/libredirect/browser_extension/refs/heads/master/src/updates/updates.xml";
      }
      {
        id = "lkbebcjgcmobigpeffafkodonchffocl";
        updateUrl = "https://raw.githubusercontent.com/bpc-clone/bypass-paywalls-chrome-clean/master/updates.xml";
      }
      {id = "dbepggeogbaibhgnhhndojpepiihcmeb";}
      {id = "bkkmolkhemgaeaeggcmfbghljjjoofoh";}
      {id = "fmkadmapgofadopljbjfkapdkoienihi";}
      {id = "mjfibgdpclkaemogkfadpbdfoinnejep";}
      {id = "mfjbmoaliicmnliefefaagcddnjkjamc";}
      {id = "jbbplnpkjmmeebjpijfedlgcdilocofh";}
      {id = "eljapbgkmlngdpckoiiibecpemleclhh";}
      {id = "djlkbfdlljbachafjmfomhaciglnmkgj";}
      {id = "gebbhagfogifgggkldgodflihgfeippi";}
    ];
  };

  programs.firefox = {
    enable = false;
  };
}
