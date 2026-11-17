-- Run from SQL editor after executing all numbered migrations.
-- Inspect policy rows. IMPORTANT: policies are permissive OR-combined by default.
SELECT tablename, policyname, cmd, roles, qual, with_check
FROM pg_policies
WHERE schemaname = 'public'
AND tablename IN (
 'customers', 'khata_transactions', 'products', 'stock_movements',
 'suppliers', 'supplier_transactions', 'ledger_audit')
ORDER BY tablename, policyname;

-- Check tables and security switches.
SELECT c.relname AS table_name, c.relrowsecurity AS rls_enabled
FROM pg_class c JOIN pg_namespace n ON n.oid = c.relnamespace
WHERE n.nspname = 'public' AND c.relname IN (
 'customers', 'khata_transactions', 'products', 'stock_movements',
 'suppliers', 'supplier_transactions', 'ledger_audit');

-- Check server functions.
SELECT proname, pg_get_function_identity_arguments(p.oid) AS signature,
       p.prosecdef AS security_definer
FROM pg_proc p JOIN pg_namespace n ON n.oid = p.pronamespace
WHERE n.nspname = 'public' AND proname IN (
 'digikhata_adjust_stock', 'dk_financial_snapshot',
 'dk_record_ledger_audit');

-- Detect pre-existing cross-shop customer transactions (should yield zero).
SELECT count(*) AS cross_shop_customer_transactions
FROM public.khata_transactions t JOIN public.customers c ON c.id = t.customer_id
WHERE t.shop_id IS DISTINCT FROM c.shop_id;

-- Detect invalid supplier links (should yield zero).
SELECT count(*) AS cross_shop_supplier_transactions
FROM public.supplier_transactions t JOIN public.suppliers s ON s.id = t.supplier_id
WHERE t.shop_id IS DISTINCT FROM s.shop_id;

-- Check publication registration.
SELECT tablename FROM pg_publication_tables
WHERE pubname = 'supabase_realtime' AND schemaname = 'public'
ORDER BY tablename;
