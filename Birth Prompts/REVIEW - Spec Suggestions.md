# Spec Review — Suggestions Before Building

_Review of the Birth Prompts, 2026-09-30. Items are ordered most important first. Tick items off as they are resolved (update the relevant PROMPT file, or note the decision next to the item)._

---

## 1. Contradictions that would cause bugs

- [ ] **1. The Change Category flow gets blocked by duplicate protection.**
  In the file-import grid, "Change Category" re-parses the file through the backend. But parsing stores the file's checksum in `pastImports`, so the second parse is rejected as "File data already imported".
  _Files:_ GUI - Import - File, BACKEND - File Import

- [ ] **2. Parsing permanently changes data before the user confirms anything.**
  Parse saves the checksum, creates new providers and instruments, and saves AI-chosen categories. If the user closes the grid without saving, they can never import that file again, and the settings are already changed.
  _Suggestion:_ make parse a preview with no side effects. Write the checksum, providers, instruments and categories only when the user clicks "Save Successful Rows".
  _Files:_ BACKEND - File Import, BACKEND - External Data Provider

- [ ] **3. Duplicate protection misses the common case.**
  The file checksum only catches the exact same file. The Duplicates group only finds duplicates inside that one file. Overlapping statements (a March file and a Q1 file) or a bank import over a date range already imported will create duplicates. The bank-import mnemonic includes a timestamp, so its checksum never matches either.
  _Suggestion:_ give each transaction a fingerprint and check it against expenses already stored. For bank data, use `entry_reference`/`transaction_id`; for files, use a hash of date, amount, merchant and instrument.
  _Files:_ BACKEND - File Import, BACKEND - External Data Provider, GUI - Import - File

- [ ] **4. Category has two sources of truth.**
  Each expense stores its own `category`, but the merchant-to-category mapping lives in settings, and the GUI says "Changing this will affect both existing and new data". Decide whether an expense's category is looked up from the merchant at read time or copied onto the expense. If it's copied, every mapping change has to update the stored expenses too.
  _Files:_ BACKEND - Model, GUI - Settings - Categorization, GUI - Management

- [ ] **5. Renaming an instrument key orphans old expenses.**
  Expenses reference instruments by `key`, and changing the key "affects only new data", so existing expenses point at a key that no longer exists. The same applies to names used as keys for categories and groups.
  _Suggestion:_ use stable internal IDs and keep names purely for display.
  _Files:_ BACKEND - Model, GUI - Settings - Instruments

- [ ] **6. A crash can leave reports broken for good.**
  The `isLoading` flags are stored in the database. If the process dies mid-sync, the flag stays `true`, and every Reports call keeps throwing.
  _Suggestion:_ replace the flag with a lease (a start time plus a timeout).
  _Files:_ BACKEND, BACKEND - Aggregated Data, BACKEND - Model

- [ ] **7. The currency lists disagree.**
  Instruments allow CHF and EUR, the country list is Switzerland and Greece, but the file-import prompt shows every currency from Frankfurter. Pick one list.
  _Files:_ GUI - Settings - Instruments, GUI - Settings, GUI - Import - File

---

## 2. Money and bank data correctness

- [ ] **8. Amounts.**
  Store them as integer cents or a decimal type, never floats. Also define the sign rule. Bank transactions carry `credit_debit_indicator`, and without it salary and refunds count as spending. The same goes for pending versus booked transactions: probably import booked (`BOOK`) only.
  _Files:_ BACKEND - Model, BACKEND - External Data Provider

- [ ] **9. The predefined EnableBanking mappings look wrong (verify).**
  I believe `creditor_account` has no `name` field; that is on `creditor`. For card payments, the merchant is often only in `remittance_information`. Also, `debtor_account` is only the user's own account for outgoing payments. Check these against the Transaction schema: https://enablebanking.com/docs/api/reference/#transaction
  _Files:_ GUI - Settings - External Data Providers

- [ ] **10. Historical rates have gaps.**
  Frankfurter/ECB publishes no rates on weekends or holidays, so conversion needs a fallback to the nearest earlier date. Also, step 6 only compares the overall min/max dates, which won't catch newly added currencies or gaps in the middle of the range.
  _Files:_ BACKEND (Syncing Historical rates), BACKEND - Aggregated Data

- [ ] **11. Sum loses the cents.**
  The Manage page's Sum uses `aggregatedData`, which rounds to an integer. Either return decimals or add a separate exact-sum call.
  _Files:_ GUI - Management, BACKEND - Aggregated Data

- [ ] **12. Merchant names need normalising.**
  Bank strings like `AMAZON*1X2Y3 LUX` vary per transaction. With exact-match merchant lists, categorisation stays manual forever.
  _Suggestion:_ add a normalisation step, or pattern rules such as prefix or regex matching.
  _Files:_ BACKEND - Model, BACKEND - File Import, GUI - Settings - Categorization

---

## 3. Security

- [ ] **13. "No auth" on a home network is risky here.**
  The app holds bank sessions, a private key and financial history, and it exposes a Reset endpoint. Anyone on the Wi-Fi, including guests, can use it. Any website the user visits can also POST to `http://192.168.x.x/reset` through the browser (a CSRF attack).
  _Suggestion:_ at minimum, one shared password or PIN, strict CORS, and CSRF protection on write calls.
  _Files:_ PROMPT (Non Functionals)

- [ ] **14. An embedded encryption key protects nothing.**
  If the export key ships with the code, anyone with the code can decrypt every backup.
  _Suggestion:_ derive the key from a passphrase the user enters instead (for example, AES-GCM with a key derived via Argon2 or PBKDF2).
  _Files:_ BACKEND (Export/Import), GUI - Settings (Bulk Data Operations)

- [ ] **15. Secrets leak through the settings API.**
  Settings CRUD returns the AI key and the EnableBanking private key to the browser.
  _Suggestion:_ make them write-only: return a masked value or just a "set" flag.
  _Files:_ BACKEND, GUI - Settings, GUI - Settings - External Data Providers

- [ ] **16. Sanitising prompts won't stop injection.**
  The real protection for AI search is to have the model output a filter matching a fixed JSON schema, validated against allowed fields and operators, and never raw SQL or GraphQL. Only the schema should go to the model, never data. Bank merchant names sent for categorisation are also untrusted input (indirect injection), so treat them as data in structured output.
  _Files:_ BACKEND - Search, BACKEND - File Import

- [ ] **17. Check the EnableBanking redirect URL.**
  It has to be registered in the EnableBanking app and may need HTTPS. A LAN address like `http://expensor.local` may not be accepted, so confirm this before designing the hosting setup.
  _Files:_ PROMPT (Hosting), GUI (Callback Page)

---

## 4. AI cost (the spec says this should be first class)

- [ ] **18. External aggregated data could mean thousands of calls.**
  One call per month × category × profile is roughly 120 × 20 × 2 = **~4,800 calls** for 10 years.
  _Suggestion:_ send one call per profile per year that returns a JSON table, use the Batch API (50% off), use Haiku, and add a per-run budget cap. Also label these values in the UI as AI estimates: the model will largely make up plausible numbers, not look them up.
  _Files:_ BACKEND - Aggregated Data, GUI - Reports

- [ ] **19. Import categorisation should be batched.**
  Send the unique uncategorised merchants in one call, not one call per row.
  _Files:_ BACKEND - File Import

- [ ] **20. Make the model configurable.**
  Store a model ID alongside the `CLAUDE` enum, defaulting to Haiku 4.5 for categorisation and search. Log token usage per feature and show it in Settings.
  _Files:_ BACKEND - Model, GUI - Settings (AI Source)

---

## 5. Scope and build practicality

- [ ] **21. Settings as one JSON document won't scale well.**
  It holds merchant lists, past imports and instruments, and many fields autosave on blur. Two open tabs will overwrite each other's changes.
  _Suggestion:_ store settings as normalised tables and expose smaller PATCH endpoints, while keeping the JSON shape as the API view if you like.
  _Files:_ BACKEND - Model, BACKEND (Settings)

- [ ] **22. Drop the "materialized search facade".**
  120k rows is tiny; SQLite or Postgres with a few indexes is enough. I'd pick SQLite (WAL mode) for a home setup, or Postgres if you prefer it in containers.
  _Files:_ BACKEND - Search, PROMPT (Persistence)

- [ ] **23. Allow some non-e2e tests.**
  Column inference, date-format detection and file-name regex generation are best covered by table-driven tests against the backend. Browser tests would be slow and flaky for these. Splitting a fast smoke suite from a full suite also resolves the tension between "the pipeline should be fast" and "e2e everything".
  _Files:_ PROMPT (Non Functionals, CI)

- [ ] **24. Hot reload in Docker on Windows.**
  It needs file polling (`usePolling` in Vite, and in the backend's file watcher) or the code kept inside WSL2. Otherwise changes aren't picked up.
  _Files:_ PROMPT (Deployment)

- [ ] **25. Simplify the setup for a non-technical user.**
  One `docker compose`, with the backend serving the built frontend (a single container in production), an mDNS name like `expensor.local`, and a start/stop script. Docker Desktop itself is the hardest step for such a user, so the instructions should cover it.
  _Files:_ PROMPT (Deployment, Hosting)

---

## Minor

- [ ] The Reports "Last" period is defined as "the one before the current". Confirm that, since it can conflict with the default of "1 (current month)". _(GUI - Reports)_
- [ ] The Sum filter selects by `id`, but the filter spec reads as field filters on the expense model. Allow `id` explicitly. _(GUI - Management, BACKEND - Aggregated Data)_
