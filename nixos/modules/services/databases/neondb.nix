{
  lib,
  pkgs,
  config,
  ...
}:
with lib; let
  cfg = config.services.neondb;
  settingsFormat = pkgs.formats.toml {};
  argumentsFormat = pkgs.formats.shellArgs {disablePrefix = "disable-";};
  pageserverOpts = {config, ...}: {
    options = let
      name = config._module.args.name;
    in {
      settings = mkOption {
        description = mdDoc ''
          Pageserver settings, converted and passed as TOML config file.
          Overriden by `configFile`.

          For available params, see: <https://github.com/neondatabase/neon/blob/release-${pkgs.neondb.version}/docs/settings.md>
        '';
        type = types.submodule {
          freeformType = settingsFormat.type;
        };
      };
      configFile = mkOption {
        description = mdDoc ''
          Pageserver config file.
          Overrides any values set using `settings`.
        '';
        type = types.path;
        default =
          settingsFormat.generate
          "pageserver-${name}.toml"
          config.settings;
        defaultText = literalMD "TOML file generated from {option}`services.neondb.pageservers.<pageserver>.settings`";
      };
    };
  };
  safekeeperOpts = {...}: {
    options = {
      settings = mkOption {
        description = mdDoc ''
          Safekeeper settings, passed as arguments
        '';
        type = types.submodule {
          freeformType = argumentsFormat.type;
        };
      };
    };
  };
  generatePageserverUnit = name: pageserver: {
    name = "neondb-pageserver@${name}";
    value = {
      wantedBy = ["multi-user.target"];
      serviceConfig = {
        # Unfortunately, config file needs to be in dataDir.
        # Pending neondb PR.
        ExecStartPre = [
          "${pkgs.coreutils}/bin/cp ${pageserver.configFile} ./pageserver.toml"
        ];
      };
      overrideStrategy = "asDropin";
    };
  };
  generateSafekeeperUnit = name: safekeeper: {
    name = "neondb-safekeeper@${name}";
    value = {
      wantedBy = ["multi-user.target"];
      serviceConfig = {
        ExecStart = ''
          ${cfg.package}/bin/safekeeper -D . \
            ${argumentsFormat.generateSystemd safekeeper.settings}
        '';
      };
      overrideStrategy = "asDropin";
    };
  };
in {
  options.services.neondb = {
    dataDir = mkOption {
      description = mdDoc ''
        Default parent directory for all neondb components.
      '';
      type = types.path;
      default = "/var/lib/neondb";
    };
    pageservers = mkOption {
      description = mdDoc "Neondb pageservers.";
      default = {};
      type = with types; attrsOf (submodule pageserverOpts);
    };
    safekeepers = mkOption {
      description = mdDoc "Neondb safekeepers.";
      default = {};
      type = with types; attrsOf (submodule safekeeperOpts);
    };
    package = mkPackageOption pkgs "neondb" {};
  };
  config = mkIf (cfg.pageservers != {} && cfg.safekeepers != {}) {
    systemd.services =
      {
        "neondb-pageserver@" = {
          description = "NeonDB Pageserver %I";
          after = ["network.target"];
          serviceConfig = {
            ExecStart = "${cfg.package}/bin/pageserver -D .";
            StateDirectory = "neondb/pageserver/%i";
            WorkingDirectory = "/var/lib/neondb/pageserver/%i";
            DynamicUser = true;
            Restart = "on-failure";
            RestartSec = 5;
          };
        };
        "neondb-safekeeper@" = {
          description = "NeonDB Safekeeper %I";
          after = ["network.target"];
          serviceConfig = {
            StateDirectory = "neondb/safekeeper/%i";
            WorkingDirectory = "/var/lib/neondb/safekeeper/%i";
            DynamicUser = true;
            Restart = "on-failure";
            RestartSec = 5;
          };
        };
        "neondb-storage-broker" = {
          description = "NeonDB Storage Broker %I";
          after = ["network.target"];
          wantedBy = ["multi-user.target"];
          serviceConfig = {
            ExecStart = "${cfg.package}/bin/storage_broker";
            StateDirectory = "neondb/storage-broker";
            WorkingDirectory = "/var/lib/neondb/storage-broker";
            DynamicUser = true;
            Restart = "on-failure";
            RestartSec = 5;
          };
        };
      }
      // (mapAttrs' generatePageserverUnit cfg.pageservers)
      // (mapAttrs' generateSafekeeperUnit cfg.safekeepers);
  };
}
