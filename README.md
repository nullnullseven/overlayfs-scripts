This repository contains a collection of Linux boot and runtime scripts designed for ephemeral, non-persistent filesystem operations using OverlayFS and dracut modules.

What It Does
The scripts enable two primary workflows:

Dracut Boot Modules — Custom dracut hooks and modules that configure the initramfs to mount root filesystems as ephemeral overlays during system boot.

User-Space Directory Overlays — scripts to launch arbitrary directories inside OverlayFS stacks, ensuring all writes are discarded on unmount.
Key Features

Use Cases
Live/Rescue Systems — Boot into a familiar environment without touching the underlying disk.
Sandboxed Testing — Experiment with system changes, package installations, or configurations safely.
Privacy & Forensics — Ensure no traces are left on disk after a session.
Immutable Infrastructure — Layer ephemeral changes over read-only base images.

License
Unlicense

This work is licensed under the Unlicense. Anyone may use, modify, and redistribute these scripts and modules without restriction, even for commercial purposes.
