# UI Contract: Shopping Cart Component

## Component Interface (`CartDrawer`)

The `CartDrawer` component interacts with the `CartContext` and depends on the following properties in the `CartItem` entity:

| Attribute | Type | Required | Description |
|-----------|------|----------|-------------|
| `id` | `uuid` | Yes | Unique product ID. |
| `name` | `string` | Yes | Product name for display. |
| `price` | `number` | Yes | Sale price or regular price. |
| `quantity` | `number` | Yes | Current count. |
| `options` | `object` | No | Selected variants (Color/Size). |
| `image_url`| `string` | No | Thumbnail for preview. |

## Sync API Contract (`Supabase`)

When synchronizing with the `cart_items` table:

- **Method**: `UPSERT` (Insert or Update on Conflict).
- **Conflict Target**: `(user_id, product_id, options::text)`.
- **Payload Format**:
  ```json
  {
    "user_id": "uuid",
    "product_id": "uuid",
    "quantity": "integer",
    "options": "jsonb"
  }
  ```

## Key Interactions

1. **On Open**: Fetch total items from local state.
2. **On Action**: Update local state immediately, then trigger debounced API call (300ms).
3. **On Close**: Ensure no pending debounce is discarded.
