-- Inventory: products and audited stock adjustments.
BEGIN;
CREATE TABLE IF NOT EXISTS public.products (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  shop_id uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  name text NOT NULL CHECK (length(btrim(name)) > 0),
  sku text,
  category text NOT NULL DEFAULT 'General',
  unit text NOT NULL DEFAULT 'pcs',
  description text,
  purchase_price numeric(12,2) NOT NULL DEFAULT 0 CHECK (purchase_price >= 0),
  selling_price numeric(12,2) NOT NULL DEFAULT 0 CHECK (selling_price >= 0),
  stock_quantity numeric(12,3) NOT NULL DEFAULT 0 CHECK (stock_quantity >= 0),
  low_stock_threshold numeric(12,3) NOT NULL DEFAULT 5 CHECK (low_stock_threshold >= 0),
  is_archived boolean NOT NULL DEFAULT false,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);
-- Compatible with the initial products schema discussed previously.
ALTER TABLE public.products ADD COLUMN IF NOT EXISTS category text NOT NULL DEFAULT 'General';
CREATE UNIQUE INDEX IF NOT EXISTS products_shop_sku_unique
 ON public.products(shop_id, lower(btrim(sku))) WHERE sku IS NOT NULL AND btrim(sku) <> '';
CREATE INDEX IF NOT EXISTS products_shop_archive_idx ON public.products(shop_id, is_archived, name);
CREATE TABLE IF NOT EXISTS public.stock_movements (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  shop_id uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  product_id uuid NOT NULL REFERENCES public.products(id) ON DELETE RESTRICT,
  delta numeric(12,3) NOT NULL CHECK (delta <> 0),
  quantity_after numeric(12,3) NOT NULL CHECK (quantity_after >= 0),
  reason text NOT NULL CHECK (length(btrim(reason)) > 0),
  created_at timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS movements_shop_product_idx
 ON public.stock_movements(shop_id, product_id, created_at DESC);
ALTER TABLE public.products ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.stock_movements ENABLE ROW LEVEL SECURITY;

DO $$ BEGIN
 IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE schemaname='public' AND tablename='products' AND policyname='dk_products_select') THEN
 CREATE POLICY dk_products_select ON public.products FOR SELECT TO authenticated USING (shop_id=(select auth.uid())); END IF;
 IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE schemaname='public' AND tablename='products' AND policyname='dk_products_insert') THEN
 CREATE POLICY dk_products_insert ON public.products FOR INSERT TO authenticated WITH CHECK (shop_id=(select auth.uid()) AND stock_quantity=0); END IF;
 IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE schemaname='public' AND tablename='products' AND policyname='dk_products_update') THEN
 CREATE POLICY dk_products_update ON public.products FOR UPDATE TO authenticated USING (shop_id=(select auth.uid())) WITH CHECK (shop_id=(select auth.uid())); END IF;
 IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE schemaname='public' AND tablename='stock_movements' AND policyname='dk_movements_select') THEN
 CREATE POLICY dk_movements_select ON public.stock_movements FOR SELECT TO authenticated USING (shop_id=(select auth.uid())); END IF;
END $$;
-- No direct INSERT/UPDATE/DELETE policies on movements: all modifications are via RPC.
-- Prevent direct editing of the product stock count: all movements must be audited.
CREATE OR REPLACE FUNCTION public.dk_guard_stock_quantity() RETURNS trigger
LANGUAGE plpgsql SET search_path = '' AS $$
BEGIN
 IF NEW.stock_quantity IS DISTINCT FROM OLD.stock_quantity
    AND current_setting('digikhata.stock_rpc', true) IS DISTINCT FROM 'yes' THEN
   RAISE EXCEPTION 'Stock quantity must be changed using digikhata_adjust_stock.';
 END IF;
 NEW.updated_at := now();
 RETURN NEW;
END;
$$;
DROP TRIGGER IF EXISTS dk_products_guard_stock ON public.products;
CREATE TRIGGER dk_products_guard_stock BEFORE UPDATE ON public.products
 FOR EACH ROW EXECUTE FUNCTION public.dk_guard_stock_quantity();

CREATE OR REPLACE FUNCTION public.digikhata_adjust_stock(
  p_product_id uuid, p_delta numeric, p_reason text
) RETURNS numeric
LANGUAGE plpgsql SECURITY DEFINER SET search_path = '' AS $$
DECLARE v_product public.products%ROWTYPE; v_quantity numeric; v_user uuid;
BEGIN
 v_user := auth.uid();
 IF v_user IS NULL THEN RAISE EXCEPTION 'Authentication required'; END IF;
 IF p_delta IS NULL OR p_delta=0 OR scale(p_delta)>3 OR abs(p_delta)>999999999 THEN
   RAISE EXCEPTION 'Invalid stock adjustment'; END IF;
 IF p_reason IS NULL OR length(btrim(p_reason))=0 OR length(p_reason)>200 THEN
   RAISE EXCEPTION 'Reason required (1-200 characters)'; END IF;
 SELECT * INTO v_product FROM public.products WHERE id=p_product_id AND shop_id=v_user AND is_archived=false FOR UPDATE;
 IF NOT FOUND THEN RAISE EXCEPTION 'Product not found or archived'; END IF;
 v_quantity := v_product.stock_quantity + p_delta;
 IF v_quantity < 0 THEN RAISE EXCEPTION 'Insufficient stock'; END IF;
 PERFORM set_config('digikhata.stock_rpc','yes',true);
 UPDATE public.products SET stock_quantity=v_quantity WHERE id=p_product_id AND shop_id=v_user;
 INSERT INTO public.stock_movements(shop_id,product_id,delta,quantity_after,reason)
 VALUES (v_user,p_product_id,p_delta,v_quantity,btrim(p_reason));
 RETURN v_quantity;
END;
$$;
REVOKE ALL ON FUNCTION public.digikhata_adjust_stock(uuid,numeric,text) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.digikhata_adjust_stock(uuid,numeric,text) TO authenticated;
REVOKE ALL ON public.products, public.stock_movements FROM anon;
GRANT SELECT,INSERT,UPDATE ON public.products TO authenticated;
GRANT SELECT ON public.stock_movements TO authenticated;
COMMIT;
