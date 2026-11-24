-- Immutable audit trail for financial updates/deletions by authenticated shops.
-- This is a historical audit, not a substitute for backups or accounting review.
BEGIN;
CREATE TABLE IF NOT EXISTS public.ledger_audit (
  id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  shop_id uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  actor_id uuid REFERENCES auth.users(id) ON DELETE SET NULL,
  source_table text NOT NULL,
  record_id uuid NOT NULL,
  operation text NOT NULL CHECK (operation IN ('INSERT','UPDATE','DELETE')),
  before_state jsonb,
  after_state jsonb,
  changed_at timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS ledger_audit_shop_recent_idx
  ON public.ledger_audit(shop_id, changed_at DESC);
ALTER TABLE public.ledger_audit ENABLE ROW LEVEL SECURITY;
DO $$ BEGIN
 IF NOT EXISTS (
    SELECT 1 FROM pg_policies WHERE schemaname='public'
    AND tablename='ledger_audit' AND policyname='dk_audit_select'
  ) THEN
   CREATE POLICY dk_audit_select ON public.ledger_audit
     FOR SELECT TO authenticated USING (shop_id = (select auth.uid()));
 END IF;
END $$;
REVOKE ALL ON public.ledger_audit FROM anon, authenticated;
GRANT SELECT ON public.ledger_audit TO authenticated;

CREATE OR REPLACE FUNCTION public.dk_record_ledger_audit()
RETURNS trigger LANGUAGE plpgsql SECURITY DEFINER SET search_path = '' AS $$
BEGIN
  INSERT INTO public.ledger_audit(
    shop_id, actor_id, source_table, record_id, operation,
    before_state, after_state
  ) VALUES (
    CASE WHEN TG_OP = 'DELETE' THEN OLD.shop_id ELSE NEW.shop_id END,
    auth.uid(), TG_TABLE_NAME,
    CASE WHEN TG_OP = 'DELETE' THEN OLD.id ELSE NEW.id END,
    TG_OP,
    CASE WHEN TG_OP = 'INSERT' THEN NULL ELSE to_jsonb(OLD) END,
    CASE WHEN TG_OP = 'DELETE' THEN NULL ELSE to_jsonb(NEW) END
  );
  RETURN CASE WHEN TG_OP='DELETE' THEN OLD ELSE NEW END;
END;
$$;
REVOKE ALL ON FUNCTION public.dk_record_ledger_audit() FROM PUBLIC, anon;

DROP TRIGGER IF EXISTS dk_customer_ledger_audit ON public.khata_transactions;
CREATE TRIGGER dk_customer_ledger_audit
 AFTER INSERT OR UPDATE OR DELETE ON public.khata_transactions
 FOR EACH ROW EXECUTE FUNCTION public.dk_record_ledger_audit();
DROP TRIGGER IF EXISTS dk_supplier_ledger_audit ON public.supplier_transactions;
CREATE TRIGGER dk_supplier_ledger_audit
 AFTER INSERT OR UPDATE OR DELETE ON public.supplier_transactions
 FOR EACH ROW EXECUTE FUNCTION public.dk_record_ledger_audit();
COMMIT;
