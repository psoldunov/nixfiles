{...}: {
  # Stock KDE: let Plasma drive Qt theming (Breeze) via the KDE platform theme.
  # No qt5ct/qt6ct override — Qt apps follow the System Settings appearance.
  qt = {
    enable = true;
    platformTheme.name = "kde";
  };
}
