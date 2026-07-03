# Enterprise Finance & General Ledger Firestore Schema

## Core Principles
* **True Dual-Entry:** Every transaction results in at least two ledger entries (debit and credit) that must balance to zero.
* **Immutability:** Posted transactions cannot be deleted or modified. Corrections require a reversing entry.
* **Auditability:** Complete track record of who created, approved, and posted entries, with timestamps.
* **Multi-Currency:** Support for base currency, transaction currency, and reporting currencies, with historical exchange rates.
* **Scalability:** Firestore sub-collections are used for unbounded data (like journal lines) while keeping the root level clean.

## Global Configurations & Master Data

### Collection: `fin_chart_of_accounts`
Defines the chart of accounts (COA) for the enterprise.

* **Document ID:** `{account_id}` (e.g., `1000-Cash`)
* **Fields:**
    * `account_number` (String): e.g., "1000"
    * `name` (String): e.g., "Petty Cash"
    * `type` (String): "ASSET", "LIABILITY", "EQUITY", "REVENUE", "EXPENSE"
    * `sub_type` (String): e.g., "CURRENT_ASSET", "LONG_TERM_LIABILITY"
    * `is_active` (Boolean): true
    * `is_reconciliation_account` (Boolean): false (true for AR/AP control accounts)
    * `currency_code` (String): Default currency for the account (null if multi-currency)
    * `financial_statement_group` (String): e.g., "Balance Sheet - Cash & Equivalents"
    * `created_at` (Timestamp)
    * `updated_at` (Timestamp)
    * `updated_by` (String)

### Collection: `fin_currencies`
Supported currencies for multi-currency operations.

* **Document ID:** `{currency_code}` (e.g., `USD`)
* **Fields:**
    * `name` (String): "US Dollar"
    * `symbol` (String): "$"
    * `decimals` (Number): 2
    * `is_active` (Boolean): true

### Collection: `fin_exchange_rates`
Historical exchange rates between currencies.

* **Document ID:** `{from_currency}_{to_currency}_{date_YYYYMMDD}`
* **Fields:**
    * `from_currency` (String): "EUR"
    * `to_currency` (String): "USD"
    * `date` (Timestamp): 00:00:00 UTC of the day
    * `rate_type` (String): "SPOT", "AVERAGE", "CLOSING"
    * `rate` (Number): 1.1254 (stored as precise decimal/double or scaled integer)
    * `source` (String): "ECB", "Reuters"
    * `created_at` (Timestamp)

### Collection: `fin_fiscal_calendars`
Fiscal years and periods.

* **Document ID:** `{fiscal_year_id}` (e.g., `FY-2026`)
* **Fields:**
    * `year_name` (String): "2026"
    * `start_date` (Timestamp)
    * `end_date` (Timestamp)
    * `status` (String): "OPEN", "CLOSING", "CLOSED"

    #### Sub-collection: `periods`
    * **Document ID:** `{period_number}` (e.g., `01`)
    * **Fields:**
        * `period_name` (String): "January 2026"
        * `start_date` (Timestamp)
        * `end_date` (Timestamp)
        * `status` (String): "OPEN", "CLOSED"
        * `ap_status` (String): "OPEN", "CLOSED"
        * `ar_status` (String): "OPEN", "CLOSED"

## General Ledger (GL)

### Collection: `fin_journal_headers`
The header for a dual-entry journal entry.

* **Document ID:** `{journal_entry_id}` (e.g., `JE-202607-000123`)
* **Fields:**
    * `transaction_date` (Timestamp): The accounting date.
    * `system_date` (Timestamp): The date it was actually recorded.
    * `fiscal_year` (String): "FY-2026"
    * `fiscal_period` (String): "07"
    * `source_module` (String): "GL", "AP", "AR", "FA" (Fixed Assets)
    * `source_reference_id` (String): Reference to AP Invoice or AR Receipt.
    * `type` (String): "STANDARD", "ACCRUAL", "REVERSAL", "ADJUSTMENT"
    * `description` (String): e.g., "Monthly Rent Accrual"
    * `status` (String): "DRAFT", "PENDING_APPROVAL", "APPROVED", "POSTED", "REVERSED", "REJECTED"
    * `currency_code` (String): Transaction currency.
    * `base_currency_code` (String): The enterprise base reporting currency.
    * `exchange_rate` (Number): Rate applied at `transaction_date`.
    * `total_debit` (Number): Sum of debit lines (transaction currency).
    * `total_credit` (Number): Sum of credit lines (transaction currency).
    * `base_total_debit` (Number): Sum of debit lines (base currency).
    * `base_total_credit` (Number): Sum of credit lines (base currency).
    * `created_by` (String)
    * `approved_by` (String)
    * `posted_at` (Timestamp)
    * `reverses_journal_id` (String): If this is a reversal, the ID of the original JE.

    #### Sub-collection: `lines`
    The individual debit and credit entries. A journal header must have at least 2 lines, and `sum(debit) == sum(credit)`.
    * **Document ID:** `{line_number}` (e.g., `1`, `2`)
    * **Fields:**
        * `account_id` (String): Foreign key to `fin_chart_of_accounts`.
        * `cost_center_id` (String): For departmental tracking.
        * `project_id` (String): For project accounting.
        * `debit_amount` (Number): Transaction currency.
        * `credit_amount` (Number): Transaction currency.
        * `base_debit_amount` (Number): Base currency.
        * `base_credit_amount` (Number): Base currency.
        * `description` (String): Line-level memo.
        * `tax_code_id` (String): Optional reference to `fin_tax_codes`.

### Collection: `fin_ledger_balances`
A materialized view/aggregate collection for fast financial reporting (Trial Balance, P&L). Updated via trigger.

* **Document ID:** `{account_id}_{fiscal_year}_{fiscal_period}`
* **Fields:**
    * `account_id` (String)
    * `fiscal_year` (String)
    * `fiscal_period` (String)
    * `opening_balance` (Number)
    * `period_debit` (Number)
    * `period_credit` (Number)
    * `closing_balance` (Number)
    * `currency_code` (String)

## Accounts Payable (AP)

### Collection: `fin_vendors`
Suppliers and vendors.

* **Document ID:** `{vendor_id}`
* **Fields:**
    * `vendor_name` (String)
    * `vendor_type` (String): "GOODS", "SERVICES", "CONTRACTOR"
    * `tax_id` (String)
    * `default_currency` (String)
    * `payment_terms_id` (String)
    * `ap_control_account_id` (String): The specific liability account used.
    * `status` (String): "ACTIVE", "INACTIVE", "ON_HOLD"
    * `contact_email` (String)
    * `contact_phone` (String)
    * `bank_routing_number` (String)
    * `bank_account_number` (String)

### Collection: `fin_ap_invoices`
Vendor invoices received.

* **Document ID:** `{invoice_id}`
* **Fields:**
    * `vendor_id` (String)
    * `invoice_number` (String): Vendor's invoice number.
    * `invoice_date` (Timestamp)
    * `due_date` (Timestamp)
    * `status` (String): "DRAFT", "PENDING_APPROVAL", "APPROVED", "PARTIALLY_PAID", "PAID", "VOID"
    * `currency_code` (String)
    * `gross_amount` (Number)
    * `tax_amount` (Number)
    * `net_amount` (Number)
    * `amount_paid` (Number)
    * `journal_entry_id` (String): Link to the GL posting.
    * `purchase_order_id` (String): Link to Procurement module.

    #### Sub-collection: `lines`
    * **Document ID:** `{line_id}`
    * **Fields:**
        * `expense_account_id` (String)
        * `amount` (Number)
        * `tax_code_id` (String)
        * `tax_amount` (Number)
        * `description` (String)
        * `cost_center_id` (String)

### Collection: `fin_ap_payments`
Payments made to vendors.

* **Document ID:** `{payment_id}`
* **Fields:**
    * `vendor_id` (String)
    * `payment_date` (Timestamp)
    * `payment_method` (String): "ACH", "WIRE", "CHECK", "CREDIT_CARD"
    * `amount` (Number)
    * `currency_code` (String)
    * `bank_account_id` (String): Source of funds.
    * `status` (String): "INITIATED", "CLEARED", "FAILED", "VOID"
    * `journal_entry_id` (String)

    #### Sub-collection: `applications`
    Mapping payment amounts to specific AP invoices.
    * **Document ID:** `{application_id}`
    * **Fields:**
        * `invoice_id` (String)
        * `applied_amount` (Number)

## Accounts Receivable (AR)

### Collection: `fin_customers`
Clients and customers.

* **Document ID:** `{customer_id}`
* **Fields:**
    * `customer_name` (String)
    * `tax_id` (String)
    * `default_currency` (String)
    * `payment_terms_id` (String)
    * `ar_control_account_id` (String)
    * `credit_limit` (Number)
    * `status` (String): "ACTIVE", "ON_HOLD", "COLLECTIONS"

### Collection: `fin_ar_invoices`
Invoices issued to customers.

* **Document ID:** `{invoice_id}`
* **Fields:**
    * `customer_id` (String)
    * `invoice_date` (Timestamp)
    * `due_date` (Timestamp)
    * `status` (String): "DRAFT", "ISSUED", "PARTIALLY_PAID", "PAID", "WRITTEN_OFF"
    * `currency_code` (String)
    * `gross_amount` (Number)
    * `tax_amount` (Number)
    * `net_amount` (Number)
    * `amount_received` (Number)
    * `journal_entry_id` (String)

    #### Sub-collection: `lines`
    * **Document ID:** `{line_id}`
    * **Fields:**
        * `revenue_account_id` (String)
        * `product_id` (String)
        * `quantity` (Number)
        * `unit_price` (Number)
        * `amount` (Number)
        * `tax_code_id` (String)
        * `tax_amount` (Number)

### Collection: `fin_ar_receipts`
Money received from customers.

* **Document ID:** `{receipt_id}`
* **Fields:**
    * `customer_id` (String)
    * `receipt_date` (Timestamp)
    * `payment_method` (String)
    * `amount` (Number)
    * `currency_code` (String)
    * `bank_account_id` (String): Destination of funds.
    * `unapplied_amount` (Number)
    * `status` (String): "RECEIVED", "CLEARED", "BOUNCED"
    * `journal_entry_id` (String)

    #### Sub-collection: `applications`
    * **Document ID:** `{application_id}`
    * **Fields:**
        * `invoice_id` (String)
        * `applied_amount` (Number)

## Tax Engine

### Collection: `fin_tax_jurisdictions`
Countries, states, or regions for tax purposes.

* **Document ID:** `{jurisdiction_id}`
* **Fields:**
    * `name` (String): e.g., "California State", "Germany Federal"
    * `country_code` (String)
    * `type` (String): "COUNTRY", "STATE", "COUNTY", "CITY"

### Collection: `fin_tax_codes`
Specific tax rules applied to transactions.

* **Document ID:** `{tax_code_id}`
* **Fields:**
    * `code` (String): e.g., "VAT-GER-19"
    * `jurisdiction_id` (String)
    * `name` (String): "German VAT Standard Rate 19%"
    * `tax_type` (String): "SALES", "USE", "VAT", "GST", "WITHHOLDING"
    * `rate` (Number): 0.19
    * `gl_liability_account_id` (String): Account to credit for collected tax.
    * `gl_receivable_account_id` (String): Account to debit for paid tax (if recoverable).
    * `effective_from` (Timestamp)
    * `effective_to` (Timestamp)
    * `is_active` (Boolean)

### Collection: `fin_tax_transactions`
Auditable log of every tax event calculated across the system.

* **Document ID:** `{tax_trans_id}`
* **Fields:**
    * `source_module` (String): "AP", "AR"
    * `source_document_id` (String): e.g., an Invoice ID
    * `source_line_id` (String)
    * `tax_code_id` (String)
    * `jurisdiction_id` (String)
    * `tax_date` (Timestamp)
    * `taxable_base_amount` (Number)
    * `calculated_tax_amount` (Number)
    * `currency_code` (String)

## Recommended Indexes

### Collection Group Indexes
* **`lines` (Journal Lines):**
  * `account_id` (ASC), `cost_center_id` (ASC)
  * `account_id` (ASC), `project_id` (ASC)
* **`applications` (Payment/Receipt Applications):**
  * `invoice_id` (ASC)

### Single Collection Indexes
* **`fin_journal_headers`:**
  * `status` (ASC), `transaction_date` (DESC)
  * `fiscal_year` (ASC), `fiscal_period` (ASC), `status` (ASC)
  * `source_reference_id` (ASC)
* **`fin_ap_invoices` / `fin_ar_invoices`:**
  * `vendor_id` / `customer_id` (ASC), `status` (ASC), `due_date` (ASC)
* **`fin_exchange_rates`:**
  * `from_currency` (ASC), `to_currency` (ASC), `date` (DESC)
* **`fin_tax_transactions`:**
  * `jurisdiction_id` (ASC), `tax_date` (ASC)
