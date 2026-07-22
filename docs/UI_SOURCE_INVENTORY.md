# UI Source Inventory

Source: `TinyCanvas-46-Screen-UI-Source.zip` → `README.md`, `index.html`,
`styles.css`, `app.js`, `screen-inventory.json`, `screens/01–46.html`.
This inventory is the fidelity contract for the Flutter build.

## Design tokens (`styles.css :root`)

| Token | Value | Flutter home |
|---|---|---|
| --ink | #17253D | `TcColors.ink` |
| --muted | #667085 | `TcColors.muted` |
| --canvas | #F6F4EF | `TcColors.canvas` |
| --paper | #FFFDF8 | `TcColors.paper` |
| --navy | #111C34 | `TcColors.navy` |
| --blue / --blue2 | #3E7FA0 / #69B3C8 | `TcColors.blue/blue2` |
| --coral | #ED6B67 | `TcColors.coral` |
| --gold | #F2BD55 | `TcColors.gold` |
| --leaf / --violet | #58A678 / #8C76CF | `TcColors.leaf/violet` |
| --line | #E8E3D8 | `TcColors.line` |
| --shadow | 0 18px 50px rgba(23,37,61,.13) | `TcShadows.panel` |
| --radius / --radius-sm | 28 / 18 | `TcRadius.panel/small` |
| font | Inter (400/600/700/800/900) | `TcType` (see fidelity exceptions) |

## Component inventory → Flutter widget

| Source component | Spec | Flutter |
|---|---|---|
| Nav rail | 94px, gradient #15233F→#111A30; item 62px r18 #B7C0D3; ≤900px → 74px | `TcShell` |
| Brandmark | 52px r18 coral→gold gradient | `TcBrandmark` |
| Buttons | r16 minH48; primary #397D9D→#5AA8BE; coral #E95F61→#EF8177; danger #AD2D35/#FFF0EF; soft; dark; link | `TcButton` (6 kinds) |
| Icon button | 48px r16 | `TcIconButton` |
| Type scale | h1 31 / h2 23 / h3 16 / eyebrow 11 w800 | `TcType` |
| Panel / card | r28 / r22 + shadows | `TcPanel` / `TcCard` |
| Hero | gradient #1A2B4D→#244E68→#5BAAC0 | home `_hero` |
| Badge pill | 11px w800 (normal/gold/coral) | `TcBadge` |
| Search | 54px r18 | `TcSearchField` |
| Tool dock | rgba(17,28,52,.94) r22; tool 48 r15, active gold | canvas `_ToolDock` |
| Swatch | 28px r10 | `ColorSwatchButton` |
| Modal | r30 max520 paper; visual 92 r30 | `showTcModal` + `TcModalCard` |
| Art board / paper | r28 #F0EDE5; paper aspect 1.18 r14 | canvas & preview |
| Price | 42px w900 | paywall |
| Switch | 46×26 | `TcSwitch` |
| Grid / split | gap 18; split 1.15fr/.85fr; ≤900px 2col/1col | `Responsive` |

## Screens 01–46 (all recreated)

01 Splash · 02 Local Data Repair · 03 Welcome · 04 How to Color ·
05 Sound Choice · 06 Home · 07 Explore Categories · 08 Category Results ·
09 Search · 10 Page Preview (free/draft) · 11 Page Preview (locked) ·
12 Coloring Canvas · 13 Canvas Tool Settings · 14 Color Palette ·
15 Sticker Drawer · 16 Clear Confirmation · 17 Save Failure ·
18 My Art (grid) · 19 My Art (empty) · 20 Artwork Detail · 21 Rename ·
22 Delete + Undo · 23 Badges · 24 Badge Earned · 25 Adult Gate ·
26 Adult Gate Cooldown · 27 Paywall · 28 Paywall (offline) ·
29 Paywall (product unavailable) · 30 Checkout Handoff ·
31 Purchase Pending · 32 Purchase Success · 33 Purchase Failure ·
34 Restore · 35 Restore (offline/results) · 36 Parent Zone ·
37 Sound & Motion · 38 Storage & Erase · 39 Export flow ·
40 Export permission / OS settings guidance · 41 Privacy Policy ·
42 Terms · 43 Open-source Licenses · 44 About · 45 Update available ·
46 Unsupported device / forced update.

Named variants covered: first-launch, locked picture, save-failed,
adult-gate cooldown, paywall offline, product unavailable, restore offline,
reduced-motion, high-contrast, empty/error/loading/low-storage states.

## Microcopy

All microcopy was transcribed verbatim from the screens (e.g. "Getting your
colors ready…", "Make a little world of color.", "Clear this picture?" /
"Your original line art stays safe.", "We couldn't save yet", "Grown-ups
only", "Unlock all 100 pictures", "The final localized price appears from
Amazon before checkout.", "You'll have five seconds to undo.", "Saved to the
gallery!" / "The PNG is in Pictures → TinyCanvas", OS path "Apps &
Notifications → TinyCanvas Adventures → Permissions → Allow Photos and
media"). No copy was reworded.

## Behavioral notes from `app.js`

- Scene thumbnails/heroes are procedural `scene(seed, line)` renders — mirrored
  by `ScenePainter`/`LineArtPainter` with the same seed-driven approach.
- Canvas badges: "One finger colors", "Two fingers move & zoom", zoom % badge.
- Stamps: star, heart, flower, balloon, cloud, butterfly.
