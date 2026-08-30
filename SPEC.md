# finello — v1 Specification

Vocabulary is defined in [CONTEXT.md](CONTEXT.md) and used strictly throughout:
**Post**, **Variant**, **Platform**, **Media**, **Library**, **Done**,
**Overdue**, **Schedule**. Decisions this spec must respect are recorded in
[docs/adr/](docs/adr/).

## Problem Statement

She publishes to five platforms — Instagram, TikTok, YouTube, Snapchat and
LinkedIn — and each one wants the same idea worded differently: a longer
caption here, a shorter one there, different hashtags, a different framing.
Right now that planning lives in notes, message drafts and her head.

Three things go wrong. She loses track of which day a piece of content is meant
to go out. She rewrites captions from scratch each time instead of adapting the
one she already wrote. And when she publishes to two platforms and means to
come back for the third, nothing remembers that the third is still owed — it
simply never happens, and there is no record that it was supposed to.

Existing tools solve this by taking over publishing: hand them your account
credentials and they post for you. That is a large, ongoing trust and
maintenance cost to solve a problem that is really about memory, not about
automation.

## Solution

A calendar for one person on one Mac.

She opens finello and sees a month, each day large enough to actually recognise
the photo or video planned for it. She adds a Post to a day, drops in the
Media, picks the Platforms it is going to, and writes each Platform's caption
on its own tab — deriving the short ones from the long one rather than starting
over. When she publishes something by hand, she ticks that Platform off. A Post
that is partly done says so; a Post whose day has passed with something still
owed is flagged and counted, and finello never quietly moves it.

finello never touches the network for her content. It has no accounts, holds no
credentials, and cannot post anything anywhere. It is a memory aid with good
thumbnails.

## User Stories

### Seeing the calendar

1. As a creator, I want the month view to open by default, so that I see my plan for the current period without choosing a view first.
2. As a creator, I want each day cell large enough to show a recognisable thumbnail, so that I can identify content by sight rather than by reading titles.
3. As a creator, I want the Media thumbnail to fill the whole day cell edge to edge, so that as much of the image as possible is visible.
4. As a creator, I want the day number always visible on every cell, so that I can orient myself in the month without hovering.
5. As a creator, I want a Post's Done state always visible on its cell, so that I can scan the month for outstanding work.
6. As a creator, I want an Overdue Post's cell visibly flagged without hovering, so that a missed Post announces itself while I scroll.
7. As a creator, I want Platform badges and the Media count revealed when I hover a cell, so that detail is available on demand without cluttering the image.
8. As a creator, I want several Posts on one day drawn as a stack of offset cards, so that I can see at a glance that the day holds more than one.
9. As a creator, I want to switch to a week view, so that I have room to actually write.
10. As a creator, I want the week view to show large Media, caption previews and per-Platform Done toggles inline, so that I can work through the week's captions without opening each Post.
11. As a creator, I want to move between months and weeks with the keyboard, so that navigation does not require the trackpad.
12. As a creator, I want to jump back to today in one action, so that I can return from browsing without scrolling.
13. As a creator, I want days outside the current month shown but visually recessed, so that the grid stays a complete rectangle without misleading me.
14. As a creator, I want today's cell marked distinctly, so that I can locate the present at a glance.
15. As a creator, I want an empty day to look calmly empty rather than broken, so that a sparse month is not visually alarming.

### Creating and editing a Post

16. As a creator, I want to create a Post on a specific day, so that I can plan content for that date.
17. As a creator, I want to create a Post with no Media at all, so that I can capture an idea before the footage exists.
18. As a creator, I want to open a Post and see its Media at the top of the editor, so that I am looking at the content while I write about it.
19. As a creator, I want to add several Media items to one Post, so that I can plan a carousel.
20. As a creator, I want to reorder a Post's Media by dragging, so that the carousel sequence is the one I intend.
21. As a creator, I want to remove a Media item from a Post, so that I can correct a mistaken drop.
22. As a creator, I want to drag Media in from Finder, so that adding content is a single gesture.
23. As a creator, I want video Media to show a sensible still rather than a black frame, so that my grid is legible when most of my content is video.
24. As a creator, I want to give a Post a title, so that I can identify it in a list.
25. As a creator, I want a Post with no title to display a sensible one derived from its first caption, so that I never have to type a title I do not care about.
26. As a creator, I want to change a Post's date from within the editor, so that I can reschedule without dragging.
27. As a creator, I want to delete a Post, so that abandoned plans do not clutter the calendar.
28. As a creator, I want to be asked before a deletion that would discard Media, so that I do not lose content by a stray keystroke.

### Platforms and Variants

29. As a creator, I want to choose which Platforms a Post targets, so that a LinkedIn post does not carry four empty TikTok fields.
30. As a creator, I want a Variant created for each Platform I select, so that each has somewhere to hold its own wording.
31. As a creator, I want the Post editor to show one tab per selected Platform, so that I can write for one audience at a time without scrolling past the others.
32. As a creator, I want each Variant to hold its own caption, description and hashtags, so that I can adapt tone and length per Platform.
33. As a creator, I want to copy another Platform's caption into the one I am editing, so that I can cut the long version down instead of rewriting it.
34. As a creator, I want each Platform to show its own icon and colour, so that I can identify Platforms by sight across the app.
35. As a creator, I want to add a Platform to an existing Post, so that I can cross-post something I had not planned to.
36. As a creator, I want to remove a Platform from a Post, so that I can drop a Platform without deleting the Post.
37. As a creator, I want to be warned before removing a Platform whose Variant already has writing in it, so that I do not silently lose a caption.
38. As a creator, I want every Variant of a Post to share the same Media, so that I manage the content in one place.

### Done and Overdue

39. As a creator, I want to tick a Variant as Done once I have published it by hand, so that I record what has actually gone out.
40. As a creator, I want a Post to show how many of its Variants are Done, so that partial progress is visible without opening it.
41. As a creator, I want to tick Variants Done directly from the week view, so that recording progress does not require opening the editor.
42. As a creator, I want a Post whose day has passed with Variants still outstanding to be marked Overdue, so that the omission is visible.
43. As a creator, I want an Overdue count visible in the toolbar, so that I know work is outstanding without scrolling into the past.
44. As a creator, I want to open a list of Overdue Posts from that count, so that I can work through them.
45. As a creator, I want to jump from that list to the Post in the calendar, so that I can act on it in context.
46. As a creator, I want finello never to move a Post's date on its own, so that the calendar stays an honest record of what I planned and when.

### Rescheduling

47. As a creator, I want to drag a Post from one day to another, so that rescheduling is a single gesture.
48. As a creator, I want to undo a reschedule, so that an accidental drag costs me nothing.
49. As a creator, I want to undo and redo edits generally, so that I can experiment without fear.
50. As a creator, I want dragging onto a day that already has a Post to add to that day, so that a day can hold several Posts.

### Media and the Library

51. As a creator, I want Media copied into finello when I add it, so that moving, renaming or deleting the original never breaks my calendar.
52. As a creator, I want adding a large video to feel instant, so that planning does not stall on file copying.
53. As a creator, I want to reveal finello's Library in Finder, so that I can back it up or inspect it myself.
54. As a creator, I want my Media never to be uploaded anywhere, so that unpublished content stays private until I publish it.

### Setup and updates

55. As a non-technical recipient, I want to approve finello once at first launch and never again, so that using it does not require understanding Gatekeeper.
56. As a creator, I want finello to tell me when a new version is available, so that I get improvements without checking anything.
57. As a creator, I want to see what changed before installing an update, so that I am not surprised by a new version.
58. As a creator, I want to decline or defer an update, so that finello does not interrupt me mid-task.
59. As a creator, I want an update to preserve all my Posts and Media, so that upgrading is never a risk.
60. As the maintainer, I want to publish a release by tagging and pushing, so that shipping a fix is not a manual ceremony.
61. As the maintainer, I want updates cryptographically verified, so that an unnotarized app cannot be tricked into installing something I did not sign.

## Implementation Decisions

### Modules

- **Model** — the `Post` and `Variant` SwiftData entities and the `Platform` type. Owns all derived-state rules.
- **Store** — the single facade over persistence and the Library. Everything above it creates, queries and mutates Posts through it; nothing above it touches SwiftData or the filesystem directly. Constructed with a model container and a Library root directory, both injectable.
- **Library** — Media import, storage and removal on disk. Reached through the Store, not directly.
- **CalendarLayout** — pure date arithmetic: which days a month grid contains, week boundaries, leading and trailing days. No dependencies.
- **Views** — MonthView, WeekView, PostEditor, OverdueList. Read from the Store via SwiftUI observation.
- **Updater** — Sparkle integration. Isolated behind a thin wrapper so the rest of the app never imports it.

### Schema

A **Post** holds: a date (day granularity, no time), an optional title, an ordered list of Media references, and its Variants. A **Variant** holds: its Platform, a caption, a description, hashtags, and its own Done flag. Media references point into the Library; Media bytes are never stored in SwiftData (ADR 0002, ADR 0003).

`Platform` is a fixed set of five — Instagram, TikTok, YouTube, Snapchat, LinkedIn — and is **persisted as a string, not as a database enum**, so that adding a sixth Platform later is a code change with no schema migration.

### Derived state

None of the following is stored; all are computed from the Variants:

- **Done state** of a Post is *none*, *some* or *all*, from the fraction of its Variants marked Done. A Post with no Variants is *none*.
- **Overdue** is true when the Post's date is strictly before today and its Done state is not *all*. It is recomputed on read and never written; finello does not mutate dates (ADR 0001 in spirit, story 46).
- **Display title** is the Post's title when non-empty, otherwise the opening words of the first non-empty caption among its Variants in Platform order, otherwise a date-based fallback.

Storing any of these would create a second source of truth that could drift from the Variants.

### Media

Media is copied into the Library on add and finello owns the copy (ADR 0002). Same-volume adds are copy-on-write clones on APFS and are effectively instant; cross-volume adds are real copies and may need progress feedback. Library filenames are generated, not taken from the source, so that two files with the same name cannot collide.

Video poster frames are extracted at approximately one second in, not at frame zero, because leading frames are frequently black or a fade. The chosen offset is a pure function of asset duration so that very short clips do not seek past their own end. The offset is not persisted in v1.

### Presentation rules

Month cells draw the first Media item edge to edge with a scrim at top and bottom. **Always visible**: day number, Done pill, Overdue flag. **On hover**: Platform badges, Media count. Several Posts on a day draw as offset cards — always visible, since it is a shape rather than metadata. A Post with no Media draws its display title on a tinted card.

The week view is the writing surface: large Media, caption preview, per-Platform Done toggles inline.

The editor shows Media first, then a segmented control across only the Platforms the Post targets, then that Platform's fields. A copy-from action pulls another Platform's caption in as a starting point.

### Platform and distribution

Native SwiftUI, Swift 6, Xcode project (an app target is required for Sparkle and signing configuration). Deployment target macOS 15. **App Sandbox off** and ad-hoc signing with Sparkle self-updates from the public repo (ADR 0004). Bundle identifier `dev.gowdy.finello`, which is permanent — Sparkle uses it to match an update to the installed app.

Releases are semantically versioned from git tags, with a monotonically increasing build number, since that is what Sparkle compares.

## Testing Decisions

### What makes a good test here

A test drives finello the way the person does and asserts what she would see. It creates a Post, marks a Variant Done, and asserts the Post reports *some* — it does not assert that a particular property was set or a particular method was called. Rewriting how derived state is computed must not break a single test; changing what she sees must break several.

### Seams

**One seam: the Store.** Tests construct it with an in-memory model container and a temporary directory as the Library root, then exercise it. This deliberately puts SwiftData, `FileManager` and the on-disk Library layout *behind* the seam, so tests cover real persistence and real file operations without touching her actual data. Two candidate seams collapse into this one: had media import been separate, the filesystem would have needed its own test surface.

**Pure functions tested directly**, since they have no dependencies to seam: the month grid (leading and trailing days, week start, month lengths), the poster-frame offset, and title derivation.

**Not unit tested**: SwiftUI views, and Sparkle. Views are asserted through the Store beneath them; the updater is a third-party integration whose meaningful failures are environmental and are verified by installing a real release.

### Coverage

Through the Store: creating Posts with and without Media; several Posts on one day; adding, reordering and removing Media; selecting and deselecting Platforms and the Variants that appear and disappear; marking Variants Done and the *none / some / all* rollup; Overdue across the day boundary and the assertion that dates are never mutated; rescheduling and undo; querying a month and a week; Media import from same and different volumes, filename collisions, and removal.

Pure: month grids across month lengths, leap years, and months starting on each weekday; poster-frame offset for assets shorter than the nominal offset; title derivation with no title, an empty first caption, and no captions at all.

### Prior art

None — this is the first code in the repo. Tests use **Swift Testing** (`@Test`, `#expect`) rather than XCTest, matching the Swift 6 toolchain. This spec sets the prior art for what follows.

## Out of Scope

Everything below was considered during design and cut deliberately. Check here and in the ADRs before adding one back.

- **Any publishing integration.** finello never contacts a social network — no accounts, no credentials, no scheduled posting (ADR 0001). This is structural, not a v1 limitation.
- **Any audience analytics** — reach, views, follower growth. Structurally impossible given the above.
- **Yearly view.** Cut: 365 cells cannot satisfy the recognisable-thumbnail requirement that motivates the app.
- **Statistics tab.** Cut as scope creep.
- **Manual video poster-frame picker.** Automatic extraction only; revisit if her real footage looks bad in the grid.
- **Per-Platform Media.** Every Variant of a Post shares one set of Media.
- **Staggered per-Platform dates.** The date lives on the Post. Publishing the same idea on different days means two Posts.
- **Time of day.** Posts have a date, not a datetime.
- **Multi-user, sync, iCloud, iOS, sharing, export.** Single person, single Mac.
- **App Store distribution and notarization.** Ad-hoc signing and Sparkle instead (ADR 0004).
- **Search.** May be worth adding once she has enough Posts to need it.

## Amendments since this spec was written

Recorded here rather than edited silently into the text above, so the reasoning
survives.

- **Several Posts on a day render as a 2×2 grid, not a stack of offset cards.**
  The stack hid every Post but the front one, which made them unreachable. Each
  grid tile is its own click target and its own drag source. Beyond four, a
  `+N` pill opens a menu listing every Post on the day.
- **The Post editor has no separate "Add" button.** The dashed drop zone is
  itself the button: click it to choose files, or drop onto it.
- **Copy-from copies caption, description and hashtags**, not the caption alone.
  The action is explicit and named after its source, so an overwrite is what she
  asked for; copying one field of three made her redo the other two by hand.
- **`MediaLibrary` is tested directly**, which is a second test surface the
  Testing Decisions section said it had collapsed away. Filesystem behaviour —
  name collisions, a deleted Library folder, cross-volume copies — is where the
  real failures live, and asserting it only through the Store would have tested
  it less honestly. The Store tests still drive it end to end.
- **Story 60 is met on demand, not by tagging.** The story asked to "publish a
  release by tagging and pushing". `.github/workflows/release.yml` instead runs
  only from the Actions tab: it tests, builds, signs, creates the tag and
  release and commits the appcast. Deliberate — a release should be something a
  person asks for, not a side effect of a tag. `scripts/release.sh` still
  builds and signs locally without publishing anything.
  The signing key reaches CI either as a repository secret or pasted per run.
  Pasting is offered because it keeps the key in a password safe rather than in
  GitHub, but a manual run's inputs live in the run's event payload, and this
  repository is public — so a pasted key must be treated as disclosed.
- **`AppModel.startupWarning` is not in any story.** It opens the window with a
  visible warning when the on-disk store cannot be opened, instead of refusing
  to launch on her machine with no explanation.

## Further Notes

- **Her macOS version is still unconfirmed.** Targeting 15 is safe for any MacBook Air under two years old, but the real number is needed before handing over a build to test against.
- **The Sparkle EdDSA key pair does not exist yet.** It is generated at the first release; the private half goes into the login keychain and never into the repo (`.gitignore` blocks it by name), the public half into the app's `Info.plist`.
- **The repository must stay public.** A private repo would require an embedded GitHub token for the app to download its own updates — a credential that expires on a non-technical user's machine and stops updates with no visible cause (ADR 0004).
- **First launch is blocked by Gatekeeper** and approved once in System Settings, in person, during setup. Sparkle clears quarantine on updates it installs, so this happens once rather than on every release.
- **The Library is the irreplaceable thing.** It holds the only copy of Media whose originals she may have deleted. Any operation that removes from it deserves confirmation, and it is the thing to protect first in any future migration.
