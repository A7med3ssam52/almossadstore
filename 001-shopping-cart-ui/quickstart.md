# Quickstart Guide: Shopping Cart UI & Persistence

## 1. Setup

Ensure the `cart_items` table is created in Supabase:
```sql
-- Migration file: supabase/migrations/20260403_cart_items.sql
```

## 2. Running Locally

Start the Vite development server:
```bash
npm run dev
```

## 3. Testing Features

### UI Refinements
- **Open Cart**: Click the cart icon in the header. Verify the `backdrop-blur` and smooth animation.
- **Empty State**: Clear your local storage or remove all items to see the new empty-state UI and "Explore" button.
- **Variant Labels**: Add a product with options (e.g., Color: Red, Size: XL) and verify they appear as pill-shaped labels.

### Persistence & Sync
- **Guest Usage**: Add items, refresh the page. Items should persist (via LocalStorage).
- **Login Sync**: Add items as a guest, then log in. Verify the items are **merged** into your account (User choice: Merge).
- **Rapid Updates**: Rapidly click "+" and "-" on a product. Open the **Network Tab** in DevTools; verify that calls to Supabase are **debounced** (only one call after multiple clicks in <300ms).

## 4. Verification

1. Check the `cart_items` table in Supabase dashboard to ensure rows match the UI state.
2. Logout and login on a different browser/device to verify the cart follows the account.
