# Data Model & Schema Details

This feature heavily leverages the existing `back.sql` schema while introducing a slight correction to Row Level Security to support the full feature spectrum securely.

## 1. Core Entities Configuration

### `products`
The core entity for inventory.
- **`name`**: `TEXT NOT NULL DEFAULT ''` - The only strictly required data point.
- **`description`**: `TEXT NULL`
- **`base_price`**: `DECIMAL(10,2) DEFAULT 0` - Automatically defaults to 0 if left blank.
- **`images`**: `JSONB DEFAULT '[]'::jsonb` - Array of URLs, accepts empty arrays securely.
- **`category_id`**: `BIGINT` (Foreign Key -> `categories.id`) - Determines where the product shows up on the storefront. Optional.
- **`is_featured`**: `BOOLEAN DEFAULT false` - Star tag.

### `orders`
The outcome of the Storefront synchronized to Admin.
- **`id`**: `UUID PRIMARY KEY`
- **`user_id`**: `UUID NULL` - **Modified Policy required** Allows un-authenticated guest orders.
- **`total_amount`**: `DECIMAL(10,2) DEFAULT 0`
- **`status`**: `TEXT DEFAULT 'pending'` - Mapped to the Admin workflow states.
- **`customer_name`**, **`contact_phone`**, **`shipping_address`**: Crucial customer details.

### `categories`
Used behind the scenes to map new products to `دهانات`, `حدايد`, etc.
- **`id`**: `BIGSERIAL`
- **`name`**: `TEXT` (Target: Arabic categorical labels used in Navbar)

## 2. Policy Adjustments Required (`back.sql`)
The following SQL migration rules will be applied to guarantee seamless integration for both Users and Admins:

```sql
-- Fix Orders constraint for unauthenticated guest checkouts
DROP POLICY IF EXISTS "Users can create own orders" ON public.orders;
CREATE POLICY "Users can create own orders" ON public.orders
FOR INSERT WITH CHECK (auth.uid() = user_id OR user_id IS NULL);

-- Fix Order_items constraint for matching unauthenticated orders
DROP POLICY IF EXISTS "Users can insert own order items" ON public.order_items;
CREATE POLICY "Users can insert own order items" ON public.order_items
FOR INSERT WITH CHECK (
    EXISTS (
        SELECT 1 FROM public.orders
        WHERE id = order_items.order_id 
        AND (user_id = auth.uid() OR user_id IS NULL)
    )
);
```
