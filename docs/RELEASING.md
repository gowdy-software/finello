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

## Getting the key out of the keychain

```sh
./scripts/export-signing-key.sh
```

Writes `sparkle-private-key.txt` (git-ignored). Put its contents in your
password safe, then `rm` the file.

## Two ways to give CI the key — and only one is safe on a public repo

**Repository secret (recommended).** Settings -> Secrets and variables ->
Actions -> new secret named exactly `SPARKLE_PRIVATE_KEY`. Set once; leave the
workflow's `signing_key` box blank when you run it. GitHub never displays a
secret's value.

**Pasting it into the `signing_key` box (danger on a public repo).** The
workflow masks it so it will not appear in the job log — but a manual run's
inputs are part of the run's own event payload, and this repository is
**public**, so that payload is readable by anyone. Treat a key pasted this way
as disclosed: rotate it (`generate-keys.sh`, new `SUPublicEDKey`, ship a
release signed with the old key first so installed copies can still update).

The key is the only thing standing between her Mac and a malicious update,
because finello is not notarized. That is why this matters.

## Every release

Write `release-notes/<version>.html` first — a fragment, not a whole document:

```html
<h3>What's new</h3>
<ul><li>Week view now remembers which day you were on.</li></ul>
```

Sparkle shows it in the update panel. Without it she gets an empty changelog.

Releases only ever happen on demand. Go to the repository's **Actions** tab ->
**Release** -> **Run workflow**, enter the version, and leave `signing_key`
blank if you have set the secret. CI tests, builds, signs, creates the tag and
release, attaches the archive, and commits the appcast to `main`.

Nothing ships because a tag or a commit appeared — there is no push trigger.

To build and sign locally without publishing anything:

```sh
./scripts/release.sh 0.2.0
```

Then, if you want to publish that by hand, follow the commands it prints: copy the appcast to the repo root, commit,
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
