# Stash

Save any link — a podcast, a YouTube video, a Spotify audiobook, a restaurant, an Amazon product — with its title, image, and description pulled in automatically, so you don't forget about it. Mark things done once you've actually checked them out.

## One-time setup

Same as PriceTrack:

1. **Install Xcode** from the Mac App Store, if you haven't already (shared across all your personal apps — no need to reinstall).
2. **Install XcodeGen** (also shared, skip if already installed): `brew install xcodegen`
3. **Generate the Xcode project** (run from this `Stash/` folder):
   ```bash
   xcodegen generate
   ```
   Note: `Stash/App/Info.plist` is **generated** from the `info.properties` block in `project.yml` — edit it there, not in the plist file directly (it gets overwritten every time you run `xcodegen generate`).
4. **Open `Stash.xcodeproj` in Xcode**, select the `Stash` target → *Signing & Capabilities* → pick your Apple ID under *Team*.
5. Build and run (⌘R) — Simulator or your real device.

Stash runs **fully local** by design (no iCloud) — a free Apple ID can't provision that capability at all, as we found out the hard way with PriceTrack, so there was no point building toward it here.

## How it works

- **To Check Out / Checked Out** tabs — your saved links, split by whether you've gotten to them yet, grouped by category (Watch / Listen / Read / Visit / Buy / Other).
- **Add a link** (+ button) — paste a URL, Stash fetches its title, description, and thumbnail automatically via Apple's own link-preview technology (the same thing that makes links look nice in Messages), no API keys or setup needed. Category is guessed from the URL and easy to change.
- **Tap a link** to see the full preview, open it in Safari/the relevant app, add a personal note, or mark it done.

## Not built yet: adding via the Share Sheet

The obviously-better way to add a link is tapping *Share* from inside YouTube/Podcasts/Safari/Amazon and sending it straight to Stash. That needs an iOS Share Extension, which in turn needs an "App Group" entitlement — the same category of thing that blocked iCloud on PriceTrack's free-tier signing. Deliberately left out of v1 so the app has a guaranteed-working way to add links first; worth revisiting once it's confirmed App Groups actually provisions on this Apple ID.

## Project structure

Mirrors PriceTrack: `App` (entry point, Info.plist), `Models` (SwiftData models), `DesignSystem` (colors, type, card/chip components — copied from PriceTrack unchanged, same look and feel across both apps), `Services` (link metadata fetching), `Features` (Root, Links), `Extensions`.
