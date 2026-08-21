# py-cam

[FreeCORE](https://freecore.org) carries the TrueNAS CORE 13.3 system forward as an
independently maintained operating system on FreeBSD. TrueNAS CORE 13.3 systems
upgrade straight to FreeCORE 15.0 in place, then continue on the project’s
update train.

Not affiliated with or endorsed by iXsystems, Inc.

## What this repository is

`py-cam` forked from [`truenas/py-cam`](https://github.com/truenas/py-cam) at:

| | |
|---|---|
| **Base commit** | `91f9b783e3e34e9370b3349e26c7e572b487c575` |
| **Base** | truenas/13.0-stable @ 2022-06-09 |
| **Licence** | BSD-2-Clause — unchanged from upstream |

## How to read the history

Upstream history is preserved verbatim below the base commit: original commits,
original authors, original dates. Everything FreeCORE changed sits above it.

```sh
git log --oneline 91f9b783e3e3..HEAD      # the entire FreeCORE delta
git diff 91f9b783e3e3..HEAD               # ...as one diff
```

The FreeCORE commits are a compact **release history**, generated from the
reviewed source-state difference rather than copied from the development
repositories. Private commit subjects, issue references, dates, and intermediate
churn are not mirrored here. Only tagged release commits are states that were
built and tested.

## Releases

Tags mark states that were actually built, installed and validated.

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md). Security reports go to
security@freecore.org, not to the issue tracker — see [SECURITY.md](SECURITY.md).

## Licence and attribution

See [NOTICE](NOTICE) and [TRADEMARKS.md](TRADEMARKS.md). Nothing here is
relicensed; upstream copyright notices and licence texts are preserved.
