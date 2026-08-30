# finello

A local-only macOS calendar for planning social media posts.

Plan what goes out on which day, adapt the wording per platform, publish by
hand, tick it off. finello never talks to a social network — see
[ADR 0001](docs/adr/0001-planning-only-never-touches-the-network.md).

- **Vocabulary**: [CONTEXT.md](CONTEXT.md) — read this first.
- **Decisions**: [docs/adr/](docs/adr/)
- **Spec**: [SPEC.md](SPEC.md) — v1 scope, user stories, testing seams.

## Shape

**Monthly view** (default) — roughly 210×140pt cells, photo edge to edge.
Always visible: day number, done pill (`2/3`), overdue flag. On hover: platform
badges and image count. Several Posts on one day render as a stack. Drag to
reschedule, ⌘Z to undo. An overdue count in the toolbar opens a list.

**Weekly view** — the writing view. Large media, caption previews, per-platform
done toggles inline in the cell.

**Post editor** — media at the top, then segmented tabs across the platforms
this Post targets, each with caption, description, hashtags and its own done
checkmark. A *copy from another platform* action, for cutting the long version
down.

## Deliberately not in v1

Yearly view · statistics tab · manual video poster-frame picker · per-platform
media · staggered per-platform dates · time of day · any publishing integration.

Each was considered and cut. Check the ADRs and this list before adding one back.

## Build

Native SwiftUI, Swift 6, Xcode project. Deployment target macOS 15. SwiftData.
App Sandbox off. Bundle identifier `dev.gowdy.finello`.
