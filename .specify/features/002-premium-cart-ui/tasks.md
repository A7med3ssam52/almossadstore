# Tasks: Premium Shopping Cart UI

**Feature Branch**: `002-premium-cart-ui`  
**Plan**: [plan.md](file:///c:/Users/admin/Desktop/Al%20Mossad%20Store/.specify/features/002-premium-cart-ui/plan.md)  
**Spec**: [spec.md](file:///c:/Users/admin/Desktop/Al%20Mossad%20Store/.specify/features/002-premium-cart-ui/spec.md)

## Summary
Implementation of a professional, high-end shopping cart. This involves fixing critical RLS recursion issues followed by a complete visual overhaul of the Cart Drawer.

## Phase 1: Setup & Critical Fixes
- [ ] T001 Fix RLS recursion in `supabase/back.sql` and `supabase/migrations/schema.sql`
- [ ] T002 Verify product loading and "Add to Cart" functionality via `browser_subagent`

## Phase 2: Foundational Refinements
- [ ] T003 [P] Enhance `src/context/CartContext.jsx` with robust sync logging and hydration status

## Phase 3: [US1] Immersive Cart Overview
- [ ] T004 [US1] Implement Glassmorphism (backdrop-blur-xl) on main container in `src/components/Cart/CartDrawer.jsx`
- [ ] T005 [P] [US1] Apply Cairo typography and brand color theme in `src/components/Cart/CartDrawer.jsx`
- [ ] T006 [US1] Add RTL-optimized Framer Motion entry/exit animations in `src/components/Cart/CartDrawer.jsx`

## Phase 4: [US2] Clear Product Management
- [ ] T007 [US2] Redesign product card with high-res thumbnails and Pill-labels for options in `src/components/Cart/CartDrawer.jsx`
- [ ] T008 [US2] Implement smooth layout transitions for item removal using `AnimatePresence`

## Phase 5: [US3] Transparent Cost Breakdown
- [ ] T009 [US3] Redesign sticky footer with floating breakdown and vibrant CTA button in `src/components/Cart/CartDrawer.jsx`

## Phase 6: Polish & final Validation
- [ ] T010 Verify "Premium" feel and mobile performance via `browser_subagent`

## Implementation Strategy
- **MVP First**: Restore product loading (T001-T002) before applying complex UI.
- **Incremental Delivery**: Each User Story is testable independently.
- **RTL Integrity**: All animations use direction-aware logic.
