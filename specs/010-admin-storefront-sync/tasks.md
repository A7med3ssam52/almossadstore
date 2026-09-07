# Application Tasks: 010-admin-storefront-sync

This checklist tracks the implementation of the Admin and Storefront Synchronization feature, built strictly off `spec.md`, `plan.md`, `research.md`, and `data-model.md`.

## Phase 1: Foundational Database Adjustments
**Goal**: Enable Guest Checkouts by updating core RLS policies without breaking Admin functionality.
**Independent Test**: Guest can place an order without an RLS permission error.

- [x] T001 Update Order insertion policies to permit `user_id IS NULL` in `supabase/back.sql`.
- [x] T002 Update OrderItems insertion policies matching the `user_id IS NULL` check in `supabase/back.sql`.
- [x] T003 Execute the modified `supabase/back.sql` directly on the connected Supabase instance to apply new RLS policies.

## Phase 2: [US1] Flexible Product Creation
**Goal**: Guarantee product forms in Admin allow inserting records with purely a title (name) without blocking validation.
**Independent Test**: Submitting a product with only title succeeds.

- [x] T004 [US1] Loosen client-side form validation criteria for price, stock, category, and images in `src/pages/Admin/Products/ProductForm.jsx` (or equivalent file).
- [x] T005 [US1] Test insertion of basic title-only product using `src/services/supabase/productService.js`.

## Phase 3: [US2] Storefront Synchronization and Categorization
**Goal**: Display newly added items in their proper specific category sections globally across the web UI.
**Independent Test**: Adding a product to 'Hardware' in Admin reflects immediately in the Hardware page of the store.

- [x] T006 [P] [US2] Ensure category pages (e.g. `src/pages/Category.jsx`) robustly handle blank/missing images seamlessly using an empty placeholder.
- [x] T007 [P] [US2] Ensure category filtering works reliably if `category_id` maps correctly to `back.sql` references.

## Phase 4: [US3] Featured Products Highlighting
**Goal**: Attach visual distinction to specifically flagged products.
**Independent Test**: Toggling featured switch reveals a star badge on the storefront.

- [x] T008 [US3] Add a star vector/icon `<Star size={16} fill="gold"/>` conditional render inside the storefront product card (e.g., `src/components/ProductCard.jsx`) if `product.is_featured` is true.

## Phase 5: [US4] Order End-to-End Synchronization
**Goal**: Sync completed checkouts gracefully directly to the Admin Dashboard exactly as they're inserted.
**Independent Test**: Placing a mock order as an anonymous customer flows exactly into `OrderList.jsx`.

- [x] T009 [US4] Verify and ensure payload generated in Checkout view (e.g., `src/pages/Checkout.jsx`) correctly sends `user_id: null` instead of failing if not logged in.
- [x] T010 [US4] Log into the Admin panel and confirm the real-time fetch visually lists the new test order.

## Implementation Strategy & Dependencies

1. **MVP Target**: Phase 1 and 2 comprise the literal core. If guest checkout inserts fail, the system is blocked. Start there.
2. **Parallel Delivery**: Developers can build out mapping logic for UI (Phase 3 & 4) parallel to tracking actual database logic.
3. Test end-to-end (Phase 5) manually prior to sign-off to ensure all phases coalesce.
