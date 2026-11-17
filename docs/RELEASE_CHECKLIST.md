# DigiKhata production release checklist

Do **not** launch a commercial shop accounting system until every applicable
check is completed against your own development and staging environments.

## Database and security

- [ ] Back up Supabase tables, policies and Auth settings.
- [ ] Apply all six migrations in numerical order on STAGING and review each output.
- [ ] Run `supabase/verify.sql`; ensure cross-shop mismatch counts are zero.
- [ ] Audit all existing RLS policies, including policies created before these scripts.
- [ ] Confirm user A cannot read, insert, update or delete user B's customers,
      supplier records, transactions, or inventory — including direct REST calls.
- [ ] Verify product stock cannot be changed except through stock RPC.
- [ ] Verify ledger audit rows cannot be edited/deleted by authenticated clients.
- [ ] Validate unvalidated foreign keys after confirming existing data integrity.
- [ ] Enable and test Supabase Realtime on the specified tables.
- [ ] Confirm staging and production backup/restore procedures and recovery time.

## Source and devices

- [ ] Run `flutter pub get` with the pinned lockfile and compatible Flutter SDK.
- [ ] Run `dart format lib test`, `flutter analyze`, `flutter test`.
- [ ] Test Android and iOS builds against their native platform projects.
- [ ] Test login, registration, email confirmation, recovery deep links, sign out.
- [ ] Test two separate shop accounts for data isolation.
- [ ] Test customer and supplier Udhar/Jama and edit/delete account reconciliation.
- [ ] Test customer and supplier PDFs, printing and sharing on physical devices.
- [ ] Test several thousand transactions and confirm no silent 1,000-row truncation.
- [ ] Test concurrent stock adjustments from two devices; quantities never negative.
- [ ] Test live updates on a second device and refresh after reconnection.
- [ ] Test slow/offline networks, screen rotations, narrow phones, and tablets.
- [ ] Verify all Urdu strings, date/amount formatting, and Urdu PDF fonts.
- [ ] Review accessibility, contrast, font scaling, and error-state wording.

## Commercial decisions

- [ ] Decide on formal sales/invoice itemization and automated inventory deduction.
- [ ] Document accounting treatment of customer/supplier advances and refunds.
- [ ] Review taxes/invoice requirements for jurisdictions in which the app operates.
- [ ] Establish data retention, dispute handling, audit review and privacy policy.
- [ ] Configure Android/iOS permissions, deep links, signing and store distribution.
- [ ] Review app telemetry without logging customer financial or private credentials.
