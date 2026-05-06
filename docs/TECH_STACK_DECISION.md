# Tech Stack Decision

## Decision Summary

Recommended primary stack for Appiombi:

- Flutter native
- Supabase
- GitHub-based code workflow
- Codex-driven implementation

Recommended secondary role for FlutterFlow:

- optional prototype tool
- optional exploratory UI helper
- not the primary implementation environment

## Why This Decision Matters

Appiombi is not a simple connected CRUD app.
Its real requirements include:

- native Android/iOS delivery
- mobile-first workflows
- offline-first session handling
- future local database
- conflict-aware sync
- custom podal map behavior
- precise role and RLS-aware data flows
- direct implementation through repository code

The goal is also to minimize manual work in visual editors and maximize what Codex can implement directly in the codebase.

## Option A: FlutterFlow + Custom Code

### Pros

- fast visual prototyping
- quick setup for simple auth and CRUD screens
- easy first-pass layout building
- approachable for non-developer editing

### Cons

- visual-editor work is still manual and difficult to scale through code review
- generated structure is less ideal for a code-first agent workflow
- complex offline-first architecture does not fit naturally
- custom sync engine becomes an external layer anyway
- custom podal map and advanced navigation/state handling become more cumbersome
- repository-driven incremental refactors are less clean than pure Flutter
- theme, reusable components, and design system consistency are harder to evolve purely by code

## Option B: Pure Flutter Native + Supabase

### Pros

- fully code-driven development
- much better fit for Codex and GitHub workflow
- easier to version, review, refactor, and compose
- clean support for custom UI components
- clean support for future offline engine
- clean support for local persistence layer
- clean support for custom podal map
- stronger control over navigation, state, theme, and native UX
- no dependence on visual editor operations for core product delivery

### Cons

- slightly slower than FlutterFlow for superficial first mock screens
- requires more up-front app structure decisions
- demands stronger engineering discipline from the start

## Evaluation By Requirement

## 1. Offline Sync

FlutterFlow:

- weak fit as primary implementation environment
- real sync engine still requires custom Dart architecture
- local persistence and retry orchestration quickly outgrow the visual builder

Pure Flutter:

- strong fit
- easier to implement repositories, queues, local DB, retry logic, and conflict handling

Recommendation:

- prefer pure Flutter

## 2. Podal Map Customization

FlutterFlow:

- possible only with custom widgets and growing escape hatches
- weak for iterative custom geometry and interaction work

Pure Flutter:

- strong fit for custom painter, gesture logic, overlays, hit areas, and future advanced map logic

Recommendation:

- prefer pure Flutter

## 3. UI And Brand Direction

FlutterFlow:

- acceptable for simple screens
- weaker for evolving a coherent product design system over time entirely by code

Pure Flutter:

- stronger control over theme tokens, spacing, typography, reusable widgets, and product identity

Recommendation:

- prefer pure Flutter

## 4. User Manual Work

FlutterFlow:

- still requires repeated manual editing in the visual builder
- harder to let Codex own implementation end-to-end

Pure Flutter:

- far less editor clicking
- changes can be requested and implemented directly in repository code

Recommendation:

- prefer pure Flutter

## 5. Codex-Driven Development

FlutterFlow:

- limited because significant work remains visual/manual
- code generation and structure are not the cleanest target for repeated AI-driven iteration

Pure Flutter:

- strongest fit
- Codex can implement screens, navigation, theme, components, queries, and integration logic directly in versioned source

Recommendation:

- strongly prefer pure Flutter

## Strategic Recommendation

For Appiombi, Flutter pure native is the technically coherent primary stack.

Recommended positioning:

- primary stack: Flutter native + Supabase + GitHub + Codex
- secondary option: FlutterFlow only for prototype experimentation if ever useful

Do not rely on FlutterFlow as the core delivery path for the production MVP.

## Practical Consequence

From this point forward, architecture and planning should assume:

- repository-first implementation
- native Flutter code as source of truth
- custom design system in code
- custom local persistence layer
- custom sync orchestration

FlutterFlow documents may remain as reference material, but should be treated as secondary or prototype-oriented guidance.
