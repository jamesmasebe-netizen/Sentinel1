import 'package:cloud_firestore/cloud_firestore.dart';

// 1. GeneralLedgerAccount
class GeneralLedgerAccount {
  final String id; // account_id
  final String accountNumber;
  final String name;
  final String type; // "ASSET", "LIABILITY", "EQUITY", "REVENUE", "EXPENSE"
  final String? subType;
  final bool isActive;
  final bool isReconciliationAccount;
  final String? currencyCode;
  final String? financialStatementGroup;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final String? updatedBy;

  GeneralLedgerAccount({
    required this.id,
    required this.accountNumber,
    required this.name,
    required this.type,
    this.subType,
    required this.isActive,
    required this.isReconciliationAccount,
    this.currencyCode,
    this.financialStatementGroup,
    this.createdAt,
    this.updatedAt,
    this.updatedBy,
  });

  factory GeneralLedgerAccount.fromJson(Map<String, dynamic> json, String id) {
    return GeneralLedgerAccount(
      id: id,
      accountNumber: json['account_number'] ?? '',
      name: json['name'] ?? '',
      type: json['type'] ?? '',
      subType: json['sub_type'],
      isActive: json['is_active'] ?? true,
      isReconciliationAccount: json['is_reconciliation_account'] ?? false,
      currencyCode: json['currency_code'],
      financialStatementGroup: json['financial_statement_group'],
      createdAt: (json['created_at'] as Timestamp?)?.toDate(),
      updatedAt: (json['updated_at'] as Timestamp?)?.toDate(),
      updatedBy: json['updated_by'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'account_number': accountNumber,
      'name': name,
      'type': type,
      if (subType != null) 'sub_type': subType,
      'is_active': isActive,
      'is_reconciliation_account': isReconciliationAccount,
      if (currencyCode != null) 'currency_code': currencyCode,
      if (financialStatementGroup != null)
        'financial_statement_group': financialStatementGroup,
      if (createdAt != null) 'created_at': Timestamp.fromDate(createdAt!),
      if (updatedAt != null) 'updated_at': Timestamp.fromDate(updatedAt!),
      if (updatedBy != null) 'updated_by': updatedBy,
    };
  }
}

// 2. JournalEntry
class JournalEntry {
  final String id; // journal_entry_id
  final DateTime transactionDate;
  final DateTime? systemDate;
  final String? fiscalYear;
  final String? fiscalPeriod;
  final String sourceModule; // "GL", "AP", "AR", "FA"
  final String? sourceReferenceId;
  final String type; // "STANDARD", "ACCRUAL", "REVERSAL", "ADJUSTMENT"
  final String description;
  final String
  status; // "DRAFT", "PENDING_APPROVAL", "APPROVED", "POSTED", "REVERSED", "REJECTED"
  final String currencyCode;
  final String? baseCurrencyCode;
  final double? exchangeRate;
  final double totalDebit;
  final double totalCredit;
  final double? baseTotalDebit;
  final double? baseTotalCredit;
  final String? createdBy;
  final String? approvedBy;
  final DateTime? postedAt;
  final String? reversesJournalId;

  JournalEntry({
    required this.id,
    required this.transactionDate,
    this.systemDate,
    this.fiscalYear,
    this.fiscalPeriod,
    required this.sourceModule,
    this.sourceReferenceId,
    required this.type,
    required this.description,
    required this.status,
    required this.currencyCode,
    this.baseCurrencyCode,
    this.exchangeRate,
    required this.totalDebit,
    required this.totalCredit,
    this.baseTotalDebit,
    this.baseTotalCredit,
    this.createdBy,
    this.approvedBy,
    this.postedAt,
    this.reversesJournalId,
  });

  factory JournalEntry.fromJson(Map<String, dynamic> json, String id) {
    return JournalEntry(
      id: id,
      transactionDate: (json['transaction_date'] as Timestamp).toDate(),
      systemDate: (json['system_date'] as Timestamp?)?.toDate(),
      fiscalYear: json['fiscal_year'],
      fiscalPeriod: json['fiscal_period'],
      sourceModule: json['source_module'] ?? '',
      sourceReferenceId: json['source_reference_id'],
      type: json['type'] ?? '',
      description: json['description'] ?? '',
      status: json['status'] ?? '',
      currencyCode: json['currency_code'] ?? '',
      baseCurrencyCode: json['base_currency_code'],
      exchangeRate: (json['exchange_rate'] as num?)?.toDouble(),
      totalDebit: (json['total_debit'] as num?)?.toDouble() ?? 0.0,
      totalCredit: (json['total_credit'] as num?)?.toDouble() ?? 0.0,
      baseTotalDebit: (json['base_total_debit'] as num?)?.toDouble(),
      baseTotalCredit: (json['base_total_credit'] as num?)?.toDouble(),
      createdBy: json['created_by'],
      approvedBy: json['approved_by'],
      postedAt: (json['posted_at'] as Timestamp?)?.toDate(),
      reversesJournalId: json['reverses_journal_id'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'transaction_date': Timestamp.fromDate(transactionDate),
      if (systemDate != null) 'system_date': Timestamp.fromDate(systemDate!),
      if (fiscalYear != null) 'fiscal_year': fiscalYear,
      if (fiscalPeriod != null) 'fiscal_period': fiscalPeriod,
      'source_module': sourceModule,
      if (sourceReferenceId != null) 'source_reference_id': sourceReferenceId,
      'type': type,
      'description': description,
      'status': status,
      'currency_code': currencyCode,
      if (baseCurrencyCode != null) 'base_currency_code': baseCurrencyCode,
      if (exchangeRate != null) 'exchange_rate': exchangeRate,
      'total_debit': totalDebit,
      'total_credit': totalCredit,
      if (baseTotalDebit != null) 'base_total_debit': baseTotalDebit,
      if (baseTotalCredit != null) 'base_total_credit': baseTotalCredit,
      if (createdBy != null) 'created_by': createdBy,
      if (approvedBy != null) 'approved_by': approvedBy,
      if (postedAt != null) 'posted_at': Timestamp.fromDate(postedAt!),
      if (reversesJournalId != null) 'reverses_journal_id': reversesJournalId,
    };
  }
}

// 3. JournalLine
class JournalLine {
  final String id; // line_number
  final String accountId;
  final String? costCenterId;
  final String? projectId;
  final double debitAmount;
  final double creditAmount;
  final double? baseDebitAmount;
  final double? baseCreditAmount;
  final String? description;
  final String? taxCodeId;

  JournalLine({
    required this.id,
    required this.accountId,
    this.costCenterId,
    this.projectId,
    required this.debitAmount,
    required this.creditAmount,
    this.baseDebitAmount,
    this.baseCreditAmount,
    this.description,
    this.taxCodeId,
  });

  factory JournalLine.fromJson(Map<String, dynamic> json, String id) {
    return JournalLine(
      id: id,
      accountId: json['account_id'] ?? '',
      costCenterId: json['cost_center_id'],
      projectId: json['project_id'],
      debitAmount: (json['debit_amount'] as num?)?.toDouble() ?? 0.0,
      creditAmount: (json['credit_amount'] as num?)?.toDouble() ?? 0.0,
      baseDebitAmount: (json['base_debit_amount'] as num?)?.toDouble(),
      baseCreditAmount: (json['base_credit_amount'] as num?)?.toDouble(),
      description: json['description'],
      taxCodeId: json['tax_code_id'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'account_id': accountId,
      if (costCenterId != null) 'cost_center_id': costCenterId,
      if (projectId != null) 'project_id': projectId,
      'debit_amount': debitAmount,
      'credit_amount': creditAmount,
      if (baseDebitAmount != null) 'base_debit_amount': baseDebitAmount,
      if (baseCreditAmount != null) 'base_credit_amount': baseCreditAmount,
      if (description != null) 'description': description,
      if (taxCodeId != null) 'tax_code_id': taxCodeId,
    };
  }
}

// 4. Invoice (AP or AR)
class Invoice {
  final String id;
  final String invoiceType; // "AP" or "AR"
  final String? vendorId;
  final String? customerId;
  final String? invoiceNumber;
  final DateTime invoiceDate;
  final DateTime dueDate;
  final String status;
  final String currencyCode;
  final double grossAmount;
  final double taxAmount;
  final double netAmount;
  final double? amountPaidOrReceived;
  final String? journalEntryId;

  Invoice({
    required this.id,
    required this.invoiceType,
    this.vendorId,
    this.customerId,
    this.invoiceNumber,
    required this.invoiceDate,
    required this.dueDate,
    required this.status,
    required this.currencyCode,
    required this.grossAmount,
    required this.taxAmount,
    required this.netAmount,
    this.amountPaidOrReceived,
    this.journalEntryId,
  });

  factory Invoice.fromJson(
    Map<String, dynamic> json,
    String id, {
    required String type,
  }) {
    return Invoice(
      id: id,
      invoiceType: type,
      vendorId: json['vendor_id'],
      customerId: json['customer_id'],
      invoiceNumber: json['invoice_number'],
      invoiceDate: (json['invoice_date'] as Timestamp).toDate(),
      dueDate: (json['due_date'] as Timestamp).toDate(),
      status: json['status'] ?? '',
      currencyCode: json['currency_code'] ?? '',
      grossAmount: (json['gross_amount'] as num?)?.toDouble() ?? 0.0,
      taxAmount: (json['tax_amount'] as num?)?.toDouble() ?? 0.0,
      netAmount: (json['net_amount'] as num?)?.toDouble() ?? 0.0,
      amountPaidOrReceived:
          (json['amount_paid'] as num?)?.toDouble() ??
          (json['amount_received'] as num?)?.toDouble(),
      journalEntryId: json['journal_entry_id'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (vendorId != null) 'vendor_id': vendorId,
      if (customerId != null) 'customer_id': customerId,
      if (invoiceNumber != null) 'invoice_number': invoiceNumber,
      'invoice_date': Timestamp.fromDate(invoiceDate),
      'due_date': Timestamp.fromDate(dueDate),
      'status': status,
      'currency_code': currencyCode,
      'gross_amount': grossAmount,
      'tax_amount': taxAmount,
      'net_amount': netAmount,
      if (amountPaidOrReceived != null)
        (invoiceType == 'AP' ? 'amount_paid' : 'amount_received'):
            amountPaidOrReceived,
      if (journalEntryId != null) 'journal_entry_id': journalEntryId,
    };
  }
}

// 5. TaxCode
class TaxCode {
  final String id;
  final String code;
  final String jurisdictionId;
  final String name;
  final String taxType; // "SALES", "USE", "VAT", "GST", "WITHHOLDING"
  final double rate;
  final String? glLiabilityAccountId;
  final String? glReceivableAccountId;
  final DateTime? effectiveFrom;
  final DateTime? effectiveTo;
  final bool isActive;

  TaxCode({
    required this.id,
    required this.code,
    required this.jurisdictionId,
    required this.name,
    required this.taxType,
    required this.rate,
    this.glLiabilityAccountId,
    this.glReceivableAccountId,
    this.effectiveFrom,
    this.effectiveTo,
    required this.isActive,
  });

  factory TaxCode.fromJson(Map<String, dynamic> json, String id) {
    return TaxCode(
      id: id,
      code: json['code'] ?? '',
      jurisdictionId: json['jurisdiction_id'] ?? '',
      name: json['name'] ?? '',
      taxType: json['tax_type'] ?? '',
      rate: (json['rate'] as num?)?.toDouble() ?? 0.0,
      glLiabilityAccountId: json['gl_liability_account_id'],
      glReceivableAccountId: json['gl_receivable_account_id'],
      effectiveFrom: (json['effective_from'] as Timestamp?)?.toDate(),
      effectiveTo: (json['effective_to'] as Timestamp?)?.toDate(),
      isActive: json['is_active'] ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'code': code,
      'jurisdiction_id': jurisdictionId,
      'name': name,
      'tax_type': taxType,
      'rate': rate,
      if (glLiabilityAccountId != null)
        'gl_liability_account_id': glLiabilityAccountId,
      if (glReceivableAccountId != null)
        'gl_receivable_account_id': glReceivableAccountId,
      if (effectiveFrom != null)
        'effective_from': Timestamp.fromDate(effectiveFrom!),
      if (effectiveTo != null) 'effective_to': Timestamp.fromDate(effectiveTo!),
      'is_active': isActive,
    };
  }
}

// 6. BudgetPlan
class BudgetPlan {
  final String id;
  final String name;
  final String fiscalYear;
  final String fiscalPeriod;
  final String? departmentId;
  final String? costCenterId;
  final String? glAccountId;
  final double plannedAmount;
  final double actualAmount;
  final double variance;
  final double variancePercentage;
  final String status; // "Draft", "Active", "Closed", "Exceeded"
  final String notes;
  final String? createdBy;
  final String? approvedBy;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  BudgetPlan({
    required this.id,
    required this.name,
    required this.fiscalYear,
    required this.fiscalPeriod,
    this.departmentId,
    this.costCenterId,
    this.glAccountId,
    required this.plannedAmount,
    required this.actualAmount,
    required this.variance,
    required this.variancePercentage,
    required this.status,
    required this.notes,
    this.createdBy,
    this.approvedBy,
    this.createdAt,
    this.updatedAt,
  });

  factory BudgetPlan.fromJson(Map<String, dynamic> json, String id) {
    return BudgetPlan(
      id: id,
      name: json['name'] ?? '',
      fiscalYear: json['fiscal_year'] ?? '',
      fiscalPeriod: json['fiscal_period'] ?? '',
      departmentId: json['department_id'],
      costCenterId: json['cost_center_id'],
      glAccountId: json['gl_account_id'],
      plannedAmount: (json['planned_amount'] as num?)?.toDouble() ?? 0.0,
      actualAmount: (json['actual_amount'] as num?)?.toDouble() ?? 0.0,
      variance: (json['variance'] as num?)?.toDouble() ?? 0.0,
      variancePercentage:
          (json['variance_percentage'] as num?)?.toDouble() ?? 0.0,
      status: json['status'] ?? 'Draft',
      notes: json['notes'] ?? '',
      createdBy: json['created_by'],
      approvedBy: json['approved_by'],
      createdAt: (json['created_at'] as Timestamp?)?.toDate(),
      updatedAt: (json['updated_at'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'fiscal_year': fiscalYear,
      'fiscal_period': fiscalPeriod,
      if (departmentId != null) 'department_id': departmentId,
      if (costCenterId != null) 'cost_center_id': costCenterId,
      if (glAccountId != null) 'gl_account_id': glAccountId,
      'planned_amount': plannedAmount,
      'actual_amount': actualAmount,
      'variance': variance,
      'variance_percentage': variancePercentage,
      'status': status,
      'notes': notes,
      if (createdBy != null) 'created_by': createdBy,
      if (approvedBy != null) 'approved_by': approvedBy,
      if (createdAt != null) 'created_at': Timestamp.fromDate(createdAt!),
      if (updatedAt != null) 'updated_at': Timestamp.fromDate(updatedAt!),
    };
  }
}

// 7. CostCenter
class CostCenter {
  final String id;
  final String code;
  final String name;
  final String? departmentId;
  final String? managerId;
  final String? parentCostCenterId;
  final bool isActive;
  final double totalBudget;
  final double totalSpend;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  CostCenter({
    required this.id,
    required this.code,
    required this.name,
    this.departmentId,
    this.managerId,
    this.parentCostCenterId,
    required this.isActive,
    required this.totalBudget,
    required this.totalSpend,
    this.createdAt,
    this.updatedAt,
  });

  factory CostCenter.fromJson(Map<String, dynamic> json, String id) {
    return CostCenter(
      id: id,
      code: json['code'] ?? '',
      name: json['name'] ?? '',
      departmentId: json['department_id'],
      managerId: json['manager_id'],
      parentCostCenterId: json['parent_cost_center_id'],
      isActive: json['is_active'] ?? true,
      totalBudget: (json['total_budget'] as num?)?.toDouble() ?? 0.0,
      totalSpend: (json['total_spend'] as num?)?.toDouble() ?? 0.0,
      createdAt: (json['created_at'] as Timestamp?)?.toDate(),
      updatedAt: (json['updated_at'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'code': code,
      'name': name,
      if (departmentId != null) 'department_id': departmentId,
      if (managerId != null) 'manager_id': managerId,
      if (parentCostCenterId != null)
        'parent_cost_center_id': parentCostCenterId,
      'is_active': isActive,
      'total_budget': totalBudget,
      'total_spend': totalSpend,
      if (createdAt != null) 'created_at': Timestamp.fromDate(createdAt!),
      if (updatedAt != null) 'updated_at': Timestamp.fromDate(updatedAt!),
    };
  }
}
