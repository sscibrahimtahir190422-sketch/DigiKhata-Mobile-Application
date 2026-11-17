# DigiKhata architecture

## Flutter application structure

- `lib/app`: GetX route registration, auth middleware, application initialization.
- `lib/core`: brand theme, translations, persisted locale settings and realtime subscriptions.
- `lib/data/repositories`: shared repository implementations for auth, dashboard and customers.
- `lib/features/<module>/models`: immutable models / JSON conversion.
- `lib/features/<module>/repositories`: interfaces and Supabase implementations.
- `lib/features/<module>/viewmodels`: GetX controllers and reactive state.
- `lib/features/<module>/bindings`: `Get.lazyPut` dependency registration.
- `lib/features/<module>/views`: screens and user interactions.

## Data isolation

All shop-owned tables have a `shop_id = auth.uid()` policy for authenticated
users. Client queries also filter explicitly by shop ID whenever possible.
Supplier entries have a composite foreign key `(supplier_id, shop_id)` that
prevents cross-shop references. The original customer financial ledger has a
reconstructed composite cross-shop constraint (see migration 001).

## Monetary definitions

- Customer balance = sum(`credit`) - sum(`payment`), all time.
- Supplier payable = sum(`purchase`) - sum(`payment`), all time.
- Period activity refers to customer credit and payment transactions within
  the date boundaries. It must not be misrepresented as finalized retail sales.
- Inventory cost valuation = sum(stock_quantity × purchase_price).
- Database aggregation uses PostgreSQL `numeric` and runs behind RLS.
- Client formatting converts values to Dart `double`; for very high financial
  precision, a future migration to integer minor units / decimal models is
  recommended before regulated accounting use.

## State synchronization

Realtime subscriptions are scoped to a signed-in shop ID and route/controller
lifecycle. Live events cause repository reloads; no optimistic user balance is
invented while the network is offline. Reports use an aggregation RPC rather
than downloading all rows to compute financial totals in Flutter.

## PDF services

PDF preview uses `printing`; file sharing uses `share_plus` and `path_provider`.
Customer statements, transaction receipts, supplier statements, and financial
reports have independent rendering paths. Native platform setup and language
font rendering must be checked on real devices before release.
