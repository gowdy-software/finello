# Releasing finello

finello is ad-hoc signed and updates itself from this repo's GitHub releases
(ADR 0004). There is no Apple Developer Program membership and no notarization.

## Once, ever

```sh
./scripts/generate-keys.sh
```

This creates the EdDSA key pair Sparkle uses to verify updates. The private key
goes into your login keychain; `.gitignore` blocks the file forms of it by name.
Paste the printed public key into `Support/Info.plist` as `SUPublicEDKey` and
commit that.

Until that key is set, finello deliberately does not start its updater at all —
an unnotarized app must never install an update it cannot verify, so no key
means no updates rather than unsafe ones.

Also confirm `SUFeedURL` in `Support/Info.plist` points at the real repo.

## Every release

Write `release-notes/<version>.html` first — a fragment, not a whole document:

```html
<h3>What's new</h3>
<ul><li>Week view now remembers which day you were on.</li></ul>
```

Sparkle shows it in the update panel. Without it she gets an empty changelog.

```sh
./scripts/release.sh 0.2.0
```

Then follow the commands it prints: copy the appcast to the repo root, commit,
tag, push, and attach the zip to a GitHub release with the matching tag.

`CFBundleVersion` is the commit count, so it increases on every release —
Sparkle compares that, not the marketing version.

## Her first launch

Gatekeeper blocks an unnotarized app the first time. Once, in person:

1. She double-clicks finello. macOS refuses to open it.
2. System Settings → Privacy & Security → "Open Anyway" next to finello.
3. Confirm.

Sparkle clears quarantine on updates it installs, so this happens **once**, not
on every release.

## The repo must stay public

A private repo would need a GitHub token embedded in the app so it could
download its own updates. That token expires on her machine and stops updates
with no visible cause. Nothing sensitive is in the repo; her Posts, captions and
Media never leave her Mac.
