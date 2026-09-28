#!/usr/bin/env python3
"""Export every Secret Service item to a JSON file.

Run this while gnome-keyring still owns org.freedesktop.secrets, i.e. before
rebuilding into the KWallet-only configuration. The companion script
keyring-import.py replays the dump into whichever daemon owns the bus
afterwards.

The output file contains plaintext secrets. It is written with mode 0600 and
should be shredded as soon as the import has been verified.
"""

import json
import os
import stat
import sys

try:
    import secretstorage
except ImportError:
    sys.exit("secretstorage is not importable; run under the python3 in systemPackages")


def item_to_dict(item):
    return {
        "label": item.get_label(),
        "attributes": dict(item.get_attributes()),
        "content_type": item.get_secret_content_type(),
        "secret": item.get_secret().decode("utf-8", "surrogateescape"),
    }


def main(path):
    connection = secretstorage.dbus_init()
    collections = []
    for collection in secretstorage.get_all_collections(connection):
        if collection.is_locked():
            collection.unlock()
        if collection.is_locked():
            print(f"skipping locked collection: {collection.get_label()!r}", file=sys.stderr)
            continue
        collections.append(
            {
                "label": collection.get_label(),
                "items": [item_to_dict(i) for i in collection.get_all_items()],
            }
        )

    fd = os.open(path, os.O_WRONLY | os.O_CREAT | os.O_TRUNC, stat.S_IRUSR | stat.S_IWUSR)
    with os.fdopen(fd, "w") as handle:
        json.dump({"collections": collections}, handle, indent=2)

    total = sum(len(c["items"]) for c in collections)
    print(f"exported {total} items from {len(collections)} collections to {path}")


if __name__ == "__main__":
    main(sys.argv[1] if len(sys.argv) > 1 else os.path.expanduser("~/keyring-export.json"))
