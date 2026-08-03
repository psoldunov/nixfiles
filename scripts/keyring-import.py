#!/usr/bin/env python3
"""Replay a keyring-export.py dump into the current Secret Service provider.

Run this after rebooting into the KWallet-only configuration, once ksecretd owns
org.freedesktop.secrets. Items are matched by their attribute set, so re-running
the script overwrites rather than duplicates.
"""

import json
import os
import sys

try:
    import secretstorage
except ImportError:
    sys.exit("secretstorage is not importable; run under the python3 in systemPackages")


def target_collection(connection):
    collection = secretstorage.get_default_collection(connection)
    if collection.is_locked():
        collection.unlock()
    if collection.is_locked():
        sys.exit("default collection stayed locked; unlock the wallet and retry")
    return collection


def main(path):
    with open(path) as handle:
        dump = json.load(handle)

    connection = secretstorage.dbus_init()
    owner = connection.get_name_owner("org.freedesktop.secrets")
    print(f"org.freedesktop.secrets is owned by {owner}")

    collection = target_collection(connection)
    written = 0
    for source in dump["collections"]:
        for item in source["items"]:
            if not item["attributes"]:
                print(f"skipping attribute-less item: {item['label']!r}", file=sys.stderr)
                continue
            collection.create_item(
                item["label"],
                item["attributes"],
                item["secret"].encode("utf-8", "surrogateescape"),
                replace=True,
                content_type=item["content_type"],
            )
            written += 1

    print(f"wrote {written} items into collection {collection.get_label()!r}")


if __name__ == "__main__":
    main(sys.argv[1] if len(sys.argv) > 1 else os.path.expanduser("~/keyring-export.json"))
