This is a todo list for the Linux port

- Figure out a strategy for keeping this in sync with smartos-live/src/img
- The default pool should be determined by existence `/<pool>/.system_pool`, not
  by hard-coded `zones`.
- Docker is not supported, but has not been removed.
  - If docker is to be supported, likely need to add mknod interposer.
- The installation is huge - 102 MB on Linux, 2.2 MB on SmartOS.  That needs to
  be trimmed.
