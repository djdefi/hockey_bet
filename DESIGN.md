---
name: NHL Fan League
description: Broadcast Viewfinder — a dark viewing field, white readouts, and amber focus.
colors:
  accent-primary: "#ffbc52"
  focus: "#ffbc52"
  accent-positive: "#35d07f"
  accent-danger: "#ff5347"
  accent-warning: "#ffb020"
  accent-info: "#87b6e5"
  accent-orange: "#ff7a2f"
  bg-primary: "#101214"
  bg-depth: "#090b0c"
  bg-secondary: "#171a1d"
  bg-tertiary: "#22262a"
  bg-hover: "#292e33"
  text-primary: "#f4f5f6"
  text-secondary: "#b2b8bf"
  text-muted: "#949ca5"
  text-inverse: "#101214"
  border-default: "#363c42"
  border-subtle: "#282d32"
  border-strong: "#737d87"
typography:
  headline:
    fontFamily: "-apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Helvetica, Arial, sans-serif"
    fontSize: "1.75rem"
    fontWeight: 650
    lineHeight: 1.25
    letterSpacing: "-0.025em"
  title:
    fontFamily: "-apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Helvetica, Arial, sans-serif"
    fontSize: "1.0625rem"
    fontWeight: 650
    lineHeight: 1.25
  body:
    fontFamily: "-apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Helvetica, Arial, sans-serif"
    fontSize: "0.9375rem"
    fontWeight: 400
    lineHeight: 1.5
  label:
    fontFamily: "-apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Helvetica, Arial, sans-serif"
    fontSize: "0.75rem"
  readout:
    fontFamily: "'SF Mono', Monaco, 'Cascadia Code', 'Roboto Mono', Consolas, 'Courier New', monospace"
    fontSize: "0.9375rem"
    fontWeight: 400
    fontFeature: '"tnum"'
rounded:
  square: "0"
  sm: "2px"
  lg: "4px"
spacing:
  space-1: "0.25rem"
  space-2: "0.5rem"
  space-3: "0.75rem"
  space-4: "1rem"
  space-5: "1.25rem"
  space-6: "1.5rem"
  space-7: "1.75rem"
  space-8: "2rem"
  space-10: "2.5rem"
  space-12: "3rem"
components:
  button-primary:
    backgroundColor: "{colors.focus}"
    textColor: "{colors.text-inverse}"
    rounded: "{rounded.sm}"
    padding: "10px 16px"
  button-primary-hover:
    backgroundColor: "color-mix(in srgb, var(--color-focus) 85%, white)"
    textColor: "{colors.text-inverse}"
  button-secondary:
    backgroundColor: "{colors.bg-tertiary}"
    textColor: "{colors.text-primary}"
    rounded: "{rounded.sm}"
    padding: "10px 16px"
  button-secondary-hover:
    backgroundColor: "{colors.bg-hover}"
    textColor: "{colors.text-primary}"
  button-team-theme:
    backgroundColor: "transparent"
    textColor: "{colors.text-secondary}"
    rounded: "{rounded.sm}"
    padding: "10px 12px"
  button-team-theme-hover:
    backgroundColor: "{colors.bg-hover}"
    textColor: "{colors.focus}"
  button-reset:
    backgroundColor: "{colors.bg-tertiary}"
    textColor: "{colors.text-secondary}"
    rounded: "{rounded.sm}"
    padding: "6px 12px"
  button-help:
    backgroundColor: "{colors.bg-secondary}"
    textColor: "{colors.text-secondary}"
    rounded: "{rounded.sm}"
    width: "44px"
    height: "44px"
  button-close:
    backgroundColor: "transparent"
    textColor: "{colors.text-secondary}"
    rounded: "{rounded.sm}"
    padding: "4px"
  input-season:
    backgroundColor: "{colors.bg-secondary}"
    textColor: "{colors.text-primary}"
    rounded: "{rounded.sm}"
    padding: "8px 32px 8px 12px"
  navigation-tab:
    backgroundColor: "transparent"
    textColor: "{colors.text-secondary}"
    rounded: "{rounded.square}"
    padding: "10px 20px"
  navigation-tab-active:
    backgroundColor: "{colors.bg-secondary}"
    textColor: "{colors.focus}"
  status-tag:
    backgroundColor: "transparent"
    textColor: "{colors.text-primary}"
    rounded: "{rounded.square}"
    padding: "2px 5px"
  status-tag-eliminated:
    textColor: "{colors.accent-danger}"
  card-field:
    backgroundColor: "{colors.bg-depth}"
    textColor: "{colors.text-primary}"
    rounded: "{rounded.square}"
    padding: "24px"
---

# Design System: NHL Fan League

## Overview

**Creative North Star: "Broadcast Viewfinder"**

A quiet, dark viewing field gives names and white readouts the foreground. Fine rules and corner brackets organize attention without decorative glow or a wall of elevated cards. The character is precise, compact, and clean.

The neutral palette is the default, not a replacement for team identity. Existing team themes remain available; independent amber focus cues keep controls recognizable. This records the built [tokens](lib/design-tokens.css), [main interface](lib/styles.css), [playoff interface](lib/playoff_styles.css), and their ERB/JavaScript controls. [PRODUCT.md](PRODUCT.md) owns product constraints; route strategy lives in the surface brief.

**Key Characteristics:**
- Dark tonal fields with white and gray readouts.
- Independent amber focus; team identity remains customizable.
- System sans names paired with tabular monospaced measurements.
- Hairline structure, corner brackets, and restrained state transitions.

## Colors

The palette is neutral charcoal with warm focus, not an amber wash over every surface.

### Primary
- **Focus Amber** (`focus`): selection brackets, keyboard outlines, emphasized odds, and progress marks.
- **Team Accent** (`accent-primary`): the thin application accent strip and theme-dependent accents; its default matches Focus Amber, but its ownership does not.

### Secondary
- **Positive Green / Loss Red** (`accent-positive`, `accent-danger`): gains, winning records, advancement, losses, and elimination.
- **Caution Amber / Hot Orange** (`accent-warning`, `accent-orange`): uncertain playoff status, tied series, and rivalry emphasis.
- **Comparison Blue** (`accent-info`): opposing-team measurements and supporting data color. Team themes may replace it. Chart series retain their existing categorical palettes.

### Neutral
- **Viewing Field / Inset Black** (`bg-primary`, `bg-depth`): page canvas and framed data surfaces.
- **Panel / Inset Control / Hover** (`bg-secondary`, `bg-tertiary`, `bg-hover`): active rows, controls, dialogs, and interaction states.
- **Readout White / Supporting Gray / Quiet Gray** (`text-primary`, `text-secondary`, `text-muted`): identity, explanation, and secondary labels. `text-inverse` supplies dark text on amber.
- **Rule / Quiet Rule / Control Edge** (`border-default`, `border-subtle`, `border-strong`): section boundaries, row dividers, and stronger control outlines.

### Named Rules
**The Stable Focus Rule.** Team themes may recolor surfaces and accents; selection brackets and keyboard focus retain the independent `--color-focus` token.

## Typography

**Display Font:** the system sans stack, also used for names and headings.

**Body Font:** the same system sans stack.

**Label/Mono Font:** the SF Mono-led fallback stack for dedicated numeric readouts; ordinary labels remain sans.

**Character:** Familiar, compact text carries the interface; monospaced figures make comparisons easy. Feature names can grow without turning every heading into display typography.

### Hierarchy
- **Headline:** the frontmatter role describes main view headings; these reduce to (1.5rem) below the main mobile breakpoint.
- **Title:** compact section/chart headings; repeated name labels commonly use (600) weight.
- **Body:** the main shell baseline; supporting interface copy commonly steps down to (0.875rem) or (0.8125rem).
- **Label:** metadata and captions; smaller route-local mobile chart/navigation labels are not a system-wide minimum.
- **Readout:** tabular scores and ranks, enlarged locally for points and playoff series wins. The oversized leader name and playoff title are component treatments, not extra global tokens.

### Named Rules
**The Two Voices Rule.** Use system sans for names and controls, and tabular monospace for dedicated score, rank, and odds readouts.

## Layout

- The shared container caps at (1360px). Main horizontal gutters step from (40px) to (28px) at (1100px), (20px) at (767px), and (14px) at (359px). Spacing follows the reused quarter-rem steps above, with local optical adjustments.
- Open rows and section rules do most grouping. Repeated comparison/chart fields use square bordered containers; multi-column details collapse rather than squeeze their contents.
- Desktop view navigation becomes a fixed bottom rail at (767px). Main content reserves (100px + bottom safe-area inset); the rail also pads for that inset.
- Main comparison layouts stack on mobile; detail grids reduce from four columns to two. The playoff round grid changes from four columns to two at (1100px), then one at (720px), with sticky round headings.
- Theme choices use two columns, expanding to four from (520px). Dialog content scrolls within viewport bounds. Empty-state explanation stays near (48ch); names wrap rather than being truncated.

## Elevation & Depth

The shell is flat: solid tonal fields and thin borders provide depth. Dialogs are the exception, separated by a dark scrim and broad shadow. The inherited token file contains more shadow names than the redesigned shell uses; they are not a card-elevation ladder.

### Shadow Vocabulary
- **Team picker:** (`0 24px 48px rgba(0,0,0,0.4)`) under the theme dialog.
- **Keyboard help:** (`0 20px 60px rgba(0,0,0,0.5)`) under the shortcuts dialog.
- Both dialog backdrops use (`rgba(0, 0, 0, 0.8)`).

### Named Rules
**The Flat Field Rule.** Structural panels stay flat and hairline-bordered; shadows separate dialogs, not ranked teams or ordinary cards.

## Shapes

Square fields and diagonal corner pairs are the signature. Small control rounding uses `rounded.sm`; keycaps and the playoff empty-state exception use `rounded.lg`. Team-selection dots and swatches retain their circular/pill geometry: this is not a ban on circles.

Active navigation brackets and expanded rows share the focus vocabulary. Row brackets move inward on expansion (180ms ease-out); ordinary color/background transitions stay around (150–200ms). Reduced-motion preferences suppress CSS motion, and both charts disable their animation.

## Components

### Buttons
Quiet, bounded controls rather than oversized calls to action. The playoff return actions show both amber-filled primary and tonal secondary variants. Team-theme controls have a strong hairline edge and small corners; hover/focus changes their edge and text to amber. Reset uses a tonal fill; the dialog close control is transparent. Touch targets are at least (44px) in the sampled button/select controls; disabled buttons fade to (0.55) opacity.

The help control is a labeled square button in the masthead, not a floating overlay. Its script shows it when initialized above (768px); keyboard help remains available through its shortcuts. Theme selection retains its dialog, Escape dismissal, focus trap, focus restoration, and saved preference.

### Chips
Small rectangular status tags and achievement badges pair text with status color. Playoff tags are unrounded and hairline-bordered; advanced/alive states use green, eliminated states red, and champions amber. Achievement badges may retain their existing data-provided background.

### Cards / Containers
Comparison and chart fields use `card-field`, with no shadow. Mobile comparison padding reduces to (20px); charts use (20px 14px). Standings remain expandable rows, not a new card grid; expanded rows receive a tonal background, amber corners, and a separated detail area.

### Inputs / Fields
The native season selector keeps its label, strong border, small corners, and (1rem) text. It remains mounted with the chart during empty-history states. No general text-input system is implied by this selector.

### Navigation
Text-first desktop buttons have a neutral hover field; the current view adds amber text and corner brackets. Mobile buttons retain labels and current-view cues. Preserve the existing navigation semantics and keyboard access.

### Readouts and Feedback
Probabilities name the fan whose chance is shown; upcoming matchup cards carry their schedule. Missing last-ten records say they are unavailable. Trend rendering distinguishes zero points from missing values, requires a second history snapshot, and exposes empty/error text through a status region. Chart.js retains its local Inter-first fallback stack and categorical colors; neither becomes the global typography or accent contract.

Focus is amber throughout, not one uniform outline thickness: the base CSS uses (2px / 4px offset), the main accessibility enhancement uses (3px / 2px offset), and theme controls use (2px / 3px offset). Component-specific focus rules remain authoritative.

## Do's and Don'ts

### Do:
- **Do** preserve independent amber focus when applying team themes.
- **Do** pair status color with readable labels and tabular numeric readouts.
- **Do** keep mobile content clear of the bottom rail and masthead controls clear of the data field.
- **Do** retain native controls, keyboard access, reduced-motion support, and honest empty/error states.

### Don't:
- **Don't** add decorative glow or turn ordinary data rows into elevated cards.
- **Don't** replace missing records with zeroes, fabricated results, or unlabeled probabilities.
- **Don't** turn retained chart-only fonts, legacy aliases, or one-off dimensions into global defaults.
