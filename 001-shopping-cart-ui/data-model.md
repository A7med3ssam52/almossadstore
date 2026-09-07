# Data Model: Shopping Cart Persistence

## Entities

### `cart_items` (Supabase Table)
Represents the persistent server-side state of a user's shopping cart.

| Field | Type | Description |
|-------|------|-------------|
| `id` | `uuid` | Primary Key. |
| `profile_id` | `uuid` | Foreign Key to `profiles.id`. |
| `product_id` | `uuid` | Foreign Key to `products.id`. |
| `quantity` | `integer` | Number of items. Default: 1. |
| `options` | `jsonb` | Selected variants (size, color, etc.). |
| `created_at` | `timestamptz` | When the item was added. |
| `updated_at` | `timestamptz` | When the item was last modified. |

## Relationships
- **Profile 1:N CartItems**: A user has many items in their cart.
- **Product 1:N CartItems**: A product can be in many users' carts.

## Validation Rules
- `quantity` MUST be at least 1.
- `options` MUST be an object (even if empty).
- `profile_id` + `product_id` + `options` (hash) should ideally be unique to avoid duplicate rows for the same SKU/variant combination.
