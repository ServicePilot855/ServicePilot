---
name: ServicePilot
description: Book a trusted home repair in Phnom Penh as easily as ordering in Grab.
colors:
  pipe-blue: "#1463D8"
  pipe-blue-deep: "#0B2E6B"
  pipe-blue-soft: "#E6EEFB"
  on-pipe-blue-soft: "#0B3A8A"
  tape-yellow: "#FFC42E"
  tape-yellow-soft: "#FFF4D1"
  on-tape-yellow: "#3A2A00"
  tape-yellow-deep: "#6B4E00"
  page: "#F4F6FA"
  surface: "#FFFFFF"
  fill: "#EEF1F6"
  hairline: "#E1E6EE"
  field-border: "#8793A8"
  ink: "#0E1726"
  ink-body: "#2A3547"
  ink-secondary: "#55627A"
  ink-muted: "#8E99AD"
  danger: "#C7352B"
  danger-soft: "#FCEAE8"
  danger-deep: "#9B271F"
  success: "#18794E"
  success-soft: "#E3F5EC"
  success-deep: "#125C3B"
typography:
  display:
    fontFamily: "Figtree, Kantumruy Pro, sans-serif"
    fontSize: "30px"
    fontWeight: 700
    lineHeight: 1.2
    letterSpacing: "-0.015em"
  headline:
    fontFamily: "Figtree, Kantumruy Pro, sans-serif"
    fontSize: "20px"
    fontWeight: 700
    lineHeight: 1.2
  title:
    fontFamily: "Figtree, Kantumruy Pro, sans-serif"
    fontSize: "16.5px"
    fontWeight: 600
    lineHeight: 1.4
  body:
    fontFamily: "Figtree, Kantumruy Pro, sans-serif"
    fontSize: "15.5px"
    fontWeight: 400
    lineHeight: 1.5
  label:
    fontFamily: "Figtree, Kantumruy Pro, sans-serif"
    fontSize: "14px"
    fontWeight: 600
    lineHeight: 1.3
rounded:
  chip: "8px"
  control: "12px"
  card: "16px"
  sheet: "24px"
spacing:
  xs: "4px"
  sm: "8px"
  md: "12px"
  lg: "16px"
  xl: "24px"
  xxl: "32px"
  gutter: "20px"
components:
  button-primary:
    backgroundColor: "{colors.pipe-blue}"
    textColor: "{colors.surface}"
    rounded: "{rounded.control}"
    height: "52px"
  button-primary-disabled:
    backgroundColor: "{colors.fill}"
    textColor: "{colors.ink-muted}"
  button-secondary:
    backgroundColor: "{colors.surface}"
    textColor: "{colors.ink}"
    rounded: "{rounded.control}"
    height: "52px"
  input:
    backgroundColor: "{colors.surface}"
    textColor: "{colors.ink}"
    rounded: "{rounded.control}"
    padding: "15px 14px"
  input-readonly:
    backgroundColor: "{colors.fill}"
    textColor: "{colors.ink-secondary}"
  choice-row:
    backgroundColor: "{colors.surface}"
    textColor: "{colors.ink}"
    rounded: "{rounded.card}"
    padding: "16px"
  choice-row-selected:
    backgroundColor: "{colors.pipe-blue-soft}"
    textColor: "{colors.ink}"
  notice-waiting:
    backgroundColor: "{colors.tape-yellow-soft}"
    textColor: "{colors.ink}"
    rounded: "{rounded.control}"
    padding: "14px"
---

# Design System: ServicePilot

Source of truth in code: `lib/core/theme/app_theme.dart` and `lib/shared/widgets/sp_*.dart`.
Token names map to `AppTheme` constants: `pipe-blue` = `primary`, `tape-yellow` = `accent`, `page` = `background`, `fill` = `surfaceElevated`, `hairline` = `border`, `ink-*` = `text*`.
Research, flows and the sprint plan are in [`docs/UX-PLAN.md`](docs/UX-PLAN.md).

This file describes what is built: the Sprint 1 account screens. Components for later sprints are specified when they are built.

## Overview

**Creative North Star: "Blue Pipe"**

The blue PVC water pipe that runs along every Phnom Penh wall is the most familiar object in home repair here. ServicePilot borrows its colour and its joints. Pipe Blue is the brand and every primary action; a run of pipe with collar joints is the one recurring motif, as the logo and as the step indicator, and later as the booking status line.

Flow and layout start from the Grab app, because that is the ordering pattern the city already knows: white screens, one brand colour used for actions, one decision per screen, the primary action pinned at the bottom. Everything visual is ours. Material 3 governs components, navigation and motion; the brand is themed through it.

The app is a working tool, used in daylight on mid-range Android phones by someone whose tap is leaking now. It is light, flat and plain. Colour appears only where it does a job.

**Key Characteristics:**
- White form pages, a cool pale page tone for browse screens; never a dark canvas.
- One filled blue button per screen, pinned to the bottom in flows.
- Tape Yellow means "waiting" and nothing else.
- Flat forms: labels above fields, no boxes around groups, a visible field edge.
- One clean type family, with Khmer handled by an automatic fallback.

## Colors

One saturated blue on white and cool greys, with a single yellow signal.

### Primary
- **Pipe Blue** (`pipe-blue`): primary buttons, links, focus borders, selected radios and checkboxes, reached joints, the splash background. White on it measures 5.5:1.
- **Pipe Blue Deep** (`pipe-blue-deep`): tint for the float shadow; reserved for dark brand bands later.
- **Pipe Blue Soft** (`pipe-blue-soft`): selected choice rows and brand notices. Text and icons on it use `on-pipe-blue-soft` (9.1:1).

### Secondary
- **Tape Yellow** (`tape-yellow`): the dot in the current joint and in the logo. A fill or a mark only; never text (1.6:1 on white).
- **Tape Yellow Soft** (`tape-yellow-soft`): background of "waiting" notices.
- **Tape Yellow Deep** (`tape-yellow-deep`): icons and text on Tape Yellow Soft (7.0:1).
- **On Tape Yellow** (`on-tape-yellow`): text on a solid yellow fill (8.7:1).

### Neutral
- **Surface** (`surface`): form pages, cards, sheets, inputs.
- **Page** (`page`): background of home and browse screens.
- **Fill** (`fill`): read-only fields, neutral tags, disabled buttons.
- **Hairline** (`hairline`): 1px dividers and the top edge of the pinned action bar. Decorative; too faint to mark a control.
- **Field Border** (`field-border`): the edge of inputs, outlined buttons and unselected radios (3.1:1 on white).
- **Ink** (`ink`): headings, labels, entered text (18:1).
- **Ink Body** (`ink-body`): paragraphs.
- **Ink Secondary** (`ink-secondary`): subtitles, helper text, placeholders, flow titles (6.2:1).
- **Ink Muted** (`ink-muted`): disabled text only (2.9:1). Never carries information.

### Status
- **Danger / Soft / Deep**: field errors use Danger (5.3:1 on white); error snackbars and text on Danger Soft use Danger Deep (6.7:1).
- **Success / Soft / Deep**: confirmations; text and icons on Success Soft use Success Deep (7.1:1).

### Named Rules
**The Waiting Rule.** Tape Yellow appears only when something is pending: an account awaiting verification, the current step, later a booking awaiting the provider. If nothing is waiting, the only yellow on screen is the logo's joint.

**The One Fill Rule.** One filled Pipe Blue button per screen. Alternatives are outlined or text.

**The Not Colour Alone Rule.** Every status pairs its colour with an icon and words. The password strength meter states its level in text under the bar.

## Typography

**Font:** Figtree for all Latin text.
**Khmer fallback:** Kantumruy Pro, applied automatically to any Khmer characters.

**Character:** one friendly, rounded, clean family. Headings differ from body by weight and size only. Figtree is narrower than most UI sans faces, so provider names, areas and prices fit on one line more often on a 360dp phone. Its round geometric shapes match Kantumruy Pro, so mixed Khmer and English lines read as one voice. Chosen by the team on 13 Nov 2026 from a six-font comparison (Figtree, Onest, Manrope, Bricolage Grotesque, Gabarito, Inter).

### Hierarchy
- **Display** (700, 30px, 1.2, tracking -0.015em): the one heading on each screen (`SpPageHeader`); 40px for the name on the splash.
- **Headline** (700, 20px): section headings inside a form (`SpFormSection`); 28px in result and dead-end states (`SpStatusHero`).
- **Title** (600, 16.5px): choice-row titles; button labels at 16px.
- **Body** (400, 15.5px, 1.5): subtitles and messages; 14px in notices and choice-row descriptions.
- **Label** (600, 14px): field labels; 15px in the top bar for the flow title, in Ink Secondary.
- **Caption** (400 to 600, 13px): helper text, step count, footnotes.

### Named Rules
**The Role Rule.** Sizes come from `AppTheme.display()` / `AppTheme.text()` at the steps above or from the theme's text roles. No other sizes, and no direct font calls, in feature code.

**The Khmer Room Rule.** No layout depends on an English string length: titles wrap, buttons ellipsise, nothing sits in a fixed-height box. Khmer needs more height than Latin, so leave line height at 1.5 or more wherever text can wrap.

**The Weight Floor Rule.** Nothing lighter than 400 below 18px.

**The No Literals Rule.** Every string a person can read comes from `context.l10n` (`lib/l10n/app_en.arb`). Sentences with a variable use a placeholder, never string concatenation, because word order changes in Khmer.

## Layout

A single column on a 4dp grid with steps of 4, 8, 12, 16, 24 and 32.

- **Gutter:** 20dp on form and flow pages. Content is capped at 480dp and centred on wider screens.
- **Flow page** (`SpFlowPage`): a 48dp top bar with the back arrow, a small flow title and the joint steps; scrolling content; the primary action pinned at the bottom on a Surface strip with a Hairline top edge, above the keyboard and inside the safe area.
- **Entry page** (log in): no back arrow; wordmark, heading, form, then alternatives in descending importance.
- **Rhythm:** 6dp from a label to its field, 16dp between fields, 32dp between sections, 24dp from the page header to the first block. Space between groups is at least twice the space within one.
- **Touch:** every target is at least 48dp, including the back arrow, the password eye, text links and the remember-me row.
- **Back:** the system Back gesture always works; when there is nothing to pop, Back goes to the screen the flow came from.

## Elevation & Depth

Flat. Depth comes from the page tone against white and from 1px edges. Nothing that scrolls with the page has a shadow.

### Shadow Vocabulary
- **Float** (`0 6px 20px` Pipe Blue Deep at 10%; `AppTheme.floatShadow`): reserved for elements that stay put while content scrolls under them (the cart bar in a later sprint). Not used in Sprint 1.

### Named Rules
**The Flat Rule.** No gradients, glows, glass or blur. A coloured area is one flat fill.

## Shapes

Medium rounding that grows with the object: tags 8dp, buttons and inputs 12dp, cards and choice rows 16dp, sheets 24dp on the top corners. Radios, joints and avatars are round. Edges are 1px; selection and focus thicken to 2px in Pipe Blue. Icons are Material Symbols, rounded or outlined, 20dp inside fields and 24dp elsewhere; no emoji, no second icon set. The Google "G" is the only mark that carries its own colour.

## Components

Plain and dependable: large targets, labels that say what happens, obvious state.

### Buttons
- **Primary** (`SpPrimaryButton`): Pipe Blue fill, white 16px label, 52dp tall, 12dp corners, full width. While loading it shows a white spinner and keeps its size and colour. Disabled is Fill with Ink Muted text.
- **Secondary** (`SpSecondaryButton`): Surface with a Field Border edge and Ink label; optional leading icon. Destructive actions use the same shape with Danger Deep text.
- **Google** (`SpGoogleButton`): secondary button with the blue "G".
- **Text** (`SpTextButton`): Pipe Blue 15px label with a 48dp target, for "Forgot password?" and footer links.
- **Back** (`SpBackButton`): a bare 24dp arrow in a 48dp target with a "Back" tooltip.

### Inputs / Fields
- **Style** (`SpTextField`, `SpPasswordField`): label above; white field with a Field Border edge, 12dp corners; a 20dp leading icon that names the field type; placeholder in Ink Secondary showing an example value.
- **Focus:** the edge becomes 2px Pipe Blue and the leading icon turns blue.
- **Error:** the edge turns Danger and a 13px message under the field says what to fix, up to three lines.
- **Read-only:** Fill background with Ink Secondary text (the invited email on activation).
- **Password:** a show/hide eye with its own 48dp target and tooltip; paste is never blocked.

### Choice row
`SpChoiceRow`: a full-width row with an icon, a title, one line of description and a radio at the trailing edge. Selected: Pipe Blue Soft fill, 2px Pipe Blue edge, blue icon and filled radio. The pinned button names the selection ("Continue as homeowner").

### Joint steps (signature)
`SpJointSteps`: a run of pipe with a round collar joint per step. Reached joints and the pipe between them are Pipe Blue; the current joint carries a Tape Yellow dot; joints ahead are white with a Field Border ring. Joints are 14dp joined by 18dp of pipe so three steps fit beside a flow title. A count ("2 of 3") follows in words, and the whole run is announced as "Step 2 of 3".

### Sign-up flow
`RegistrationFlow` (`lib/features/auth/widgets/registration_flow.dart`) holds every sign-up: the role choice is step 1, details step 2, password step 3. The details page carries only the person's or company's details and a pinned "Continue". The password page names the email being registered, shows any verification notice, and lists its rules as a live checklist: a hollow ring that becomes a green tick (`check_circle`) with the label darkening from Ink Secondary to Ink. Back, on screen or from the system, returns from the password page to the details with every value kept.

### Notices and results
- **Notice** (`SpNotice`): a tinted block with a 20dp icon and 14px Ink text, in five tones (`SpTone`). The waiting tone is the only yellow surface in the app.
- **Status hero** (`SpStatusHero`): a 56dp tinted icon tile, a heading and a message, left-aligned. Used for sent, invalid-link and success states.
- **Result sheet** (`showSpResultSheet`): a bottom sheet holding a status hero and one primary button; it closes only through that button.
- **Error snackbar** (`showSpError`): floating, Danger Deep, icon plus message.

### Section and header
- **Page header** (`SpPageHeader`): the screen's one Display heading with an optional subtitle.
- **Form section** (`SpFormSection`): a Headline over a flat group of fields. No box.
- **Or divider** (`SpOrDivider`) and **footer link** (`SpFooterLink`): for alternatives below the primary path.

### Brand
`SpLogoMark`: a rounded Pipe Blue tile with a house drawn as one white run of pipe and a Tape Yellow joint at the ridge; inverted (white tile, blue pipe) on the splash. `SpWordmark` sets it beside the name.

### Motion
State changes only, 150 to 250ms: the joint filling, a field focusing, the splash fading in (350ms, once). No entrance choreography, no looping motion.

## Do's and Don'ts

### Do:
- **Do** take every colour, size and radius from `AppTheme` and the `Sp*` widgets; extend those files before styling a one-off.
- **Do** give each screen one job, one Display heading and one filled button.
- **Do** put labels above fields and show an example in the placeholder.
- **Do** write errors that say what is wrong and what to do.
- **Do** keep targets at 48dp and test at 130% font scale on a 360dp-wide phone.
- **Do** use Tape Yellow for waiting states with an icon and a sentence.

### Don't:
- **Don't** bring back a dark canvas, an orange accent, gradients, glows or blur.
- **Don't** box field groups in cards, or nest a card inside a card.
- **Don't** put a small uppercase label above a heading, or decorate with icons in coloured circles.
- **Don't** use Tape Yellow or Ink Muted for text that must be read.
- **Don't** call `GoogleFonts`, write hex colours, or hard-code readable text in feature code.
- **Don't** reuse Grab's or Orkun's colours, logos, illustrations, product names or copy.
- **Don't** imply features that are out of scope: no payment form, live map, in-app chat or auto-assign control.
