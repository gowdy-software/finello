# Media is copied into a finello-owned Library, not referenced in place

When media is added to a Post, finello copies the file into its own Library and
treats that copy as the source of truth, rather than storing a reference to
wherever the file happened to be sitting. Referencing is cheaper in theory but
fails badly in practice on macOS: clearing the Desktop, renaming a folder, or
letting iCloud offload originals turns the calendar into a grid of broken
thumbnails with no way to tell what was meant to go out.

## Consequences

- The Library is self-contained and can be backed up or moved as one thing.
- On APFS a same-volume copy is a copy-on-write clone: effectively instant, and
  consuming no additional disk until one copy is modified. The usual
  disk-duplication objection to copying does not apply here.
- Copies from another volume (an SD card, an external drive) are real copies,
  which is the desired behaviour anyway.
- The Library lives outside the app bundle so updates never touch it.
