# Implementation Plan: Admin and Storefront Synchronization

**Branch**: `010-admin-storefront-sync` | **Date**: 2026-04-07 | **Spec**: [Link to Spec](./spec.md)
**Input**: Feature specification from `/specs/010-admin-storefront-sync/spec.md`

## Summary

The objective is to seamlessly connect the Admin panel's product creation workflow to the public storefront, ensuring partial data insertions (e.g., just a Title) succeed gracefully. Furthermore, we must visually denote "Featured" (مميز) products and guarantee that Storefront orders correctly filter into the Admin dashboard in real-time, accounting for all essential database RLS tweaks inside `back.sql`.

## Technical Context

**Language/Version**: React 18, Supabase JS Client  
**Primary Dependencies**: `lucide-react`, `framer-motion`, `@supabase/supabase-js`  
**Storage**: PostgreSQL (Supabase `products`, `categories`, `orders`, `order_items`)  
**Target Platform**: Web Browsers  
**Project Type**: Web Application Dashboard & E-commerce Public Storefront  

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

- [x] Code is properly documented and understandable.
- [x] React components remain functionally independent.
- [x] State flow relies responsibly on existing services (`orderService`, `productService`).

## Project Structure

### Documentation (this feature)

```text
specs/010-admin-storefront-sync/
├── plan.md              # This file
├── research.md          # Technical research and RLS discovery 
├── data-model.md        # Database layout validation
└── tasks.md             # Tasks checklist (to be generated)
```

### Source Code

```text
src/
├── components/
│   ├── Admin/
│   │   ├── Products/    # Adjust forms to allow nullable fields gracefully
│   ├── Catalog/         # Storefront Product Cards (Render 'Star' if is_featured)
├── services/
│   └── supabase/        # Update services to properly fetch and write
supabase/
└── back.sql             # Minor RLS policy updates for guest checkouts
```

**Structure Decision**: A dual setup modifying the React components residing in `src/components/Admin` alongside their counterpart public displays under `src/components/`, heavily supported by modifications to RLS in `supabase/back.sql`.

## Phase Plan Outline

1. **Database Adjustments**: Modify `back.sql` to apply the fixed RLS policies allowing Guest checkouts (which feed into the Admin Orders list without blocking on `user_id = auth.uid()`). Run the SQL to ensure the DB accepts it immediately.
2. **Product Form Flexibility**: Adjust the Admin product creation form (`AdminInput`, `Products.jsx`) to default nullable fields or bypass validations when not provided, except for the Title.
3. **Featured Indicator**: Implement a visual logic on the Storefront (`ProductCard.jsx`, `Catalog.jsx`) to render a golden Star icon if `is_featured === true`.
4. **Order Synchrony Verification**: Guarantee that the checkout flow calls `createOrder` properly and the Admin page captures it exactly as it occurred.
