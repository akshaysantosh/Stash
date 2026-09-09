# Stash

Save any link — a podcast, a YouTube video, a Spotify audiobook, a restaurant, a LinkedIn or X post — with its title, image, and a preview of the content pulled in automatically, so you don't forget about it. Tag it, edit it, mark it done once you've actually checked it out, and let Stash nudge you to revisit it later. Add links from inside the app, or straight from the Share Sheet in Safari/YouTube/Instagram/etc.

<p>
  <img src="screenshots/the-stash.png" width="320" alt="The Stash list, grouped by category, with auto-fetched titles/images/dates">
</p>

*(Screenshot uses public sample links, not real personal data.)*

## One-time setup

Same as PriceTrack:

1. **Install Xcode** from the Mac App Store, if you haven't already (shared across all your personal apps — no need to reinstall).
2. **Install XcodeGen** (also shared, skip if already installed): `brew install xcodegen`
3. **Generate the Xcode project** (run from this `Stash/` folder):
   ```bash
   xcodegen generate
   ```
   Note: `Stash/App/Info.plist` and `ShareExtension/Info.plist` are **generated** from the `info.properties` blocks in `project.yml` — edit them there, not in the plist files directly (they get overwritten every time you run `xcodegen generate`).
4. **Open `Stash.xcodeproj` in Xcode** and set the signing team on **both** targets — `Stash` and `ShareExtension` → *Signing & Capabilities* → pick your Apple ID under *Team* for each.
5. Build and run (⌘R) — Simulator or your real device.

Stash runs **fully local** by design (no iCloud/CloudKit) — a free Apple ID can't provision that capability at all, as we found out the hard way with PriceTrack. It does use an **App Group** (for sharing storage between the app and the Share Extension), which — unlike iCloud — a free Apple ID *can* provision, confirmed working on-device.

## How it works

- **The Stash / Vault** tabs — your saved links, split by whether you've gotten to them yet. Marking a link done moves it to the Vault — a keep pile, not a delete pile. Filter by category (Watch / Listen / Read / Socials / Visit / Buy / Other) with the chip row up top; the header shows a live count of what's visible.
- **Add a link** (+ button, or the Share Sheet from any app) — Stash fetches a title and thumbnail automatically. YouTube and X/Twitter go through their own public oEmbed APIs for accurate titles and (for X) the actual post text; everything else uses Apple's LinkPresentation framework, the same engine behind Messages/Safari link previews. LinkedIn/Instagram/Facebook posts get their poster's name as the title and, best-effort, a caption preview. Category is guessed from the URL/domain and always editable. A publish date is picked up where the source exposes one (reliable for X; best-effort elsewhere via common meta tags).
- **Share Sheet**: tap *Share* from inside YouTube/Instagram/Safari/etc. and send straight to Stash — no need to copy/paste a URL. Handles both proper link shares and apps (like YouTube) that share plain text with a URL embedded in it.
- **Tap a link** to see the full preview — the image itself is the tap target to open the link (Safari/the relevant app) — plus any fetched post-preview text, your own note, tags, and category/done controls.
- **Edit anything** — tap the pencil icon on a link's detail view to fix up the title, category, note, or tags after the fact. Changes only apply on Save, so Cancel always discards them, no matter what you typed.
- **Tags** are free-form and cut across categories and source apps — tag a YouTube video and a saved article both "storytelling" if that's how you think about them. Add tags from the Edit sheet (previously-used tags show up as one-tap suggestions); the list view gets a second filter row for them, alongside the existing category filter, so you can slice by category and tag together.
- **Daily recall**: from the Settings tab, turn on a once-a-day local notification tied to one tag and one time of day. The notification itself is a generic teaser ("Time to revisit your storytelling stash") — no content is baked into it — and tapping it picks a genuinely random saved link under that tag at open time, so it's always fresh even if what's tagged has changed since the notification was scheduled.

## Project structure

Mirrors PriceTrack: `App` (entry point, Info.plist, notification-delegate wiring), `Models` (SwiftData models, incl. the `Category` enum and each link's free-form `tags: [String]`), `DesignSystem` (colors, type, card/chip/flow-layout components — copied from PriceTrack unchanged, same look and feel across both apps), `Services` (`LinkMetadataService` for title/image/snippet/date fetching, `NotificationScheduler`/`NotificationRouter` for the daily recall notification), `Features` (Root, Links — including `EditLinkView` and `DailyRecallView` — and Settings), `Extensions`.

`ShareExtension/` is a separate app-extension target (Share Sheet UI + save logic) and `Shared/AppGroup.swift` defines the App Group identifier both targets use to read/write the same SwiftData store.
