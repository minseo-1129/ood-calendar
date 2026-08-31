# Sodam Visual Grammar

This document is the current visual and interaction grammar for the Flutter implementation. It should be treated as a design constraint, not a loose mood board.

## 1. Product posture

Sodam is a private daily doodle keepsake. The UI should feel quiet, tactile, warm, and editorial rather than gamified or utility-heavy.

Core rules:

- One Daily Sheet per calendar day.
- The Daily Sheet is always 3:4.
- Calendar is Home.
- Today is editable; past days are read-only.
- Blank days are valid and should never imply failure.
- No streak language, completion rings, counts, or social pressure.
- Motion stays restrained. Internal flow uses quiet/no-transition routes; card browsing uses horizontal swipe.

## 2. Color tokens

The implementation source of truth is `lib/app/theme.dart`.

| Token | Value | Role |
| --- | --- | --- |
| Background | `#F8F5EE` | warm ivory app field |
| Paper | `#FFFDF8` | Daily Sheet |
| Ink | `#203748` | doodle + strongest text |
| Muted ink | `#7C8888` | secondary text + controls |
| Soft ink | `#B9BCB7` | metadata + quiet helper text |
| Accent | `#809B92` | rare state indication only |

Accent is not a reward color. Use it sparingly.

## 3. Typography

Primary UI typeface: **Gaegu**.

| Role | Size | Weight | Color |
| --- | ---: | --- | --- |
| Date / month title | 28 | Regular | Ink |
| Prompt text | 19 | Regular | Ink at ~75% opacity |
| Prompt metadata label | 12 | Regular | Soft ink |
| Note input / saved note | 18 | Regular | Ink / Muted ink |
| Actions | 19 | Regular; primary may be medium | Muted ink / Ink |
| Remaining character count | 12 | Regular | Soft ink |

Prompt text must use the same visual grammar in Drawing and Card views. `그날의 질문` is metadata, not a second prompt style.

## 4. Vertical rhythm

Daily screens share the same fixed sequence even when a slot is empty:

1. Date header
2. Prompt slot
3. Daily Sheet
4. Note slot
5. Action slot

Current shared metrics live in `DailyLayoutMetrics`.

- Header height: 46
- Prompt slot height: 48
- Prompt → paper: 26
- Paper ratio: 3:4
- Paper → note: 26
- Note slot height: 116
- Action height: 44

Do not move the Daily Sheet vertically just because a prompt, note, or action is absent.

## 5. Daily Sheet states

### Today, empty
Show an **open blank Daily Sheet**. It is available to edit.

### Saved entry
Show the recorded Daily Sheet with subtle **masking-tape PNG overlays** at the upper corners. Tape means “kept / placed here,” not “locked.”

Asset: `assets/images/tape.png`

### Past, empty, read-only
Show a **sealed paper PNG** rather than an editable-looking blank sheet. This communicates that the day passed without turning the blank day into an error state.

Asset: `assets/images/sealed_paper.png`

The sealed state should not contain warning copy or failure language.

## 6. Prompt grammar

Drawing:
- Show the daily prompt directly above the paper.
- No `그날의 질문` metadata label is necessary while actively drawing.

Saved Card:
- Small metadata: `그날의 질문`
- Same prompt text style as Drawing.
- Prompt belongs to the saved entry and should remain stable if the prompt pool later changes.

Past empty:
- Do not fabricate a saved prompt if no entry exists.

## 7. One-line memo grammar

Copy:
- Placeholder: **`한 줄 메모 남기기`**

Rules:
- Hard maximum: **60 characters**.
- The formatter must prevent characters beyond 60 from being entered.
- While focused, show **`N자 남음`**.
- Do not show Flutter's default counter.
- Text may visually wrap up to 3 lines so the user can always see what they typed.
- The concept remains “one-line memo”; visual wrapping is only a layout safeguard.
- Input width equals Daily Sheet width.
- Underline belongs to the input content, not to a fixed screen coordinate.
- Leave approximately 10 px between the last text line and the underline.
- Underline is very quiet: muted ink at low opacity, slightly stronger on focus.
- Placeholder disappears on focus.

Saved memo:
- Same content width as the Daily Sheet.
- Up to 3 visual lines; ellipsis only if an old/legacy value exceeds current presentation bounds.

## 8. Actions

Action pairs occupy the same horizontal and vertical positions across screens:

- Drawing: `Undo` / `Next`
- Memo compose: `Edit` / `Save`
- Saved today Card: right-side `Edit`
- Past Card: no edit action

Do not add decorative action icons unless a future test shows a clear comprehension problem.

## 9. Calendar states

- Keep date numbers visible alongside saved doodle thumbnails for now.
- Today should not be represented by a literal `+` because that mark may also be part of a doodle.
- Empty today may use the small open-paper affordance.
- Saved day uses its doodle thumbnail.
- Past blank days remain quiet in Calendar; the sealed state is revealed when that Card is opened.

This calendar decision is intentionally provisional and can be revisited after visual testing.

## 10. Save feedback

Saving is an in-app action, so confirmation should remain **in-app**, not an OS notification.

Current pattern:
- Brief custom toast: `저장했어요`
- No system notification permission.
- No modal interruption.

## 11. Asset tone

Paper assets should feel physical but not photorealistic:
- warm ivory / cream
- low-contrast shadows
- subtle fibre
- masking tape for “saved”
- string / seal for “past empty and closed”

Avoid scrapbook decoration for its own sake. Material cues must communicate state.
