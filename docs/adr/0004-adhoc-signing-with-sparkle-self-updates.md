# Ad-hoc signed, sandbox off, self-updating from a public GitHub repo

finello is distributed as an ad-hoc signed app — no Apple Developer Program
membership, no notarization — and updates itself with Sparkle 2 by reading an
appcast published from its public GitHub repo. Updates are verified with an
EdDSA key pair, which is free and independent of Apple code signing, and which
is what makes an unnotarized self-update safe to accept.

## Consequences

- First launch is blocked by Gatekeeper. The recipient approves it once in
  System Settings → Privacy & Security, in person, during setup. Sparkle clears
  quarantine on updates it installs, so this ritual happens once, not on every
  release.
- **The repo must stay public.** A private repo would require a GitHub token
  baked into the app to download its own releases — a credential that expires
  on a non-technical user's machine and stops updates with no visible cause.
  Nothing sensitive lives in the repo; her posts, captions and media never go
  near it.
- **The App Sandbox is off.** Sandboxing buys little here — the app has no
  network access (ADR 0001), no scripting and no plugins, so there is no
  untrusted input for an attacker to arrive on — and it costs real complexity
  in the one component that must never break, since Sparkle inside a sandbox
  requires additional XPC services.
- The bundle identifier `dev.gowdy.finello` is effectively permanent: Sparkle
  uses it to recognise that an update belongs to the installed app, so changing
  it would break the update chain.
