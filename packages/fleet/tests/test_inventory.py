import unittest

import support
import inventory
from inventory import UsageError


class Load(unittest.TestCase):
    def test_paths_come_from_the_environment(self):
        cfg = support.config(state="/state", flake="/flake")
        self.assertEqual(cfg.state_dir, "/state/fleet")
        self.assertEqual(cfg.flake_dir, "/flake")
        defaults = inventory.load(support.raw_config(), {"HOME": "/home/p"})
        self.assertEqual(defaults.flake_dir, "/home/p/.nixfiles")
        self.assertEqual(defaults.state_dir, "/home/p/.local/state/fleet")

    def test_bad_entries_are_rejected(self):
        for bad in ({"name": "X", "kind": "windows"}, {"name": "X", "kind": "nixos", "wakeMac": "nope"}, {"kind": "nixos"}):
            raw = {**support.raw_config(), "hosts": [bad]}
            with self.assertRaises(ValueError):
                inventory.load(raw, {"HOME": "/h"})

    def test_target_and_local_kind(self):
        cfg = support.config("MacFlurry")
        self.assertEqual(cfg.target(cfg.host("ShackStack")), "psoldunov@shackstack")
        self.assertEqual(cfg.local_kind, "darwin")


class Resolve(unittest.TestCase):
    def setUp(self):
        self.cfg = support.config()

    def test_any_case_in_inventory_order_once(self):
        hosts, from_all = inventory.resolve(self.cfg, ["pihome", "bigtasty", "BigTasty"])
        self.assertEqual([h.name for h in hosts], ["BigTasty", "PiHome"])
        self.assertFalse(from_all)

    def test_all(self):
        hosts, from_all = inventory.resolve(self.cfg, ["ALL"])
        self.assertEqual(len(hosts), len(support.HOSTS))
        self.assertTrue(from_all)

    def test_mistakes(self):
        with self.assertRaisesRegex(UsageError, "unknown host 'Kingsize'"):
            inventory.resolve(self.cfg, ["Kingsize"])
        with self.assertRaises(UsageError):
            inventory.resolve(self.cfg, ["all", "Whopper"])


class Reach(unittest.TestCase):
    def test_probe_asks_about_remote_hosts_only(self):
        cfg = support.config()
        asked = []

        def reach(target):
            asked.append(target)
            return target.endswith("bigtasty")

        hosts = [cfg.host(n) for n in ("Whopper", "BigTasty", "BigMac")]
        self.assertEqual(inventory.probe(cfg, hosts, reach), {"Whopper": True, "BigTasty": True, "BigMac": False})
        self.assertEqual(sorted(asked), ["psoldunov@bigmac", "psoldunov@bigtasty"])

    def test_magic_packet(self):
        packet = inventory.magic_packet("cc:28:aa:86:dd:6a")
        self.assertEqual(len(packet), 102)
        self.assertEqual(packet[:6], b"\xff" * 6)
        self.assertEqual(packet[6:12], bytes.fromhex("cc28aa86dd6a"))
        self.assertEqual(packet[6:12] * 16, packet[6:])
        with self.assertRaises(ValueError):
            inventory.magic_packet("cc:28:aa")


if __name__ == "__main__":
    unittest.main()
