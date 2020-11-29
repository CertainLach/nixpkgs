{ config, lib, pkgs, ... }:

with lib;

let

  cfg = config.qt5;

  isQGnome = cfg.platformTheme == "gnome" && builtins.elem cfg.style ["adwaita" "adwaita-dark"];
  isQtStyle = cfg.platformTheme == "gtk2" && !(builtins.elem cfg.style ["adwaita" "adwaita-dark"]);

  packages = if isQGnome then [
    pkgs.libsForQt5.qgnomeplatform
    pkgs.libsForQt514.qgnomeplatform
    pkgs.libsForQt512.qgnomeplatform
    pkgs.libsForQt5.adwaita-qt
    pkgs.libsForQt514.adwaita-qt
    pkgs.libsForQt512.adwaita-qt
  ] else if isQtStyle then [
    pkgs.libsForQt5.qtstyleplugins
    pkgs.libsForQt514.qtstyleplugins
    pkgs.libsForQt512.qtstyleplugins
  ]
    else throw "`qt5.platformTheme` ${cfg.platformTheme} and `qt5.style` ${cfg.style} are not compatible.";

in

{

  options = {
    qt5 = {

      enable = mkEnableOption "Qt5 theming configuration";

      platformTheme = mkOption {
        type = types.enum [
          "gtk2"
          "gnome"
        ];
        example = "gnome";
        relatedPackages = [
          ["libsForQt5" "qgnomeplatform"]
          ["libsForQt514" "qgnomeplatform"]
          ["libsForQt512" "qgnomeplatform"]
          ["libsForQt5" "qtstyleplugins"]
          ["libsForQt514" "qtstyleplugins"]
          ["libsForQt512" "qtstyleplugins"]
        ];
        description = ''
          Selects the platform theme to use for Qt5 applications.</para>
          <para>The options are
          <variablelist>
            <varlistentry>
              <term><literal>gtk</literal></term>
              <listitem><para>Use GTK theme with
                <link xlink:href="https://github.com/qt/qtstyleplugins">qtstyleplugins</link>
              </para></listitem>
            </varlistentry>
            <varlistentry>
              <term><literal>gnome</literal></term>
              <listitem><para>Use GNOME theme with
                <link xlink:href="https://github.com/FedoraQt/QGnomePlatform">qgnomeplatform</link>
              </para></listitem>
            </varlistentry>
          </variablelist>
        '';
      };

      style = mkOption {
        type = types.enum [
          "adwaita"
          "adwaita-dark"
          "cleanlooks"
          "gtk2"
          "motif"
          "plastique"
        ];
        example = "adwaita";
        relatedPackages = [
          ["libsForQt5" "adwaita-qt"]
          ["libsForQt514" "adwaita-qt"]
          ["libsForQt512" "adwaita-qt"]
          ["libsForQt5" "qtstyleplugins"]
          ["libsForQt514" "qtstyleplugins"]
          ["libsForQt512" "qtstyleplugins"]
        ];
        description = ''
          Selects the style to use for Qt5 applications.</para>
          <para>The options are
          <variablelist>
            <varlistentry>
              <term><literal>adwaita</literal></term>
              <term><literal>adwaita-dark</literal></term>
              <listitem><para>Use Adwaita Qt style with
                <link xlink:href="https://github.com/FedoraQt/adwaita-qt">adwaita</link>
              </para></listitem>
            </varlistentry>
            <varlistentry>
              <term><literal>cleanlooks</literal></term>
              <term><literal>gtk2</literal></term>
              <term><literal>motif</literal></term>
              <term><literal>plastique</literal></term>
              <listitem><para>Use styles from
                <link xlink:href="https://github.com/qt/qtstyleplugins">qtstyleplugins</link>
              </para></listitem>
            </varlistentry>
          </variablelist>
        '';
      };
    };
  };

  config = mkIf cfg.enable {

    environment.variables.QT_QPA_PLATFORMTHEME = cfg.platformTheme;

    environment.variables.QT_STYLE_OVERRIDE = cfg.style;

    environment.systemPackages = packages;

  };
}
