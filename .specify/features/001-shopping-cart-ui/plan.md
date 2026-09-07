# Implementation Plan: Shopping Cart UI Refinement & Persistence

This plan outlines the steps to upgrade the "Al Mossad Store" shopping cart into a premium, interactive experience with immediate server-side synchronization for logged-in users while maintaining a robust guest experience.

## User Review Required

> [!IMPORTANT]
> **Data Sync Strategy**: We will implement "Immediate Sync" (from Q1 clarification) with a 300ms debounce to balance UI responsiveness with server load.
> **Guest Support**: Cart data will persist in `localStorage` for guests and will be merged into the user's account upon login.
> **Aesthetics**: Using `framer-motion` for spring-based drawer transitions and `lucide-react` for modern iconography.

## Proposed Changes

### [Component] Cart Context & Sync Logic
Updating core state management to support Supabase synchronization.

#### [MODIFY] [CartContext.jsx](file:///c:/Users/admin/Desktop/Al%20Mossad%20Store/src/context/CartContext.jsx)
- **Supabase Sync**: Update `useEffect` to sync items if the user is authenticated.
- **Merge logic**: Combine guest cart with user cart on login (User choice: Merge).

### [Component] Cart Drawer UI
Refining visual presentation and informative sections.

#### [MODIFY] [CartDrawer.jsx](file:///c:/Users/admin/Desktop/Al%20Mossad%20Store/src/components/Cart/CartDrawer.jsx)
- **Glassmorphism**: Apply `backdrop-blur-xl` and semi-transparent backgrounds.
- **Pill Labels**: Update item display to show variants as styled tokens (FR-011).
- **Empty State**: Refined "Continue Shopping" UI (FR-010).
- **Price Breakdown**: Sticky footer with detailed cost breakdown (FR-009).

### [Component] Database
#### [NEW] [cart_items.sql](file:///c:/Users/admin/Desktop/Al%20Mossad%20Store/supabase/migrations/20260403_cart_items.sql)
- Migration to create the `cart_items` table with RLS policies.

## Open Questions

- **Merging Strategy**: Merging confirmed by user.

## Verification Plan

### Manual Verification
1. Verify "Glassmorphism" look and "Pill Labels" for variants.
2. Rapidly change quantities to ensure the 300ms debounce prevents API flooding.
3. Logout/Login to verify cart persistence via Supabase.
