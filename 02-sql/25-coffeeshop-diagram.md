# Coffee-Shop Database Diagram

This entity-relationship diagram shows how shops, menu items, customers,
and sales are connected. A voucher may belong to a registered customer or
represent a walk-in sale with no customer record.

```mermaid
erDiagram
    SHOPS ||--o{ CATEGORIES : has
    SHOPS ||--o{ MENUS : offers
    SHOPS ||--o{ CUSTOMERS : registers
    SHOPS ||--o{ VOUCHERS : issues

    CATEGORIES ||--o{ MENUS : classifies
    MENUS ||--o{ VOUCHER_ITEMS : "sold as"
    VOUCHERS ||--o{ VOUCHER_ITEMS : contains
    CUSTOMERS ||--o{ VOUCHERS : "placed by"

    SHOPS {
        bigint id PK
        string name
        string address
        string phone
        timestamp created_at
        timestamp updated_at
    }

    CATEGORIES {
        bigint id PK
        bigint shop_id FK
        string name
        timestamp created_at
        timestamp updated_at
    }

    MENUS {
        bigint id PK
        bigint shop_id FK
        bigint category_id FK
        string name
        string description
        decimal price
        bool is_available
        timestamp created_at
        timestamp updated_at
    }

    CUSTOMERS {
        bigint id PK
        bigint shop_id FK
        string name
        string phone
        string email
        timestamp created_at
        timestamp updated_at
    }

    VOUCHERS {
        bigint id PK
        bigint shop_id FK
        bigint customer_id FK
        string voucher_number
        decimal subtotal
        decimal discount
        decimal total
        string payment_method
        timestamp created_at
    }

    VOUCHER_ITEMS {
        bigint id PK
        bigint voucher_id FK
        bigint menu_id FK
        int quantity
        decimal price
        decimal subtotal
    }

```
