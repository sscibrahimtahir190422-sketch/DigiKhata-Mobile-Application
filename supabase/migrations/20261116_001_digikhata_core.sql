-- DigiKhata core reconstruction, based on prior project schema.
-- Run in Supabase SQL Editor with a database backup. No existing data is deleted.
-- Existing tables are preserved; ALTER statements only add missing fields.
BEGIN;

CREATE TABLE IF NOT EXISTS public.customers (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  shop_id uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  name text NOT NULL CHECK (length(btrim(name)) > 0),
  phone text NOT NULL DEFAULT '',
  created_at timestamptz NOT NULL DEFAULT now(),
  is_archived boolean NOT NULL DEFAULT false
);
ALTER TABLE public.customers ADD COLUMN IF NOT EXISTS is_archived boolean NOT NULL DEFAULT false;
CREATE UNIQUE INDEX IF NOT EXISTS customers_id_shop_unique ON public.customers(id, shop_id);
CREATE INDEX IF NOT EXISTS customers_shop_active_idx ON public.customers(shop_id, is_archived, created_at DESC);

CREATE TABLE IF NOT EXISTS public.khata_transactions (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  shop_id uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  customer_id uuid NOT NULL REFERENCES public.customers(id) ON DELETE RESTRICT,
  type text NOT NULL CHECK (type IN ('credit','payment')),
  amount numeric(12,2) NOT NULL CHECK (amount > 0),
  description text,
  created_at timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS khata_transactions_shop_date_idx
  ON public.khata_transactions(shop_id, created_at DESC);
CREATE INDEX IF NOT EXISTS khata_transactions_customer_date_idx
  ON public.khata_transactions(shop_id, customer_id, created_at DESC);
-- Prevent cross-shop references, even if customer ID is guessed.
DO $$
BEGIN
 IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conrelid='public.khata_transactions'::regclass
   AND conname='khata_transactions_customer_shop_fk') THEN
   ALTER TABLE public.khata_transactions ADD CONSTRAINT khata_transactions_customer_shop_fk
     FOREIGN KEY (customer_id, shop_id) REFERENCES public.customers(id, shop_id)
     ON DELETE RESTRICT NOT VALID;
 END IF;
END $$;

ALTER TABLE public.customers ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.khata_transactions ENABLE ROW LEVEL SECURITY;

DO $$ BEGIN
 IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE schemaname='public' AND tablename='customers' AND policyname='dk_customer_select') THEN
   CREATE POLICY dk_customer_select ON public.customers FOR SELECT TO authenticated USING (shop_id = (select auth.uid()));
 END IF;
 IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE schemaname='public' AND tablename='customers' AND policyname='dk_customer_insert') THEN
   CREATE POLICY dk_customer_insert ON public.customers FOR INSERT TO authenticated WITH CHECK (shop_id = (select auth.uid()));
 END IF;
 IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE schemaname='public' AND tablename='customers' AND policyname='dk_customer_update') THEN
   CREATE POLICY dk_customer_update ON public.customers FOR UPDATE TO authenticated USING (shop_id = (select auth.uid())) WITH CHECK (shop_id = (select auth.uid()));
 END IF;
 IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE schemaname='public' AND tablename='customers' AND policyname='dk_customer_delete') THEN
   CREATE POLICY dk_customer_delete ON public.customers FOR DELETE TO authenticated USING (shop_id = (select auth.uid()));
 END IF;
 IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE schemaname='public' AND tablename='khata_transactions' AND policyname='dk_tx_select') THEN
   CREATE POLICY dk_tx_select ON public.khata_transactions FOR SELECT TO authenticated USING (shop_id = (select auth.uid()));
 END IF;
 IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE schemaname='public' AND tablename='khata_transactions' AND policyname='dk_tx_insert') THEN
   CREATE POLICY dk_tx_insert ON public.khata_transactions FOR INSERT TO authenticated WITH CHECK (
     shop_id = (select auth.uid()) AND EXISTS (
       SELECT 1 FROM public.customers c WHERE c.id = customer_id AND c.shop_id = (select auth.uid())
     ));
 END IF;
 IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE schemaname='public' AND tablename='khata_transactions' AND policyname='dk_tx_update') THEN
   CREATE POLICY dk_tx_update ON public.khata_transactions FOR UPDATE TO authenticated
     USING (shop_id = (select auth.uid()))
     WITH CHECK (shop_id = (select auth.uid()) AND EXISTS (
       SELECT 1 FROM public.customers c WHERE c.id = customer_id AND c.shop_id = (select auth.uid())
     ));
 END IF;
 IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE schemaname='public' AND tablename='khata_transactions' AND policyname='dk_tx_delete') THEN
   CREATE POLICY dk_tx_delete ON public.khata_transactions FOR DELETE TO authenticated USING (shop_id = (select auth.uid()));
 END IF;
END $$;

REVOKE ALL ON public.customers, public.khata_transactions FROM anon;
GRANT SELECT, INSERT, UPDATE, DELETE ON public.customers, public.khata_transactions TO authenticated;
COMMIT;
