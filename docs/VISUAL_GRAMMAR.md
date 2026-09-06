# Ood Visual Grammar

This document is the current visual and interaction grammar for the Flutter implementation. It should be treated as a design constraint, not a loose mood board.

## 1. Product posture

Ood is a private daily doodle keepsake. The UI should feel quiet, tactile, warm, and editorial rather than gamified or utility-heavy.

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
- Note slot height: 104
- Action height: 44

Do not move the Daily Sheet vertically just because a prompt, note, or action is absent.

## 5. Daily Sheet states

### Today, empty
Show an **open blank Daily Sheet**. It is available to edit.

### Saved entry
Show the recorded Daily Sheet **plain**, with no tape or extra material decoration. Saved and editable blank sheets use the same paper treatment; the doodle and note carry the state.

### Past, empty, read-only
Keep the **same full-size 3:4 blank Daily Sheet** as the editable empty state for now. The app still knows this date is locked and does not offer editing, but the paper itself should not carry tape, seals, warning marks, or a different illustration.

This is intentionally a visual placeholder while the editorial empty-state language is explored. Blank days must remain calm and should not look like an error or a task left undone.

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

Calendar is an accumulation surface for the doodles themselves. Material-state decoration belongs to Card view, not Calendar.

- Keep date numbers visible, but treat them as metadata rather than as a peer to the doodle.
- Saved-day date numbers are smaller and softer; doodles keep the strongest ink weight.
- In the visual area under a date, **saved days show only the doodle thumbnail**.
- Do not show tape, paper, seals, string, or closed-state assets in Calendar.
- Empty today and past blank days leave the doodle area empty.
- Today keeps both a subtle accent background and a stronger date weight; never use a literal `+`.
- Opening a date reveals its paper state in Card view.

This keeps the month composition subordinate to the drawings rather than to decorative paper assets.

## 10. Save / delete confirmation

Save and Delete use the same compact in-app confirmation dialog grammar.

- No toast after Save or Delete.
- Save asks for confirmation before writing the entry.
- Delete asks for confirmation before removing the entry.
- Dialog content is centered, compact, and calm.
- Dialog corner radius is 28.
- Actions occupy opposite sides of one row: `Cancel` on the left and `Okay` on the right.
- After confirmation and completion, return directly to Calendar.
- No system notification permission.

## 11. Asset tone

Material cues should feel physical but not photorealistic:
- warm ivory / cream
- low-contrast shadows
- subtle fibre
- no tape on saved or editable blank sheets
- no tape or seal treatment on blank days for now

Avoid scrapbook decoration for its own sake. Material cues must communicate state.


## 12. Brush experiment — dry crayon / graphite

Current test implementation keeps stroke data as normalized vector-like points and changes only rendering.

- Stroke storage remains unchanged; old entries render with the new brush automatically.
- Rendering uses a translucent centre stroke plus deterministic offset fibres and fine grain.
- Texture is deterministic, so the same saved stroke looks stable across launches.
- The target is dry pencil / graphite / restrained crayon, not waxy children's crayon.
- Calendar thumbnails use the same brush renderer at reduced stroke width.
- This is an experiment to evaluate on-device before locking the brush language.


## 13. Interaction tuning — stroke, dates, delete

- Full-size doodle stroke stays at 3.3; Calendar thumbnail stroke is reduced to 1.08 with lighter ink strength so month view reads more delicately.
- Pointer sampling now reacts from ~0.55 px and interpolates at ~0.78 px steps, making live drawing feel less rigid.
- Rendered strokes use two gentle smoothing passes before quadratic interpolation, preserving gesture character while softening stiff corners.
- Save and Delete both use the shared compact confirmation dialog; toast feedback is removed.
- Calendar date hierarchy is simplified: all past days share one style, today is emphasized mainly through weight, and future dates are muted.
- Any saved entry exposes Delete. Today additionally exposes Edit; past entries remain read-only apart from deletion.
- Delete requires the same confirmation-dialog grammar as Save.
- Deleting today also clears today's draft; deleting a past entry does not touch the current draft.


## 14. Overflow safety

Daily Sheet width is no longer based on screen width alone. It is capped by both:
- horizontal room, and
- the safe vertical height remaining after fixed header / prompt / note / action slots.

A 6 logical-pixel safety margin is reserved for Android fractional-pixel rounding and font metric differences. On normal/tall devices the sheet remains at the 288 px max width; on shorter viewports it shrinks slightly while preserving the 3:4 ratio and shared vertical grammar.


## 15. Calendar completion flow and doodle thumbnails

- Save and Delete both finish by returning to Calendar, reinforcing Calendar as Home.
- There is no completion toast; confirmation happens before the action in the shared compact dialog.
- Calendar thumbnails are content-aware: small doodles are gently enlarged and centered using their actual stroke bounds, capped at about 1.75×.
- Large doodles keep their original paper-relative placement.
- Calendar still shows doodles directly with no paper/card box around them.


## 16. Daily Sheet depth consistency

Daily Sheet shadow is one shared visual token across Card, Drawing, and Compose.

- The shadow must not become stronger when entering Edit.
- Card browsing draws the shadow outside the PageView so PageView clipping cannot trim it.
- Individual pages inside Card browsing render without their own shadow to avoid double depth.
- Drawing and Compose continue to use the same shared shadow wrapper around the sheet.
