# pihole-lists

The domain lists my Pi-hole uses, kept as plain text so they can be reviewed, diffed, and reapplied to a fresh install.
The files in `lists/` are the source of truth, and `scripts/` brings a live Pi-hole in line with them.

## Contents

| Path                   | What it holds                                                      | Entries |
| ---------------------- | ------------------------------------------------------------------ | ------- |
| `lists/adlists.txt`    | Subscribed adlist URLs, one per line                               | 8       |
| `lists/deny-exact.txt` | Exact domains to deny, one per line                                | 128     |
| `lists/deny-regex.txt` | Regex deny patterns, one per line, in the dialect Pi-hole expects  | 84      |
| `scripts/sync.sh`      | Reconciles a live Pi-hole's deny rules with the files              |         |
| `scripts/export.sh`    | Writes a live Pi-hole's deny rules and adlists back into the files |         |

The list files are plain lines with no comments, and sorted, so diffs stay small and the files pipe straight into other tools.
Anything that needs explaining belongs in this README, not in the list files.

## Where the rest of my Pi-hole config lives

| Config                                       | Where                                                                  | Public |
| -------------------------------------------- | ---------------------------------------------------------------------- | ------ |
| Deny rules and adlists                       | this repo                                                              | yes    |
| Settings such as upstreams and DNSSEC        | `FTLCONF_*` values in the `homelab` repo, `k8s/pihole/values.yaml`     | yes    |
| Local DNS records                            | `pihole.toml` on the Pi-hole's volume, in nightly backups              | no     |
| Allow rules, groups, and clients             | `gravity.db`, same backups                                             | no     |
| Admin password                               | a password manager and a Kubernetes Secret                             | no     |

Allow rules stay out of this repo on purpose.
They name the services I use, and they are not part of "what I block".

## Workflow

Changing what is blocked, starting from the files:

```bash
$EDITOR lists/deny-exact.txt
scripts/sync.sh            # dry run, shows what would change
scripts/sync.sh --apply    # adds the new rules
```

Changing what is blocked, starting from the Pi-hole admin UI:

```bash
scripts/export.sh          # overwrites the list files with what the Pi-hole has
git diff                   # review, then commit
```

`sync.sh` never deletes anything unless you pass `--prune` together with `--apply`.
It never touches allow rules, groups, or clients.
Adlists are only reported, because the Pi-hole CLI cannot manage them: add or remove those in the web UI, then run `pihole -g`.

### Reaching the Pi-hole

Both scripts run on the machine where you keep this repo, and send only the Pi-hole commands into the container.
By default they use `kubectl -n networking exec -i deploy/pihole --`.
Set `PIHOLE_EXEC` to change that, for example to `docker exec -i pihole` or `ssh host docker exec -i pihole`.
The container only needs the `pihole` CLI and its bundled `sqlite3`.

The Pi-hole image ships BusyBox, whose `xargs` has no `-d`, so the scripts pass NUL-delimited input instead.
If you apply the lists by hand inside the container, do the same:

```bash
tr '\n' '\0' < lists/deny-exact.txt | xargs -0 pihole deny
tr '\n' '\0' < lists/deny-regex.txt | xargs -0 pihole --regex
```

### Tested and not tested

Tested against a live Pi-hole v6: dry run, adding, re-running, refusing to delete without `--prune`, pruning, and exporting.
Not tested against a freshly installed Pi-hole with empty lists.

## Notes on specific rules

- `iadsdk.apple.com` blocks Apple's iAd SDK hosts, which are used by apps that serve Apple-brokered ads.
- The Moloco, Mintegral, and Pangle patterns target in-app ad networks seen in the query log of a game that served full-screen video ads.
- `adjust.io` blocks attribution tracking and is a wildcard on purpose.
- App Store ads cannot be blocked by DNS, because they are served from the same hosts as the store's own content.
  Blocking `amp-api*.apps.apple.com` would break the App Store.
- One adlist, `hagezi/native.tiktok.extended`, is subscribed but not assigned to any group in the Pi-hole this was exported from, so it blocks nothing there.

## License

Licensed under either of

- Apache License, Version 2.0 ([LICENSE-APACHE](LICENSE-APACHE) or <http://www.apache.org/licenses/LICENSE-2.0>)
- MIT license ([LICENSE-MIT](LICENSE-MIT) or <http://opensource.org/licenses/MIT>)

at your option.

### Contribution

Unless you explicitly state otherwise, any contribution intentionally submitted for inclusion in the work by you, as defined in the Apache-2.0 license, shall be dual licensed as above, without any additional terms or conditions.
