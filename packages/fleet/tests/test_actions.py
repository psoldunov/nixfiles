import shlex
import unittest

import support
import actions
from runner import SRC


def host(cfg, name):
    return cfg.host(name)


class FromWhopper(unittest.TestCase):
    def setUp(self):
        self.cfg = support.config("Whopper")

    def argv(self, action, name, tty=False):
        return [s.argv for s in actions.BUILDERS[action](self.cfg, host(self.cfg, name), tty)]

    def test_local_switch(self):
        self.assertEqual(
            self.argv("rebuild", "Whopper"),
            [("sudo", "nixos-rebuild", "switch", "--flake", ".#Whopper", "--show-trace")],
        )

    def test_remote_nixos_builds_here_and_substitutes(self):
        (argv,) = self.argv("rebuild", "BigTasty")
        self.assertEqual(
            argv,
            ("nixos-rebuild", "switch", "--flake", ".#BigTasty", "--target-host", "psoldunov@bigtasty",
             "--use-substitutes", "--sudo", "--show-trace"),
        )

    def test_pihome_builds_itself(self):
        (argv,) = self.argv("rebuild", "PiHome")
        self.assertIn("--build-host", argv)
        self.assertEqual(argv[argv.index("--build-host") + 1], "psoldunov@pihome")

    def test_update_upgrades_all_on_nixos(self):
        (argv,) = self.argv("update", "BigKing")
        self.assertEqual(argv[-1], "--upgrade-all")

    def test_remote_mac_update_archives_then_switches_and_runs_bleeding_edge(self):
        archive, switch = actions.update(self.cfg, host(self.cfg, "BigMac"), tty=True)
        self.assertTrue(archive.captures_src)
        self.assertEqual(archive.argv[-1], "ssh-ng://psoldunov@bigmac?remote-program=/run/current-system/sw/bin/nix-daemon")
        self.assertEqual(switch.argv[:3], ("ssh", "-t", "psoldunov@bigmac"))
        resolved = switch.resolved("/nix/store/abc-source")
        sh, dash_c, inner = shlex.split(resolved[3])
        self.assertEqual((sh, dash_c), ("/bin/sh", "-c"))
        self.assertIn("sudo /run/current-system/sw/bin/darwin-rebuild switch --flake /nix/store/abc-source#BigMac --show-trace", inner)
        self.assertTrue(inner.endswith("&& /etc/profiles/per-user/psoldunov/bin/update_bleeding_edge"))
        self.assertIn("export LANG=en_US.UTF-8", inner)
        self.assertNotIn(SRC, resolved[3])

    def test_remote_clean_round_trips_through_the_remote_shell(self):
        (step,) = actions.clean(self.cfg, host(self.cfg, "BigTasty"), tty=False)
        self.assertEqual(step.argv[:3], ("ssh", "-T", "psoldunov@bigtasty"))
        self.assertEqual(shlex.split(step.argv[3]), ["bash", "-c", actions.CLEAN])

    def test_local_clean(self):
        self.assertEqual(self.argv("clean", "Whopper"), [("bash", "-c", actions.CLEAN)])

    def test_power(self):
        (reboot,) = actions.reboot(self.cfg, host(self.cfg, "ShackStack"), tty=False)
        self.assertEqual(reboot.argv[-1], "sudo systemctl reboot")
        self.assertIn(255, reboot.ok_codes)
        self.assertEqual(self.argv("sleep", "Whopper"), [("systemctl", "suspend")])
        (mac,) = actions.sleep(self.cfg, host(self.cfg, "MacFlurry"), tty=False)
        self.assertEqual(mac.argv[-1], "pmset sleepnow")
        (mac_reboot,) = actions.reboot(self.cfg, host(self.cfg, "BigMac"), tty=False)
        self.assertEqual(mac_reboot.argv[-1], "sudo shutdown -r now")

    def test_routes(self):
        self.assertIn("built on this machine", actions.route(self.cfg, host(self.cfg, "BigTasty")))
        self.assertIn("built on pihome", actions.route(self.cfg, host(self.cfg, "PiHome")))
        self.assertIn("nix flake archive", actions.route(self.cfg, host(self.cfg, "BigMac")))
        self.assertEqual(actions.route(self.cfg, host(self.cfg, "Whopper")), "on this machine")

    def test_flake_update_runs_every_pin_against_the_flake(self):
        steps = actions.flake_update(self.cfg)
        self.assertEqual(steps[0].argv, ("sudo", "nix", "flake", "update"))
        self.assertEqual([s.argv for s in steps[1:]], [("/pins/update_claude_code",), ("/pins/update_codex",)])
        self.assertEqual(dict(steps[1].env), {"FLAKE_DIR": "/tmp/fleet-test-flake"})


class FromAMac(unittest.TestCase):
    def setUp(self):
        self.cfg = support.config("BigMac")

    def test_nixos_host_goes_through_flake_archive(self):
        archive, switch = actions.rebuild(self.cfg, host(self.cfg, "BigTasty"), tty=False)
        self.assertTrue(archive.captures_src)
        inner = shlex.split(switch.resolved("/nix/store/s")[3])[2]
        self.assertIn("sudo /run/current-system/sw/bin/nixos-rebuild switch --flake /nix/store/s#BigTasty", inner)
        self.assertEqual(switch.argv[1], "-T")

    def test_local_mac_update_runs_bleeding_edge_after_the_switch(self):
        switch, after = actions.update(self.cfg, host(self.cfg, "BigMac"), tty=True)
        self.assertEqual(switch.argv[:2], ("sudo", "/run/current-system/sw/bin/darwin-rebuild"))
        self.assertEqual(after.argv, ("/store/update_bleeding_edge",))


if __name__ == "__main__":
    unittest.main()
