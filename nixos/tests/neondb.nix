import ./make-test-python.nix ({pkgs, ...}: {
  name = "neondb";
  meta = with pkgs.lib.maintainers; {
    maintainers = [lach];
  };

  nodes.machine = {...}: {
    services.neondb = {
      pageservers.test.settings.id = 1;
      safekeepers.test1.settings = {
        id = 1;
        listen-pg = "127.0.0.1:5454";
        listen-http = "127.0.0.1:7676";
      };
      safekeepers.test2.settings = {
        id = 2;
        listen-pg = "127.0.0.2:5454";
        listen-http = "127.0.0.2:7676";
      };
      safekeepers.test3.settings = {
        id = 3;
        listen-pg = "127.0.0.3:5454";
        listen-http = "127.0.0.3:7676";
      };
    };
    environment.systemPackages = [pkgs.nodePackages.neonctl];
  };

  testScript = ''
    machine.start()
    machine.wait_for_unit("neondb-pageserver@test")
    machine.wait_for_unit("neondb-safekeeper@test1")
    machine.wait_for_unit("neondb-safekeeper@test2")
    machine.wait_for_unit("neondb-safekeeper@test3")

    machine.succeed(
      "neonctl projects list --api-host http://localhost:50051/ --api-key example"
    )

    machine.shutdown()
  '';
})
