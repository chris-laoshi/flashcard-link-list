# Flashcard Link List

## What it is
A personal web app for saving links. They're mostly my shared Claude artifacts (often flashcard sets), but any web link is allowed. I paste a link, press Enter, type a name, and it's saved as a row. The whole row is a big clickable/tappable link that opens it in a new tab. Must work well with a mouse and on a phone.

## Where it came from
This folder started as a copy (2026-11-20) of the current app files from my Artifact Library at C:\Users\Chris\Documents\Claude Code\claude-artifact-library (live at https://chris-laoshi.github.io/claude-artifact-library/). READ that project and its CLAUDE.md for reference only. Never modify anything in it, and never modify my notes app at C:\Users\Chris\Documents\Claude Code\notes-app either.

The copied files (index.html, app.js, storage.js, icons.js, styles.css, serve.ps1) still contain the Artifact Library's code. They are the starting point and need the changes below.

## What's different from the Artifact Library
1. **No screenshots.** Remove everything to do with preview images: the thumbnail area on each row, "Taking a snapshot…", the placeholder / "Try again", the refresh preview button, fetchPreview/previewUrl in storage.js, and the preview_path column. No Edge Function, no Microlink, no storage bucket. The row layout without a picture needs a new mockup.
2. **Any link is accepted, not just Claude artifacts.** Accept any http(s) link (add https:// if I leave it off). Store links cleaned (https, no #hash, no trailing slash; keep ?query because some sites need it) and spot duplicates by the cleaned link. Claude artifact links should still be tidied the way the Artifact Library does (claude.ai/artifact/<id>, claude.ai/public/artifacts/<id>, claude.site/artifacts/<id>, with or without www., ?query, #hash or a trailing slash).
3. **Its own Supabase table** (suggested name: flashcard_links) in the same Supabase project, with the same login as the notes app and Artifact Library. It must not share the Artifact Library's `links` table, or the two lists would mix.
4. **Its own browser storage names.** Both apps live on chris-laoshi.github.io, so they share browser storage. Rename the IndexedDB database (storage.js DB_NAME, currently 'artifact-library') and the localStorage keys (app.js 'artifacts-theme' and 'artifacts-sort') to flashcard-specific names, or the two apps will overwrite each other's data on my devices.
5. Page title, heading, empty-state text and login wording should say Flashcard Links (or similar), not Artifacts.

## Keep these from the Artifact Library (they all work and I like them)
- Plain HTML, CSS and ES-module JavaScript. No framework, no build step, no npm.
- Same design: Inter font, soft shadows, rounded cards, small animations, dark mode (follows system + toggle), friendly empty state, works on phones.
- Same local-first sync: IndexedDB copy on each device, background sync with Supabase (newest updatedAt wins, sync on change/online/tab visible/every 60s), fetch against Supabase REST/auth endpoints (no supabase-js), email+password login, sync status pill, sign out.
- Delete with a 5-second undo, using a deleted = true tombstone column (never a hard delete).
- No auto-titles: a new row appears with its name box ready to type into; names are editable later.
- Duplicate links aren't saved twice; scroll to and flash the existing row instead.
- Each row shows "Added YYYY-MM-DD" (created_at, in my local time zone). It is set once by the app when the link is added and NEVER changed afterwards. Also add the database trigger that locks it (see step3-supabase-lock-added-date.md in the Artifact Library). No "updated" date shown anywhere.
- Row actions: rename, copy link (green tick + "Link copied"), delete. Copy sits before the trash so a slip doesn't hit delete.
- Search bar above the list: filters by name only as I type, every word must match (any order, ignoring capitals), matches highlighted, match count, "No matches" with Clear search, ✕/Esc to clear, "/" to jump to it, Enter opens the only match. Adding a link clears the search.
- A–Z switch to the right of the search bar: on (default, changed from the Artifact Library 2026-11-20) = A to Z by name, untitled last; off = newest first. Remembered per device. New/renamed rows move to their place and flash.

## Open question for the mockup
Without a picture, should each row show the link's website (e.g. "claude.ai") under the name, so non-Claude links are easy to recognise? Ask me.

## Hosting
GitHub Pages from a new public repo chris-laoshi/flashcard-link-list, main branch (it will live at https://chris-laoshi.github.io/flashcard-link-list/). This folder is not a git repo yet. Git identity must stay Chris <228512593+chris-laoshi@users.noreply.github.com>. Never commit with a real email. I push with VS Code's Sync Changes button. Once I approve a feature and it's built and tested, commit it for me so I can just sync.

## How I want to work (most important)
- I'm not a coder. Explain things in plain language, and give step-by-step instructions whenever I need to do something in a website's settings (Supabase, GitHub).
- Plan first. For anything visual, make a static mockup first (mockup_v1.html, then v2…). Wait for my explicit go-ahead before building the real thing.
- Never overwrite files. New versions get new versioned files and the old ones are kept. Because GitHub Pages needs index.html, when a new version ships the current plain-named files get renamed with a version suffix and the new version takes the plain names.
- One or two changes at a time.
- Keep messages short. I like brief next steps.
- Do the database setup before the app build so the backend is checked first.

## My PC
Windows 11. Node and Python are NOT installed (Python is only the Microsoft Store stub). Git is at C:\Program Files\Git\cmd\git.exe. No gh CLI, so no Supabase CLI either: database setup is done by pasting SQL into the Supabase dashboard, with you walking me through it. To test locally, use serve.ps1 (a small PowerShell HttpListener static server, because ES modules don't load from file://) and headless Edge.

## Working order
1. Mockup of the row without a screenshot (mockup_v1.html), then wait for my go-ahead
2. SQL setup in Supabase (new table, row security, tombstones, locked Added date)
3. Build the app from the copied files
4. Create the GitHub repo and turn on Pages (walk me through it)
