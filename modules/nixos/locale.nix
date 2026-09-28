# Timezone + locale. The full LC_* matrix used to live only on Whopper;
# BigTasty now inherits it too.
{...}: {
  time.timeZone = "Asia/Nicosia";

  i18n.defaultLocale = "en_US.UTF-8";

  i18n.extraLocaleSettings = {
    LC_ADDRESS = "en_US.UTF-8";
    LC_IDENTIFICATION = "en_US.UTF-8";
    # Metric units, so temperatures read in °C wherever an app derives the
    # unit from the locale (the Plasma weather widget, KWeather, ...). Qt
    # reports en_GB as ImperialUKSystem, not MetricSystem, so it is en_IE.
    LC_MEASUREMENT = "en_IE.UTF-8";
    LC_MONETARY = "en_IE.UTF-8";
    LC_NAME = "en_US.UTF-8";
    LC_NUMERIC = "en_US.UTF-8";
    LC_PAPER = "en_US.UTF-8";
    LC_TELEPHONE = "en_US.UTF-8";
    LC_TIME = "en_GB.UTF-8";
  };
}
