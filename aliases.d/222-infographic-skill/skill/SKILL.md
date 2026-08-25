---
name: infographic
description: Use this skill whenever the user asks for an infographic, a one-pager, a visual summary, an explainer graphic, a stat sheet, a process/timeline poster, an "at a glance" visual, or a social-share graphic built around numbers or a short narrative. Also trigger it when the user asks to "make this data pop visually", "turn this report into something visual", or "make a poster/graphic out of these stats" - even if they never say the word "infographic". Make sure to use this skill instead of jumping straight to a generic chart or a plain slide whenever the deliverable is a single (or few-page) shareable visual document meant to communicate one idea fast, not an interactive dashboard or a raw data chart.
---

# Infographic

An infographic is not a chart with decoration around it. It is **one idea, told visually, in the order a reader's eye naturally moves.** If you cannot state the one takeaway in a single sentence before you start designing, stop and ask for it - everything else in this skill assumes you already have it.

This skill covers *composition and narrative* (layout archetypes, hierarchy, the anti-patterns that make AI-made infographics look cheap). For chart mechanics, color math, and mark specs, load the `dataviz` skill - this skill's color and chart rules extend it, not replace it. For general canvas/artboard mechanics when publishing as an Artifact, load `artifact-design`.

## Step 1 - Nail the one-sentence takeaway

Before touching layout, write down:
- **The headline claim**: the one fact/number/idea the reader should remember even if they only glance at it for 3 seconds.
- **3-6 supporting points**: each one a single stat, step, or fact - not a paragraph.
- **The source/context line**: where the data comes from, or the date/scope it covers. Infographics without a source line read as untrustworthy.

If the user's input doesn't cleanly reduce to this, ask them which single point matters most rather than guessing - a good infographic makes an editorial choice about what's important, it doesn't present everything with equal weight.

## Step 2 - Pick a layout archetype

Match the content shape to one of these, don't invent a new structure per project:

1. **Stat-led** - one huge number/headline stat dominates the top third, 3-5 smaller supporting stats fill the rest. Best for "here's the state of X."
2. **Timeline / process** - a single horizontal or vertical spine with 4-8 nodes, each a step or era. Best for "here's how X happened" or "here's how X works."
3. **Comparison** - two or three columns/tracks (before/after, A vs B vs C) with matched row-by-row stats. Best for "X vs Y."
4. **Anatomy / breakdown** - one central image/diagram with callout labels radiating out. Best for "here's what's inside/what makes up X."
5. **List / ranked** - a numbered or ranked sequence of items, each with an icon + short label + one stat. Best for "top N things about X."

Pick exactly one. Mixing archetypes (a timeline that also tries to be a comparison) is the fastest way to lose the reader.

## Step 3 - Build the hierarchy with scale, not color

Establish 3 tiers and stick to them for the whole piece:
- **Tier 1** (the headline stat/claim): largest type on the page, one per infographic.
- **Tier 2** (section headers, supporting stats): roughly half the size of Tier 1, used for the 3-6 supporting points.
- **Tier 3** (body copy, captions, source line): smallest, used sparingly - infographics are not essays. If a Tier 3 block runs past ~2 short sentences, cut it.

A reader should be able to squint at the page and still see which number matters most purely from size, before reading a single word.

## Step 4 - Color and type (extends `dataviz`)

- Reuse the palette approach and validator from `dataviz` - do not invent a new palette per infographic. Cap it at 1 dominant accent + 1 secondary accent + neutrals; reserve a color for "this is the headline stat" and use it nowhere else on the page, so it keeps its signal value.
- One typeface family for the whole piece (a display cut of it for Tier 1 is fine; a second family is not). Infographics that mix 3+ fonts read as a ransom note, not a document.
- Numerals get their own visual treatment (bold/tabular figures) so stats are scannable independent of the surrounding sentence.

## Step 5 - Build it

Default to a **single self-contained HTML file with inline SVG** for the actual artwork - it is inspectable, scales losslessly, and every client (Claude Code, Codex, Antigravity) can write and open a file, so this is the portable default regardless of which agent is running this skill.

- If running inside Claude Code and the user wants a shareable link: load `artifact-design`, then publish the finished HTML with the `Artifact` tool. Follow that skill's theme-aware CSS and responsive rules - an infographic that breaks in dark mode or overflows on mobile is not finished.
- If the user needs a **static image** (PNG/PDF) to paste elsewhere: render the HTML file with the Playwright MCP tools if available in this session (`browser_navigate` to the local file, then `browser_take_screenshot`, or `browser_pdf_save`-equivalent) instead of hand-building the raster asset another way.
- If the user needs an **editable slide-deck-style** infographic (single branded slide, not a webpage): use PptxGenJS (`require('pptxgenjs')`) instead of HTML - build the same hierarchy/layout archetype using slide shapes, text boxes, and native PowerPoint charts rather than raster images, so the client can still edit it afterward.
- If asked for a print piece (poster/flyer) rather than a web-shareable graphic, prefer the `design` skill's canvas flow instead - that skill is tuned for print-oriented single-artboard output.

Never ship a wall of default `<div>` boxes with drop shadows and a gradient background as a stand-in for real icons and layout - see the anti-pattern list below.

## Step 6 - Self-critique before delivering

Walk the finished piece against this checklist. Fix anything that fails before showing it to the user:

- [ ] Could a reader state the headline takeaway after 3 seconds, without reading any Tier 3 text?
- [ ] Is there exactly one Tier-1-sized element? (Two "biggest things" means no hierarchy.)
- [ ] Does every icon on the page share the same style - same stroke weight, same fill-vs-outline choice, same corner radius? Mixed icon packs are the single most common tell of a rushed infographic.
- [ ] Is the accent color used for the headline stat used *nowhere else*?
- [ ] Does everything sit on a consistent grid/margin - or are elements floating at slightly different insets "because it looked fine"?
- [ ] Is there a source/date line?
- [ ] Would this survive being resized to a phone-width share image without text overlapping?

## Anti-patterns (why AI-made infographics usually look cheap)

- **Decoration standing in for information**: glossy 3D icons, drop shadows on every box, gratuitous gradients. None of these carry meaning - they're filler because real icons/illustration felt like more work. If you don't have a real icon, use a simple geometric shape or a single-color line glyph, not a decorative placeholder.
- **Equal-weight everything**: seven stats all rendered at the same size in the same box style is a list, not an infographic. Force a hierarchy even if the input data doesn't obviously have one - that editorial choice is the job.
- **Icon soup**: pulling icons from three different styles/weights because each one "matched the topic" individually. Pick one icon system and if a concept doesn't have a clean icon in it, use text or a simple shape instead of breaking consistency.
- **Caption-as-paragraph**: a Tier 3 caption that's actually four sentences. If it needs that much explanation, it's supporting content for a report, not for an infographic - cut it or move it to a footnote.
- **No takeaway**: a page that accurately displays the data but doesn't argue for anything. Infographics are persuasive/explanatory by nature; if every stat has equal billing, the reader leaves without a point.
