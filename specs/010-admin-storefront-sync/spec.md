# Feature Specification: Admin and Storefront Synchronization

**Feature Branch**: `010-admin-storefront-sync`  
**Created**: 2026-04-07  
**Status**: Draft  
**Input**: User description: "محتاج عند إضافة منتج جديد من المنتجات فى لوحة تحكم المسؤول النظام يسمحلى أضيف بيانات منتج وساعتها هتظهر فى المتجر فى التصنيف المحدد له من صفحة المنتجات وعند إختيار منتج مميز يظهر فى متجرنا وعليه علامة نجمة كده ولا حاجة ، ومحتاج المنتج يتقبل يتضاف حتى لو كتبت عنوان بس من غير صورة حتى أو سعر ، فـ أهم حاجة الداتا اللى عندك تقبل بيها وتضيف فعلا منتج حقيقي ، محتاج بقى لما حد يعمل أوردر يظهر فى الطلبات فـ ظبط الدنيا كويس فى الموضوع ده ويهمنى إن ملف back.sql يكون بينفذ ده زى الفل وخد بالك كويس أوى إن ملف back.sql فيه حاجات ممكن نكون شيلناها فى التعديلات اللى فاتت زى مثلا على سبيل المثال فيه التصنيفات"

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Flexible Product Creation (Priority: P1)

As a Store Administrator, I want to be able to add a product using only its title (making price, image, and other details optional), so that I can quickly draft products to my database without having all information ready.

**Why this priority**: Without this, the admin cannot populate the store's inventory quickly. It ensures the database rules (`back.sql`) allow inserting partial records cleanly.

**Independent Test**: Can be fully tested by submitting a product form from the Admin Panel providing ONLY the "Name/Title" field, and receiving a success message with the product appearing in the list.

**Acceptance Scenarios**:

1. **Given** the "Add New Product" form, **When** I fill only the product title and submit, **Then** the product is created successfully with default/null values for the rest.
2. **Given** a product created without an image/price, **When** viewed on the storefront, **Then** it gracefully shows a placeholder image and a default "Call for price" or "0" price tag without breaking the layout.

---

### User Story 2 - Storefront Synchronization and Categorization (Priority: P1)

As a Customer, I want to see recently added products assigned to their respective categories instantly on the storefront, so I can browse the newly added inventory accurately.

**Why this priority**: Essential for making the store operational; admins need their actions to immediately reflect on the public-facing storefront.

**Independent Test**: Can be fully tested by creating a product in a specific category in Admin, then taking a customer role and verifying the product exists strictly within that category on the storefront.

**Acceptance Scenarios**:

1. **Given** a new product mapped to "Hardware", **When** a user visits the "Hardware" section on the storefront, **Then** the new product is listed there.

---

### User Story 3 - Featured Products Highlighting (Priority: P2)

As a Store Administrator, I want to mark specific products as "Featured" (مميز), so that they stand out to customers with a star icon on the storefront.

**Why this priority**: Important for marketing and promoting high-value items to drive sales.

**Independent Test**: Can be fully tested by toggling the "Featured" flag on an admin product, and observing a prominent visual indicator (e.g., a star) appearing on the item card on the public store.

**Acceptance Scenarios**:

1. **Given** a featured product, **When** a user views it on the storefront, **Then** a star icon or "Featured" badge is visibly displayed.
2. **Given** a non-featured product, **When** viewed, **Then** no star icon is displayed.

---

### User Story 4 - Order End-to-End Synchronization (Priority: P1)

As a Customer, I want my submitted orders to be accurately captured by the system so that the Administrator can immediately see and process them in the Admin Panel without delays or mock data.

**Why this priority**: Core e-commerce functionality. Without real-time order tracking, the business cannot function.

**Independent Test**: Can be fully tested by placing an order on the storefront and then logging into the Admin Panel to verify the order details are captured realistically from the database.

**Acceptance Scenarios**:

1. **Given** an active shopping cart, **When** a customer submits an order, **Then** the order is saved securely to the database.
2. **Given** a placed order, **When** the admin navigates to the Orders dashboard, **Then** the order is immediately visible with the correct total amount, products, and customer details.

---

### Edge Cases

- What happens when a user attempts to add a product without a title? (Validation error: Title is strictly required).
- Products with a base_price of 0 cannot be added to the cart; the UI instead replaces the 'Add to Cart' button with a 'Contact for price' label.
- What if a category previously created is deleted, but old products still point to it? (Database foreign key should handle nullification `ON DELETE SET NULL` or restrict it).

## Clarifications

### Session 2026-04-07
- Q: Handling unpriced (0) products → A: Option A - Prevent ordering and display 'Contact for Price' instead of 'Add to Cart'

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: System MUST allow product insertion in the database even if only the `name` or `title` is provided (other fields like `price`, `image_url`, `stock` must be nullable or have defaults).
- **FR-002**: System MUST link products to an optional `category_id` (so categorization works in backgrounds despite UI changes in previous turns).
- **FR-003**: System MUST provide a boolean database field (e.g., `is_featured`) for products and visually represent it with a star or badge on the storefront.
- **FR-004**: System MUST allow users to successfully place an order that securely writes into the `orders` and `order_items` tables.
- **FR-005**: System MUST present real-time or direct database queries in the Admin Orders view fetching actual customer orders without mocked data fallbacks.
- **FR-006**: The baseline SQL schema (`back.sql`) MUST correctly instantiate tables for `products`, `categories`, `orders`, and `order_items` with appropriate default values, UUIDs, and foreign key constraints allowing flexible insertion.

### Key Entities

- **Product**: Represents an item for sale (Attributes: id, name [Required], description, price [Optional, default 0], image_url [Optional], category_id, is_featured [Boolean, default false]).
- **Category**: Represents logical groupings for products (Attributes: id, name, slug). 
- **Order**: Represents a customer purchase (Attributes: id, customer_id/user_id, status, total_amount, shipping_address, created_at).
- **OrderItem**: Links orders to products (Attributes: id, order_id, product_id, quantity, price_at_purchase).

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: Admin can create a draft product (title only) and fully filled product; both visually appear on the storefront instantly without application errors.
- **SC-002**: 100% of orders submitted via the storefront interface reliably appear in the Admin Portal.
- **SC-003**: The `back.sql` file executes seamlessly without throwing database constraint errors, correctly establishing the foundation for all required data types.
