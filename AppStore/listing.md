# Stash — App Store listing (draft)

Paste these into App Store Connect. Limits are Apple's; counts are checked.

## Name and subtitle
- **Name (30 max):** `Stash – Save Links`  (18)
  - "Stash" alone is already taken on the App Store (AU and US), so the listing name needs a suffix.
  - The name under the icon on the home screen can stay "Stash" (it comes from the app, not the listing).
- **Subtitle (30 max):** `Save it. Tag it. Come back.`  (27)

## Promotional text (170 max, editable any time without review)
Save any link — a podcast, video, article or restaurant — and actually get back to it. Pin what's next, or let Stash surprise you.  (131)

## Description (4000 max)
Stash is a calm place for the links you mean to get back to.

Share a link from Safari, YouTube, Spotify, Instagram or any app, and Stash saves it with its title and picture already filled in. Tag it, pin the few things you want to get to next, and mark it done when you have.

• Save from anywhere — use the Share Sheet or paste a link
• Title, image and a preview pulled in automatically
• Filter by what you'll do with it: Watch, Listen, Read, and more
• Tag freely — "product", "ai", "storytelling" — and filter by tag
• Up next — pin up to three links you want to get to soon
• Surprise me — filter by a tag and tap the dice for a random link you haven't finished
• Search across titles, sites, tags and your own notes
• The Vault — links you've finished, kept as a keep pile, not a delete pile
• Private by design — no account, no ads, no tracking. Your links stay on your iPhone.

Built for people who save far more than they read, watch or listen to.

## Keywords (100 max, comma-separated, no spaces after commas)
`bookmarks,read later,save links,reading list,watch later,podcast,tags,organize,article,queue`  (92)

## What's New (first version)
First release. Save links from anywhere, tag them, pin what's next and let Stash surprise you.

## Categories
- **Primary:** Productivity
- **Secondary:** Reference (or Lifestyle)

## URLs
- **Support URL (required):** the Stash GitHub repo or a page on akshaysantosh.github.io — see "Still needed" below.
- **Privacy Policy URL (required):** see `PRIVACY.md` (needs to be hosted at a public URL).
- **Marketing URL (optional):** https://akshaysantosh.github.io/

## Screenshots (iPhone 6.9", 1320 × 2868) — in `AppStore/screenshots/`
1. `iphone-6.9-1-the-stash.png` — the list with Up next
2. `iphone-6.9-2-surprise-me.png` — Surprise me from a tag
3. `iphone-6.9-3-link-detail.png` — link detail
4. `iphone-6.9-4-vault.png` — the Vault

(6.9" screenshots are accepted for all iPhone sizes; Apple scales them down. iPad is not needed — the app is iPhone-only.)

## App Privacy ("nutrition label") answers
- **Do you or your third-party partners collect data from this app?** → **No** ("Data Not Collected").
  - Stash has no account, no analytics, no ads and no servers of its own. Saved links, notes and tags are stored only on the device.
  - When you save a link, the app asks that link's own website (and YouTube/X's public oEmbed, or Apple's link-preview service) for its title and picture. That is the user fetching the page they chose, not data collected by the developer.
- **Tracking:** No. (`NSPrivacyTracking` is false in the app's privacy manifest.)

## Age rating questionnaire
Answer "None" to everything. Result: **4+**.
- Note: the app can save links to any website, so if a question asks about unrestricted web access, answer **No** — Stash shows saved titles and previews, not a general web browser. (Links open in Safari or the target app.)

## App Review information
- **Sign-in required:** No.
- **Contact:** your name, phone and email (required by Apple; not shown to users).
- **Notes for the reviewer:**
  > Stash needs no login. To try it: tap + to paste a link (for example https://www.youtube.com/watch?v=aircAruvnKk) and tap Fetch Preview, then Save. The Share Sheet extension ("Save to Stash") appears when sharing a link from Safari or YouTube. Swipe a row right to pin it to Up next; filter by a tag and tap the dice for Surprise me.

## Export compliance
Already answered in the build (`ITSAppUsesNonExemptEncryption = NO`): the app uses only standard HTTPS.

## Still needed from you
- [ ] Apple Developer Program membership and your 10-character Team ID
- [ ] A public Support URL and Privacy Policy URL (draft policy is in `PRIVACY.md`)
- [ ] Contact details for App Review
- [ ] Check the name `Stash – Save Links` is available when you create the app record
