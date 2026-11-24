-- Opt-in realtime replication for shop data tables.
-- Publishing tables does NOT bypass RLS. Users must still be authenticated.
BEGIN;
DO $$
DECLARE table_name text;
BEGIN
  FOREACH table_name IN ARRAY ARRAY[
    'customers','khata_transactions','products','stock_movements',
    'suppliers','supplier_transactions'
  ] LOOP
    IF NOT EXISTS (
      SELECT 1 FROM pg_publication_tables
      WHERE pubname = 'supabase_realtime'
      AND schemaname = 'public' AND tablename = table_name
    ) THEN
      EXECUTE format('ALTER PUBLICATION supabase_realtime ADD TABLE public.%I',table_name);
    END IF;
  END LOOP;
END $$;
-- Default replica identity usually emits only primary keys for deletions.
-- App refresh / RLS cannot infer shop_id from a DELETE without old row data.
ALTER TABLE public.customers REPLICA IDENTITY FULL;
ALTER TABLE public.khata_transactions REPLICA IDENTITY FULL;
ALTER TABLE public.products REPLICA IDENTITY FULL;
ALTER TABLE public.stock_movements REPLICA IDENTITY FULL;
ALTER TABLE public.suppliers REPLICA IDENTITY FULL;
ALTER TABLE public.supplier_transactions REPLICA IDENTITY FULL;
COMMIT;
