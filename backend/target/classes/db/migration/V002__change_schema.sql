-- Example schema normalization adjustments (align with JPA annotations)
-- Ensure NOT NULLs align with entities

ALTER TABLE product
    ALTER COLUMN price SET NOT NULL;

-- Ensure order status is constrained to known values using a CHECK (simple alternative to enum)
ALTER TABLE orders
    ADD CONSTRAINT chk_orders_status CHECK (status IN ('pending','shipped','cancelled'));


