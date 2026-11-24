-- DigiKhata supplier ledger: non-destructive, shop-isolated migration.
-- Apply AFTER core and inventory. Verify on staging before production.
BEGIN;
CREATE TABLE IF NOT EXISTS public.suppliers (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  shop_id uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  name text NOT NULL CHECK (length(btrim(name)) BETWEEN 1 AND 150),
  phone text NOT NULL DEFAULT '' CHECK (length(phone) <= 30),
  address text CHECK (length(address) <= 500),
  is_archived boolean NOT NULL DEFAULT false,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  UNIQUE(id, shop_id)
);
CREATE INDEX IF NOT EXISTS suppliers_shop_name_idx
 ON public.suppliers(shop_id, is_archived, name);
CREATE TABLE IF NOT EXISTS public.supplier_transactions (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  shop_id uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  supplier_id uuid NOT NULL,
  type text NOT NULL CHECK (type IN ('purchase', 'payment')),
  amount numeric(12,2) NOT NULL CHECK (amount > 0),
  description text CHECK (length(description) <= 500),
  created_at timestamptz NOT NULL DEFAULT now(),
  FOREIGN KEY (supplier_id, shop_id) REFERENCES public.suppliers(id, shop_id)
    ON DELETE RESTRICT
);
CREATE INDEX IF NOT EXISTS supplier_transactions_shop_idx
 ON public.supplier_transactions(shop_id, supplier_id, created_at DESC);
ALTER TABLE public.suppliers ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.supplier_transactions ENABLE ROW LEVEL SECURITY;

DO $$ BEGIN
 IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE schemaname='public'
 AND tablename='suppliers' AND policyname='dk_supplier_select') THEN
 CREATE POLICY dk_supplier_select ON public.suppliers FOR SELECT
 TO authenticated USING (shop_id = (select auth.uid())); END IF;
 IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE schemaname='public'
 AND tablename='suppliers' AND policyname='dk_supplier_insert') THEN
 CREATE POLICY dk_supplier_insert ON public.suppliers FOR INSERT
 TO authenticated WITH CHECK (shop_id = (select auth.uid())); END IF;
 IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE schemaname='public'
 AND tablename='suppliers' AND policyname='dk_supplier_update') THEN
 CREATE POLICY dk_supplier_update ON public.suppliers FOR UPDATE
 TO authenticated USING (shop_id = (select auth.uid()))
 WITH CHECK (shop_id = (select auth.uid())); END IF;
 IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE schemaname='public'
 AND tablename='supplier_transactions' AND policyname='dk_stx_select') THEN
 CREATE POLICY dk_stx_select ON public.supplier_transactions FOR SELECT
 TO authenticated USING (shop_id = (select auth.uid())); END IF;
 IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE schemaname='public'
 AND tablename='supplier_transactions' AND policyname='dk_stx_insert') THEN
 CREATE POLICY dk_stx_insert ON public.supplier_transactions FOR INSERT
 TO authenticated WITH CHECK (shop_id = (select auth.uid()) AND EXISTS (
 SELECT 1 FROM public.suppliers s WHERE s.id = supplier_id
 AND s.shop_id = (select auth.uid()) AND s.is_archived=false)); END IF;
 IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE schemaname='public'
 AND tablename='supplier_transactions' AND policyname='dk_stx_update') THEN
 CREATE POLICY dk_stx_update ON public.supplier_transactions FOR UPDATE
 TO authenticated USING (shop_id = (select auth.uid()))
 WITH CHECK (shop_id = (select auth.uid()) AND EXISTS (
 SELECT 1 FROM public.suppliers s WHERE s.id = supplier_id
 AND s.shop_id = (select auth.uid()) AND s.is_archived=false)); END IF;
 IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE schemaname='public'
 AND tablename='supplier_transactions' AND policyname='dk_stx_delete') THEN
 CREATE POLICY dk_stx_delete ON public.supplier_transactions FOR DELETE
 TO authenticated USING (shop_id = (select auth.uid())); END IF;
END $$;

REVOKE ALL ON public.suppliers, public.supplier_transactions FROM anon;
GRANT SELECT, INSERT, UPDATE ON public.suppliers TO authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE ON public.supplier_transactions TO authenticated;
COMMIT;
