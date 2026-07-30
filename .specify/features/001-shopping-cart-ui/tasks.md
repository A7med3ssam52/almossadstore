# Tasks: Shopping Cart UI Refinement

**Input**: Design documents from `.specify/features/001-shopping-cart-ui/`
**Prerequisites**: plan.md, spec.md, research.md, data-model.md, contracts/ui-contract.md

**Organization**: Tasks are grouped by user story to enable independent implementation and testing.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: Which user story this task belongs to (e.g., US1, US2, US3)

---

## Phase 1: Setup (Shared Infrastructure)

**Purpose**: Project initialization and basic structure

- [x] T001 Verify feature directory and metadata in `.specify/features/001-shopping-cart-ui/`

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Core infrastructure for data persistence and authentication context

- [x] T002 Create `cart_items` table migration in `supabase/migrations/20260403_cart_items.sql`
- [x] T003 [P] Add Supabase auth listener and sync boilerplate in `src/context/CartContext.jsx`

**Checkpoint**: Database schema and basic context ready - user story implementation can begin.

---

## Phase 3: User Story 1 - Viewing items in the cart (Priority: P1) 🎯 MVP

**Goal**: As a customer, I want to see a clear list of products in a modern slide-in glassmorphism drawer.

**Independent Test**: User adds an item, clicks the cart icon, and verifies the drawer opens with correct product details and glassmorphism background.

### Implementation for User Story 1

- [x] T004 [P] [US1] Update `CartDrawer.jsx` backdrop and main panel with `backdrop-blur-xl` and semi-transparent styles
- [x] T005 [US1] Implement `CartItem` display in `CartDrawer.jsx` with high-quality thumbnails and subtotal
- [x] T006 [P] [US1] Implement Pill-style variant labels (Color/Size) in `CartDrawer.jsx` per FR-011
- [x] T007 [US1] Implement Detailed Price Breakdown (Subtotal, Discount, Estimated Total) in `CartDrawer.jsx` footer per FR-009

**Checkpoint**: User Story 1 is functional and visually complete (Premium View).

---

## Phase 4: User Story 2 - Managing quantities and removal (Priority: P1)

**Goal**: As a customer, I want to adjust quantities or remove items with immediate server sync and smooth animations.

**Independent Test**: User clicks +/- or Trash icon; verify quantity updates instantly in UI and syncs to Supabase (check network tab for 300ms debounce).

### Implementation for User Story 2

- [x] T008 [US2] Implement `syncToSupabase` logic in `src/context/CartContext.jsx` with 300ms debounce helper
- [x] T009 [US2] Connect `updateQuantity` and `removeFromCart` actions to the sync helper in `src/context/CartContext.jsx`
- [x] T010 [P] [US2] Add `layout` animations from `framer-motion` to the item list in `CartDrawer.jsx` for smooth re-ordering/deletion
- [x] T011 [US2] Implement Guest-to-User "Merge" logic in `src/context/CartContext.jsx` (adding guest items to the account cart on login)

**Checkpoint**: User Story 2 is functional with full persistence and synchronization.

---

## Phase 5: User Story 3 - Empty Cart State (Priority: P2)

**Goal**: As a customer with no items, I want to see a friendly message and a clear "Explore" button.

**Independent Test**: Open cart with no items; verify centered "Explore Shop" button and custom graphic are shown.

### Implementation for User Story 3

- [x] T012 [P] [US3] Implement refined empty state in `CartDrawer.jsx` with centered CTA and SVG illustration per FR-010

---

## Phase 6: Polish & Cross-Cutting Concerns

**Purpose**: Final verification and consistency checks

- [ ] T013 [P] Verify RTL support and Cairo font consistency across all new cart elements
- [ ] T014 Security check: Verify Supabase RLS (Row Level Security) prevents users from seeing/modifying other users' carts
- [ ] T015 Run `quickstart.md` validation steps to confirm successful implementation of the entire feature
