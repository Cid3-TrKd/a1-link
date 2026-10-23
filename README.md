# a1-link

A Termux package that puts **A1-143 in your pocket**: `a1` opens the opencode
terminal on the phone and connects it to the A1-143 server, so the session you
are reading is the session you are typing into.

```
phone (Termux)
  └── a1                     ← this package
       └── proot + Alpine    ← musl loader the arm64 binary needs
            └── opencode     ← TUI client, v2, linux-arm64-musl
                 └── HTTPS ──┼──> A1-143 server
```

The phone holds **no agent state**. Sessions, plugins, memory and the
conversation stay on the server; the phone is a terminal attached to it. That is
deliberate: a second local instance would be a different, empty A1.

## Install

In Termux:

```sh
pkg install -y curl
curl -fLO https://github.com/Cid3-TrKd/a1-link/releases/latest/download/a1-link_aarch64.deb
pkg install -y ./a1-link_aarch64.deb
```

That URL always serves the newest release, so the command does not change when
a version is bumped.

If `pkg install` refuses a local file on your Termux build, `dpkg -i` is the
same thing:

```sh
dpkg -i a1-link_aarch64.deb
```

Then, once:

```sh
a1 pair            # asks for the server address and password
a1                 # opens the terminal
```

`a1 bootstrap` is only needed on a phone that does not already have the runtime
(Alpine rootfs + opencode binary). It downloads ~200 MB.

## Commands

| command | what it does |
|---|---|
| `a1` | open the TUI against the server |
| `a1 local` | open the TUI with no server — a phone-local instance |
| `a1 pair [URL]` | store the server address and password |
| `a1 status` | config, runtime, client version, reachability |
| `a1 api GET /api/info` | raw client call, for diagnosis |
| `a1 bootstrap` | install the Alpine rootfs and the opencode binary |
| `a1 version` | versions of the wrapper, the client and the server |

## Where the server address comes from

`current-url.txt` in this repo holds the current address, and `a1` falls back to
it when the saved address stops answering — so a moved tunnel does not need a
re-install. The address alone is useless without the password: the server
answers `401 Unauthorized` to everything else, and the password is never stored
in this repo.

## What it writes on the phone

| path | what |
|---|---|
| `~/.config/a1-link/config` | server URL + password, mode `0600` |
| `~/a1-oc/alpine/` | Alpine rootfs (proot) |
| `~/a1-oc/opencode` | the arm64-musl client binary |

Nothing else. The wrapper never edits the rootfs except to add
`/etc/resolv.conf` when it is missing (Alpine's minirootfs ships without one,
which makes DNS fail and looks like a broken network).

## Security, plainly

- The package contains **no password**. Pairing is a deliberate, local step.
- The server is exposed through OpenTunnel over HTTPS and authenticates with
  HTTP Basic. Everything without the password gets `401`.
- The phone's config file is `0600` inside Termux's private data directory;
  another app cannot read it without root.
- The server has shell access to the laptop by design — that is what an agent
  is. Treat the password like an SSH key.

## Rebuilding

```sh
./build.sh          # -> dist/a1-link_1.0.1_aarch64.deb
```

Then copy it to the stable name the README links to:

```sh
cp dist/a1-link_1.0.1_aarch64.deb dist/a1-link_aarch64.deb
gh release upload v1.0.1 dist/a1-link_1.0.1_aarch64.deb dist/a1-link_aarch64.deb --clobber
```

The build has no dependencies beyond `dpkg-deb`, `tar` and `bash`.
