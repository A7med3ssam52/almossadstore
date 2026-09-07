# Research & Technical Decisions: Admin and Storefront Synchronization

## Clarifications Extracted from Technical Context

### 1. Database Schema Status & Nullability
**Decision**: The existing `back.sql` schema already supports optional product fields efficiently. We simply need to ensure our React Admin frontend leverages this correctly.
**Rationale**: `base_price`, `stock_quantity`, `images`, and `category_ids` all have solid default constraints (`0`, `'[]'::jsonb`). Title (`name`) is the only strictly required data block, matching the user's specification perfectly.

### 2. Storefront Guest Order Insertions (RLS Check)
**Decision**: Discovered a constraint block in Row Level Security (RLS) for `public.orders`. Postgres evaluates `auth.uid() = user_id` as NULL if both are missing (as is the case with Guest Checkout), causing the `INSERT` to fail. We will update the RLS policies to `(auth.uid() = user_id OR user_id IS NULL)`.
**Rationale**: E-commerce stores typically rely heavily on guest checkouts. Unless the user specifies a strict logged-in-only policy, the RLS must gracefully accept `user_id IS NULL` writes into `orders` and `order_items`.

### 3. Star Icon / Featured Products Representation
**Decision**: A prominent "⭐ مميز" badge will be added to the storefront product card if `is_featured` is true.
**Rationale**: Directly addresses User Story 3 without polluting categories.

---

**Output**: All technical blockers and unknowns resolved.
