# Ood Project Handoff

Use this file when starting a fresh ChatGPT session for Ood.

## 1. First rule: GitHub is the source of truth

Repository:

```text
minseo-1129/ood
```

Before changing anything:

1. Read this file.
2. Inspect the latest `main`.
3. Read the relevant source files before editing them.
4. Do not assume a commit SHA in an old chat is still current.

When implementation is requested, make the change in GitHub, commit it, and push to `main`. Do not stop at copy/paste instructions unless the user explicitly asks for instructions.

The user may also make independent local/GitHub changes, so always re-check `main` immediately before writing.

## 2. Product

**Ood** is a private daily doodle keepsake for adults.

Core idea:

> One day, one small drawing. Constraint without pressure.

Product rules:

- Calendar is Home.
- Exactly one Daily Sheet per calendar day.
- Daily Sheet is always 3:4 portrait.
- Today is editable.
- Past entries are read-only, except Delete is allowed.
- Blank days are valid and must never imply failure.
- Optional one-line memo.
- No login or server in V1.
- No social features.
- No streaks, counts, completion rings, mood ratings, or tracker-like pressure.
- No customization system in V1.
- No persistent bottom navigation.
- Internal transitions should feel quiet and restrained.

Core flow:

```text
Calendar
→ tap date
→ Card
→ Edit (today only)
→ Drawing
→ Next
→ optional memo
→ Save
→ Calendar
```

Card browsing swipes horizontally day-by-day, including blank dates.

## 3. Visual direction

Ood should feel:

- warm
- handmade
- tactile
- quiet
- editorial
- adult rather than childish

Primary visual tokens:

| Token | Value |
| --- | --- |
| Background | `#F8F5EE` |
| Paper | `#FFFDF8` |
| Ink | `#203748` |
| Muted ink | `#7C8888` |
| Soft ink | `#B9BCB7` |
| Accent | `#809B92` |

Typography:

- Primary UI font: **Gaegu**
- Avoid over-decorating.
- Material cues should be subtle: paper fibre, deckle edge, low-contrast depth.
- Saved/blank sheets should not use tape, seals, scrapbook decoration, or completion marks.

The detailed visual source of truth is:

```text
docs/VISUAL_GRAMMAR.md
```

## 4. Calendar rules

Calendar is an accumulation surface for the doodles themselves.

- Dates are quiet metadata.
- Saved days show only the doodle thumbnail.
- No paper/card boxes behind thumbnails.
- No tape, seals, string, or `+`.
- Empty days leave the doodle area empty.
- Today has a very subtle accent background.
- Future days are muted and not tappable.
- Doodle thumbnails use content-aware fitting so tiny doodles remain legible.
- Content-aware enlargement is capped at about 1.75×.

Current Calendar brush treatment:

- thumbnail stroke width: **1.08**
- thumbnail ink strength: **0.78**
- intentionally lighter than full-size drawing

## 5. Drawing / brush behavior

Stroke data is stored as normalized points, so rendering changes do not invalidate old entries.

Current brush direction:

- dry pencil / graphite / restrained crayon
- not waxy children's crayon
- deterministic texture so saved doodles render consistently
- translucent center path + offset fibres + fine grain
- full-size stroke width: **3.3**

Current interaction tuning:

- pointer movement threshold: about **0.55 px**
- interpolation step: about **0.78 px**
- rendered path uses two gentle smoothing passes before quadratic interpolation
- goal: preserve gesture character while reducing stiffness

Relevant files:

```text
lib/screens/drawing_screen.dart
lib/widgets/daily_sheet.dart
```

## 6. Prompt system

Prompts are local and deterministic, not AI-generated.

Current pool:

- 오늘 이상하게 기억나는 것 하나
- 창문 밖에서 오늘 처음 본 것
- 발밑에 있던 것
- 오늘 손에 제일 오래 있던 물건
- 지나가다 눈이 멈춘 곳
- 오늘 들은 소리 중 하나
- 어제와 달랐던 한 가지
- 오늘 만난 사람의 뒷모습

Prompt selection is deterministic by date and the chosen prompt is persisted into entries/drafts so it remains stable later.

Relevant file:

```text
lib/content/prompt_provider.dart
```

## 7. Memo

Memo placeholder:

```text
한 줄 메모 남기기
```

Rules:

- hard max 60 characters
- no Flutter default character counter
- focused state shows `N자 남음`
- may visually wrap up to 3 lines as a layout safeguard
- concept remains a one-line memo

## 8. Save / Delete behavior

Save and Delete use the same custom in-app confirmation dialog.

Rules:

- centered title/message
- paper-colored dialog
- radius 28
- divider above actions
- vertical divider between actions
- Cancel on left, Okay on right
- no toast after completion
- after Save/Delete, return to Calendar
- deleting today also clears today's draft
- deleting a past entry does not affect today's draft

Relevant shared UI:

```text
lib/widgets/daily_layout.dart
```

## 9. Persistence

V1 uses:

```text
shared_preferences
```

Stored entry fields:

- dateKey
- strokes
- note
- prompt
- createdAt
- updatedAt

Draft fields:

- dateKey
- strokes
- note
- prompt
- updatedAt

Storage keys:

```text
ood.entries.v2
ood.entries.v1          # legacy support
ood.todayDraft.v2
```

Draft autosaves after drawing changes, undo, and note changes. Explicit Save commits the entry and clears the draft.

Relevant file:

```text
lib/data/entry_store.dart
```

## 10. Main architecture

Key files:

```text
lib/main.dart
lib/app/theme.dart
lib/models/doodle_models.dart
lib/utils/date_labels.dart
lib/content/prompt_provider.dart
lib/navigation/quiet_route.dart
lib/data/entry_store.dart
lib/widgets/daily_layout.dart
lib/widgets/daily_sheet.dart
lib/screens/calendar_screen.dart
lib/screens/drawing_screen.dart
lib/screens/compose_card_screen.dart
lib/screens/card_browse_screen.dart
docs/VISUAL_GRAMMAR.md
docs/ANDROID_RELEASE.md
test/widget_test.dart
```

## 11. Android identity and release

Current app version:

```text
1.0.0+1
```

Application ID:

```text
com.ood.app
```

Android config:

- compile SDK 36
- target SDK 36
- Java/Kotlin target 17
- release signing via local `android/key.properties`

Never commit:

- `android/key.properties`
- `*.jks`
- `*.keystore`
- passwords or signing secrets

Full release instructions:

```text
docs/ANDROID_RELEASE.md
```

Branches:

- `main` — active development / release work
- `release/v1.0.0` — Android V1 release line
- `v1` — frozen earlier V1 product snapshot

## 12. Android icon and splash

Branding direction:

- calendar + loose doodle illustration
- plain warm-ivory background
- no radiant/glow
- no pre-baked rounded-square frame inside another launcher mask
- PNG assets only for current Android V1 work
- purpose-specific sizing/padding instead of cropping one finished square image for every use

Launcher locations:

```text
android/app/src/main/res/mipmap-mdpi/ic_launcher.png
android/app/src/main/res/mipmap-hdpi/ic_launcher.png
android/app/src/main/res/mipmap-xhdpi/ic_launcher.png
android/app/src/main/res/mipmap-xxhdpi/ic_launcher.png
android/app/src/main/res/mipmap-xxxhdpi/ic_launcher.png
```

Round launcher equivalents use `ic_launcher_round.png`.

Splash resource name must be:

```text
splash_mark
```

Density locations:

```text
android/app/src/main/res/drawable-mdpi/splash_mark.png
android/app/src/main/res/drawable-hdpi/splash_mark.png
android/app/src/main/res/drawable-xhdpi/splash_mark.png
android/app/src/main/res/drawable-xxhdpi/splash_mark.png
android/app/src/main/res/drawable-xxxhdpi/splash_mark.png
```

The user may manually replace these generated PNGs. If so, inspect the latest GitHub state before changing icon/splash code.

## 13. Development environment

Typical local project location:

```text
C:\dev\ood
```

Physical Android test device:

```text
R3CWC0JDAER
```

Normal test loop:

```bash
cd /c/dev/ood
git pull
flutter clean
flutter pub get
flutter run -d R3CWC0JDAER
```

Release builds:

```bash
flutter build apk --release
flutter build appbundle --release
```

Outputs:

```text
build/app/outputs/flutter-apk/app-release.apk
build/app/outputs/bundle/release/app-release.aab
```

## 14. Collaboration expectations

This is important.

The user is comfortable making design judgments but does not want to be forced into manual code editing when the assistant can change GitHub directly.

When the user says things like:

- change this
- fix this
- implement this
- commit this
- push this

the expected behavior is:

1. inspect latest `main`
2. inspect the relevant files
3. make the actual repository change
4. commit
5. push to `main`
6. report the commit SHA and a concise summary

Do not claim something is committed merely because an image was generated. Verify the repository state.

For visual iteration, prefer making one clear design decision and implementing it rather than offering an endless menu of options.

## 15. Things discussed but not implemented

Potential future extensions:

### Monthly Sheet

A month becomes one composed sheet of that month's doodles.

- not a rigid completion grid
- blank dates simply become space
- no counts or completion percentages

Long-term concept:

> 하루에는 그린다 → 한 달이 지나면 한 장이 된다 → 1년이 지나면 한 권이 된다.

Possible later extensions:

- one restrained ink per month
- subtle seasonal prompt pools
- Year Book / annual export / PDF / poster

These are future ideas only. Do not implement them unless explicitly requested.

## 16. Recommended first message in a new ChatGPT chat

Paste this:

```text
Continue my Flutter project Ood at GitHub repo minseo-1129/ood.

First read docs/PROJECT_HANDOFF.md and inspect the latest main. Treat GitHub as the source of truth because I may have changed things since the previous chat.

When I ask for an implementation change, modify the repo directly, commit it, and push to main instead of only giving me instructions.

My Android test device is R3CWC0JDAER.

After reviewing the repo, I will give you the next task.
```
