# Implementation Plan: Premium Shopping Cart UI

**Branch**: `002-premium-cart-ui` | **Date**: 2026-04-03 | **Spec**: [spec.md](file:///c:/Users/admin/Desktop/Al%20Mossad%20Store/.specify/features/002-premium-cart-ui/spec.md)
**Input**: Feature specification from `.specify/features/002-premium-cart-ui/spec.md`

## Summary
The goal is to elevate the shopping cart UI to "Premium" status using modern design tokens (Glassmorphism, Cairo font, high-end animations). We will also fix the underlying database recursion error to ensure a smooth, stable experience.

## Technical Context

**Language/Version**: Javascript/React (Vite)
**Primary Dependencies**: Framer Motion, Tailwind CSS, Lucide React, Supabase
**Storage**: Supabase / PostgreSQL
**Testing**: Manual Visual Testing + Browser Subagent
**Target Platform**: Web (Mobile/Desktop)
**Project Type**: Web Application
**Performance Goals**: 60fps animations, smooth backdrop-blur navigation
**Constraints**: RTL compliance (Arabic), Premium Glassmorphism aesthetic
**Scale/Scope**: Single feature (Cart Drawer)

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

- [x] TDD: Visual components will be built and verified incrementally.
- [x] Simplicity: Avoid over-engineering; use Tailwind utilities where possible.
- [x] RTL First: All layouts must be verified for Correct Arabic alignment.

## Project Structure

### Documentation (this feature)

```text
.specify/features/002-premium-cart-ui/
├── plan.md              # This file
├── research.md          # Phase 0 output
├── data-model.md        # Phase 1 output (reusing 001)
├── quickstart.md        # Phase 1 output
├── contracts/           # Phase 1 output
│   └── ui-contract.md   # Prop definitions for Cart components
└── tasks.md             # Phase 2 output (future)
```

### Source Code (repository root)

```text
src/
├── components/
│   └── Cart/
│       └── CartDrawer.jsx (MODIFY)
├── context/
│   └── CartContext.jsx (REFINEMENT)
```

## Phase 0: Outline & Research (Goal: solve UI/UX unknowns)

1. **Research RTL Spring Animations**: Determine the best `x` coordinate logic in Framer Motion for RTL layouts (Right side entry).
2. **Research Backdrop-Blur Performance**: Evaluate `backdrop-filter` impact on low-end mobile devices and document the "Safe Fallback" strategy.
3. **Consolidate findings** in `research.md`.

## Phase 1: Design & Contracts

1. **Interface Contract**: Document the `CartDrawer` props and the `CartContext` API to ensure decoupled development.
2. **Update Agent Context**: Run script to include new design tokens.

## Phase 2: Implementation (Summary level)

1. **Database**: Fix RLS recursion in `profiles` table.
2. **Foundation**: Update `CartContext` with any missing hydration logic.
3. **UI Implementation**: Complete the visual redesign of `CartDrawer.jsx`.
4. **Validation**: Comprehensive cross-browser check for the "WOW" factor.

## Open Questions

- [x] **Mobile Performance**: We will start with standard and add a fallback.
