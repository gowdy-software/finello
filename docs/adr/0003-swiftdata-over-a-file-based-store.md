# SwiftData, not a file-based store

Persistence is SwiftData rather than Codable JSON on disk. The data is tiny —
on the order of a few hundred Posts a year, single user, single process — so
both options are technically adequate, and the deciding factor is that
SwiftData's `@Query` is wired into SwiftUI's observation model, which hands us
the entire "calendar redraws when data changes" layer for free.

## Consequences

- The known cost is schema migration, and this app will certainly gain fields.
  Model types are kept plain enough that falling back to a file-based store
  stays possible if migrations become more trouble than the free plumbing is
  worth.
- Media files are *not* stored in SwiftData; the store holds paths into the
  Library (see ADR 0002).
