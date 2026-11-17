-- Aggregate customer and supplier ledgers in PostgreSQL instead of downloading
-- every financial transaction to the Flutter app. SECURITY INVOKER keeps RLS.
BEGIN;
CREATE OR REPLACE FUNCTION public.dk_financial_snapshot(
  p_start timestamptz,
  p_end timestamptz
) RETURNS jsonb
LANGUAGE sql STABLE SECURITY INVOKER SET search_path = '' AS $$
WITH
ledger AS (
  SELECT type, amount, created_at
  FROM public.khata_transactions
  WHERE shop_id = (select auth.uid())
),
period_ledger AS (
  SELECT type, amount, created_at FROM ledger
  WHERE created_at >= p_start AND created_at < p_end
),
ledger_total AS (
  SELECT
    COALESCE(sum(amount) FILTER (WHERE type = 'credit'), 0) AS total_credit,
    COALESCE(sum(amount) FILTER (WHERE type = 'payment'), 0) AS total_payment
  FROM ledger
),
period_total AS (
  SELECT
    COALESCE(sum(amount) FILTER (WHERE type = 'credit'), 0) AS period_credit,
    COALESCE(sum(amount) FILTER (WHERE type = 'payment'), 0) AS period_payment
  FROM period_ledger
),
by_day AS (
  SELECT (created_at AT TIME ZONE 'Asia/Karachi')::date AS day,
    COALESCE(sum(amount) FILTER (WHERE type='credit'), 0) AS credit,
    COALESCE(sum(amount) FILTER (WHERE type='payment'), 0) AS payments
  FROM period_ledger
  GROUP BY 1
),
customer_count AS (
  SELECT count(*) AS count FROM public.customers
  WHERE shop_id = (select auth.uid()) AND is_archived = false
),
stock AS (
  SELECT count(*) AS count,
    COALESCE(sum(purchase_price * stock_quantity), 0) AS cost_value
  FROM public.products
  WHERE shop_id = (select auth.uid()) AND is_archived = false
),
supplier_count AS (
  SELECT count(*) AS count FROM public.suppliers
  WHERE shop_id = (select auth.uid()) AND is_archived = false
),
supplier_totals AS (
  SELECT COALESCE(sum(CASE WHEN type='purchase' THEN amount
    WHEN type='payment' THEN -amount END), 0) AS payable
  FROM public.supplier_transactions
  WHERE shop_id = (select auth.uid())
)
SELECT jsonb_build_object(
  'outstanding', ledger_total.total_credit - ledger_total.total_payment,
  'period_credit', period_total.period_credit,
  'period_payments', period_total.period_payment,
  'customer_count', customer_count.count,
  'product_count', stock.count,
  'inventory_cost_value', stock.cost_value,
  'supplier_count', supplier_count.count,
  'supplier_payable', supplier_totals.payable,
  'daily', COALESCE((SELECT jsonb_agg(jsonb_build_object(
    'day', day, 'credit', credit, 'payments', payments) ORDER BY day)
    FROM by_day), '[]'::jsonb)
) FROM ledger_total, period_total, customer_count, stock,
  supplier_count, supplier_totals;
$$;
REVOKE ALL ON FUNCTION public.dk_financial_snapshot(timestamptz,timestamptz)
 FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.dk_financial_snapshot(timestamptz,timestamptz)
 TO authenticated;
COMMIT;
