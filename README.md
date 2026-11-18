# pihole-lists

My Pi-hole blocklist, kept as plain text so it can be reviewed, diffed, and reapplied to a fresh install.
It holds the domains and patterns I block on top of the subscribed lists, plus the subscribed lists themselves.

## Contents

| File                   | What it holds                                                      | Entries |
| ---------------------- | ------------------------------------------------------------------ | ------- |
| `lists/adlists.txt`    | Subscribed adlist URLs, one per line                               | 8       |
| `lists/deny-exact.txt` | Exact domains to deny, one per line                                | 128     |
| `lists/deny-regex.txt` | Regex deny patterns, one per line, in the dialect Pi-hole expects | 84      |

The files are plain lines with no comments, so they can be piped straight into `xargs`.
Anything that needs explaining belongs in this README, not in the list files.

## What is not here

The allowlist is deliberately left out.
It reflects the services I use, and it is not part of "what I block".

One adlist, `hagezi/native.tiktok.extended`, is subscribed but not assigned to any group in the Pi-hole this was exported from.
It is listed here because it exists there, but it was not actively blocking anything at export time.

## Applying the lists

Run these where the `pihole` CLI is available, such as inside the Pi-hole pod.

```bash
xargs -d '\n' pihole deny < lists/deny-exact.txt
xargs -d '\n' pihole --regex < lists/deny-regex.txt
```

Adlists are added in the web UI under Adlists, followed by `pihole -g` to rebuild gravity.
Both commands skip entries that already exist, so they are safe to run again.
I have not yet run them against an empty Pi-hole.

## Notes on specific rules

- `iadsdk.apple.com` blocks Apple's iAd SDK hosts, which are used by apps that serve Apple-brokered ads.
- Moloco, Mintegral, and Pangle patterns target in-app ad networks seen in the query log of a game that served full-screen video ads.
- `adjust.io` blocks attribution tracking and is a wildcard on purpose.
- App Store ads cannot be blocked by DNS, because they are served from the same hosts as the store's own content.
  Blocking `amp-api*.apps.apple.com` would break the App Store.

## License

Licensed under either of

- Apache License, Version 2.0 ([LICENSE-APACHE](LICENSE-APACHE) or <http://www.apache.org/licenses/LICENSE-2.0>)
- MIT license ([LICENSE-MIT](LICENSE-MIT) or <http://opensource.org/licenses/MIT>)

at your option.

### Contribution

Unless you explicitly state otherwise, any contribution intentionally submitted for inclusion in the work by you, as defined in the Apache-2.0 license, shall be dual licensed as above, without any additional terms or conditions.
