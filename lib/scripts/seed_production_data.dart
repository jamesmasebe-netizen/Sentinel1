import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:sentinel1/core/utils/tenant_firestore_extension.dart';

Future<void> seedProductionData(FirebaseFirestore firestore) async {
  final batch = firestore.batch();
  const tenantId = 'sentinel-dev';

  DateTime daysAgo(int days) => DateTime.now().subtract(Duration(days: days));
  String iso(int daysAgoVal) => daysAgo(daysAgoVal).toIso8601String();

  debugPrint('--- Seeding CRM ---');
  // CRM - Accounts
  final accounts = <Map<String, dynamic>>[
    {
      'id': 'ACC-001',
      'name': 'Stark Industries',
      'industry': 'Defense',
      'website': 'stark.com',
      'annualRevenue': 50000000.0,
      'employeeCount': 5000,
      'ownerId': 'EMP-001',
      'status': 'Active',
      'relationshipHealth': 'Green',
      'createdAt': iso(100),
      'updatedAt': iso(50),
    },
    {
      'id': 'ACC-002',
      'name': 'Wayne Enterprises',
      'industry': 'Technology',
      'website': 'wayne.com',
      'annualRevenue': 75000000.0,
      'employeeCount': 10000,
      'ownerId': 'EMP-002',
      'status': 'Active',
      'relationshipHealth': 'Yellow',
      'createdAt': iso(80),
      'updatedAt': iso(10),
    },
    {
      'id': 'ACC-003',
      'name': 'Oscorp',
      'industry': 'Biotech',
      'website': 'oscorp.com',
      'annualRevenue': 25000000.0,
      'employeeCount': 3000,
      'ownerId': 'EMP-001',
      'status': 'Prospect',
      'relationshipHealth': 'Red',
      'createdAt': iso(20),
      'updatedAt': iso(5),
    },
  ];
  for (var doc in accounts) {
    batch.set(
      firestore.tenantCollection(tenantId, 'accounts').doc(doc['id']),
      doc,
    );
  }

  // CRM - Contacts
  final contacts = <Map<String, dynamic>>[
    {
      'id': 'CON-001',
      'accountId': 'ACC-001',
      'firstName': 'Tony',
      'lastName': 'Stark',
      'email': 'tony@stark.com',
      'phone': '555-0100',
      'mobile': '555-0101',
      'jobTitle': 'CEO',
      'department': 'Executive',
      'leadSource': 'Trade Show',
      'isPrimary': true,
      'ownerId': 'EMP-001',
      'createdAt': iso(100),
    },
    {
      'id': 'CON-002',
      'accountId': 'ACC-002',
      'firstName': 'Bruce',
      'lastName': 'Wayne',
      'email': 'bruce@wayne.com',
      'phone': '555-0200',
      'mobile': '555-0201',
      'jobTitle': 'CEO',
      'department': 'Executive',
      'leadSource': 'Referral',
      'isPrimary': true,
      'ownerId': 'EMP-002',
      'createdAt': iso(80),
    },
    {
      'id': 'CON-003',
      'accountId': 'ACC-003',
      'firstName': 'Norman',
      'lastName': 'Osborn',
      'email': 'norman@oscorp.com',
      'phone': '555-0300',
      'mobile': '555-0301',
      'jobTitle': 'CEO',
      'department': 'Executive',
      'leadSource': 'Cold Call',
      'isPrimary': true,
      'ownerId': 'EMP-001',
      'createdAt': iso(20),
    },
  ];
  for (var doc in contacts) {
    batch.set(
      firestore.tenantCollection(tenantId, 'contacts').doc(doc['id']),
      doc,
    );
  }

  // CRM - Leads
  final leads = <Map<String, dynamic>>[
    {
      'id': 'LEAD-001',
      'firstName': 'Lex',
      'lastName': 'Luthor',
      'company': 'LexCorp',
      'email': 'lex@lexcorp.com',
      'phone': '555-0400',
      'leadSource': 'Web',
      'status': 'New',
      'rating': 'Hot',
      'aiLeadScore': 95.0,
      'ownerId': 'EMP-001',
      'isConverted': false,
      'createdAt': iso(2),
    },
    {
      'id': 'LEAD-002',
      'firstName': 'Justin',
      'lastName': 'Hammer',
      'company': 'Hammer Industries',
      'email': 'justin@hammer.com',
      'phone': '555-0500',
      'leadSource': 'Trade Show',
      'status': 'Engaged',
      'rating': 'Warm',
      'aiLeadScore': 65.0,
      'ownerId': 'EMP-002',
      'isConverted': false,
      'createdAt': iso(10),
    },
  ];
  for (var doc in leads) {
    batch.set(
      firestore.tenantCollection(tenantId, 'leads').doc(doc['id']),
      doc,
    );
  }

  // CRM - Opportunities
  final opportunities = <Map<String, dynamic>>[
    {
      'id': 'OPP-001',
      'name': 'Arc Reactor Upgrade',
      'accountId': 'ACC-001',
      'primaryContactId': 'CON-001',
      'stage': 'Negotiation',
      'amount': 5000000.0,
      'probability': 80.0,
      'expectedCloseDate': iso(-30),
      'forecastCategory': 'Commit',
      'leadSource': 'Existing Customer',
      'nextStep': 'Send final contract',
      'ownerId': 'EMP-001',
      'createdAt': iso(50),
    },
    {
      'id': 'OPP-002',
      'name': 'Batmobile Fleet Expansion',
      'accountId': 'ACC-002',
      'primaryContactId': 'CON-002',
      'stage': 'Closed Won',
      'amount': 15000000.0,
      'probability': 100.0,
      'expectedCloseDate': iso(5),
      'forecastCategory': 'Closed',
      'leadSource': 'Referral',
      'nextStep': 'Implementation',
      'ownerId': 'EMP-002',
      'createdAt': iso(40),
    },
    {
      'id': 'OPP-003',
      'name': 'Glider R&D',
      'accountId': 'ACC-003',
      'primaryContactId': 'CON-003',
      'stage': 'Discovery',
      'amount': 2500000.0,
      'probability': 20.0,
      'expectedCloseDate': iso(-90),
      'forecastCategory': 'Pipeline',
      'leadSource': 'Cold Call',
      'nextStep': 'Technical Demo',
      'ownerId': 'EMP-001',
      'createdAt': iso(15),
    },
  ];
  for (var doc in opportunities) {
    batch.set(
      firestore.tenantCollection(tenantId, 'opportunities').doc(doc['id']),
      doc,
    );
  }

  // CRM - Deals (Kanban copy of Opportunities)
  final deals = <Map<String, dynamic>>[
    {
      'id': 'OPP-001',
      'title': 'Arc Reactor Upgrade',
      'customerName': 'Stark Industries',
      'value': 5000000.0,
      'stage': 'negotiation',
      'createdAt': iso(50),
    },
    {
      'id': 'OPP-002',
      'title': 'Batmobile Fleet Expansion',
      'customerName': 'Wayne Enterprises',
      'value': 15000000.0,
      'stage': 'closedWon',
      'createdAt': iso(40),
    },
    {
      'id': 'OPP-003',
      'title': 'Glider R&D',
      'customerName': 'Oscorp',
      'value': 2500000.0,
      'stage': 'proposal',
      'createdAt': iso(15),
    },
  ];
  for (var doc in deals) {
    batch.set(
      firestore.tenantCollection(tenantId, 'deals').doc(doc['id']),
      doc,
    );
  }

  // CRM - Quotes
  final quotes = <Map<String, dynamic>>[
    {
      'id': 'QTE-001',
      'opportunityId': 'OPP-001',
      'accountId': 'ACC-001',
      'quoteNumber': 'Q-1001',
      'status': 'Presented',
      'expirationDate': iso(-15),
      'subtotal': 5000000.0,
      'discount': 0.0,
      'tax': 500000.0,
      'grandTotal': 5500000.0,
      'termsAndConditions': 'Net 30',
      'isSyncing': true,
      'ownerId': 'EMP-001',
      'createdAt': iso(10),
    },
    {
      'id': 'QTE-002',
      'opportunityId': 'OPP-002',
      'accountId': 'ACC-002',
      'quoteNumber': 'Q-1002',
      'status': 'Accepted',
      'expirationDate': iso(5),
      'subtotal': 15000000.0,
      'discount': 1000000.0,
      'tax': 1400000.0,
      'grandTotal': 15400000.0,
      'termsAndConditions': 'Net 60',
      'isSyncing': true,
      'ownerId': 'EMP-002',
      'createdAt': iso(20),
    },
  ];
  for (var doc in quotes) {
    batch.set(
      firestore.tenantCollection(tenantId, 'quotes').doc(doc['id']),
      doc,
    );
  }

  // CRM - Campaigns
  final campaigns = <Map<String, dynamic>>[
    {
      'id': 'CAMP-001',
      'name': 'Q3 Defense Expo',
      'type': 'Trade Show',
      'status': 'Active',
      'startDate': iso(10),
      'endDate': iso(-5),
      'budget': 50000.0,
      'actualSpend': 45000.0,
      'targetAudience': 'Defense Contractors',
      'expectedRevenue': 500000.0,
      'actualRevenue': 0.0,
      'ownerId': 'EMP-003',
      'createdAt': iso(15),
    },
    {
      'id': 'CAMP-002',
      'name': 'Biotech Webinar',
      'type': 'Webinar',
      'status': 'Planned',
      'startDate': iso(-10),
      'endDate': iso(-10),
      'budget': 5000.0,
      'actualSpend': 0.0,
      'targetAudience': 'Researchers',
      'expectedRevenue': 100000.0,
      'actualRevenue': 0.0,
      'ownerId': 'EMP-003',
      'createdAt': iso(5),
    },
  ];
  for (var doc in campaigns) {
    batch.set(
      firestore.tenantCollection(tenantId, 'campaigns').doc(doc['id']),
      doc,
    );
  }

  debugPrint('--- Seeding Finance ---');
  // Finance - Budget Plans
  final budgets = <Map<String, dynamic>>[
    {
      'id': 'BP-2026',
      'name': 'FY2026 Corporate Budget',
      'fiscalYear': '2026',
      'fiscalPeriod': 'Q1-Q4',
      'status': 'Approved',
      'plannedAmount': 50000000.0,
      'actualAmount': 15000000.0,
      'variance': 35000000.0,
      'variancePercentage': 70.0,
      'notes': 'Approved',
      'tenantId': tenantId,
    },
    {
      'id': 'BP-2027',
      'name': 'FY2027 Draft Budget',
      'fiscalYear': '2027',
      'fiscalPeriod': 'Q1-Q4',
      'status': 'Draft',
      'plannedAmount': 55000000.0,
      'actualAmount': 0.0,
      'variance': 55000000.0,
      'variancePercentage': 100.0,
      'notes': 'Draft phase',
      'tenantId': tenantId,
    },
  ];
  for (var doc in budgets) {
    batch.set(
      firestore.tenantCollection(tenantId, 'budget_plans').doc(doc['id']),
      doc,
    );
  }

  // Finance - Cost Centers
  final costCenters = <Map<String, dynamic>>[
    {
      'id': 'CC-ENG',
      'name': 'Engineering',
      'code': 'ENG-100',
      'managerId': 'EMP-004',
      'totalBudget': 15000000.0,
      'totalSpend': 4500000.0,
      'isActive': true,
      'tenantId': tenantId,
    },
    {
      'id': 'CC-SAL',
      'name': 'Sales & Marketing',
      'code': 'SAL-200',
      'managerId': 'EMP-001',
      'totalBudget': 10000000.0,
      'totalSpend': 3000000.0,
      'isActive': true,
      'tenantId': tenantId,
    },
  ];
  for (var doc in costCenters) {
    batch.set(
      firestore.tenantCollection(tenantId, 'cost_centers').doc(doc['id']),
      doc,
    );
  }

  // Finance - Invoices
  final invoices = <Map<String, dynamic>>[
    {
      'id': 'INV-001',
      'invoiceNumber': 'INV-26-001',
      'invoiceType': 'AR',
      'customerId': 'ACC-002',
      'vendorId': '',
      'invoiceDate': iso(5),
      'dueDate': iso(-25),
      'status': 'SENT',
      'currencyCode': 'USD',
      'grossAmount': 15000000.0,
      'taxAmount': 1400000.0,
      'netAmount': 16400000.0,
      'tenantId': tenantId,
    },
    {
      'id': 'INV-002',
      'invoiceNumber': 'INV-26-002',
      'invoiceType': 'AP',
      'customerId': '',
      'vendorId': 'VEND-001',
      'invoiceDate': iso(2),
      'dueDate': iso(-28),
      'status': 'DRAFT',
      'currencyCode': 'USD',
      'grossAmount': 50000.0,
      'taxAmount': 5000.0,
      'netAmount': 55000.0,
      'tenantId': tenantId,
    },
  ];
  for (var doc in invoices) {
    batch.set(
      firestore.tenantCollection(tenantId, 'invoices').doc(doc['id']),
      doc,
    );
  }

  // Finance - Chart of Accounts
  final chartOfAccounts = <Map<String, dynamic>>[
    {
      'id': 'COA-1000',
      'accountCode': '1000',
      'name': 'Cash and Cash Equivalents',
      'type': 'Asset',
      'subType': 'Current Asset',
      'currency': 'USD',
      'currentBalance': 5000000.0,
      'isActive': true,
    },
    {
      'id': 'COA-2000',
      'accountCode': '2000',
      'name': 'Accounts Payable',
      'type': 'Liability',
      'subType': 'Current Liability',
      'currency': 'USD',
      'currentBalance': 250000.0,
      'isActive': true,
    },
    {
      'id': 'COA-4000',
      'accountCode': '4000',
      'name': 'Sales Revenue',
      'type': 'Revenue',
      'subType': 'Operating Revenue',
      'currency': 'USD',
      'currentBalance': 15000000.0,
      'isActive': true,
    },
  ];
  for (var doc in chartOfAccounts) {
    batch.set(
      firestore.tenantCollection(tenantId, 'chart_of_accounts').doc(doc['id']),
      doc,
    );
  }

  // Finance - Journal Entries
  final journalEntries = <Map<String, dynamic>>[
    {
      'id': 'JE-001',
      'entryNumber': 'JE-2026-001',
      'date': iso(5),
      'description': 'Record Sales Revenue for Wayne Ent',
      'status': 'POSTED',
      'createdBy': 'EMP-005',
      'totalDebit': 16400000.0,
      'totalCredit': 16400000.0,
      'lines': [
        {
          'id': 'JEL-1',
          'accountId': 'COA-1000',
          'debit': 16400000.0,
          'credit': 0.0,
          'description': 'Cash received',
        },
        {
          'id': 'JEL-2',
          'accountId': 'COA-4000',
          'debit': 0.0,
          'credit': 16400000.0,
          'description': 'Sales Revenue',
        },
      ],
    },
  ];
  for (var doc in journalEntries) {
    batch.set(
      firestore.tenantCollection(tenantId, 'journal_entries').doc(doc['id']),
      doc,
    );
  }

  debugPrint('--- Seeding SCM ---');
  // SCM - Inventory Items
  final inventory = <Map<String, dynamic>>[
    {
      'id': 'ITEM-001',
      'sku': 'SKU-TITAN-1',
      'name': 'Titanium Alloy Sheets',
      'itemType': 'RAW_MATERIAL',
      'unitOfMeasure': 'KG',
      'valuationMethod': 'FIFO',
      'lifecycleStatus': 'ACTIVE',
      'stockLevel': 5000.0,
      'tenantId': tenantId,
    },
    {
      'id': 'ITEM-002',
      'sku': 'SKU-PROC-X',
      'name': 'Quantum Processor X',
      'itemType': 'FINISHED_GOOD',
      'unitOfMeasure': 'UNIT',
      'valuationMethod': 'STANDARD_COST',
      'lifecycleStatus': 'ACTIVE',
      'stockLevel': 250.0,
      'tenantId': tenantId,
    },
    {
      'id': 'ITEM-003',
      'sku': 'SKU-LUBRICANT',
      'name': 'Industrial Lubricant',
      'itemType': 'CONSUMABLE',
      'unitOfMeasure': 'LITER',
      'valuationMethod': 'FIFO',
      'lifecycleStatus': 'ACTIVE',
      'stockLevel': 1000.0,
      'tenantId': tenantId,
    },
  ];
  for (var doc in inventory) {
    batch.set(
      firestore.tenantCollection(tenantId, 'inventory_items').doc(doc['id']),
      doc,
    );
  }

  // SCM - Warehouses
  final warehouses = <Map<String, dynamic>>[
    {
      'id': 'WH-NY',
      'code': 'NY-01',
      'name': 'New York Fulfillment',
      'type': 'DISTRIBUTION_CENTER',
      'address': {'city': 'New York', 'state': 'NY'},
      'managerId': 'EMP-006',
      'isActive': true,
      'tenantId': tenantId,
    },
    {
      'id': 'WH-LA',
      'code': 'LA-02',
      'name': 'Los Angeles Hub',
      'type': 'WAREHOUSE',
      'address': {'city': 'Los Angeles', 'state': 'CA'},
      'managerId': 'EMP-007',
      'isActive': true,
      'tenantId': tenantId,
    },
  ];
  for (var doc in warehouses) {
    batch.set(
      firestore.tenantCollection(tenantId, 'warehouses').doc(doc['id']),
      doc,
    );
  }

  // SCM - Purchase Orders
  final purchaseOrders = <Map<String, dynamic>>[
    {
      'id': 'PO-001',
      'poNumber': 'PO-2026-001',
      'vendorId': 'VEND-001',
      'warehouseId': 'WH-NY',
      'status': 'CONFIRMED',
      'orderDate': iso(10),
      'expectedDeliveryDate': iso(-5),
      'currency': 'USD',
      'totalAmount': 50000.0,
    },
    {
      'id': 'PO-002',
      'poNumber': 'PO-2026-002',
      'vendorId': 'VEND-002',
      'warehouseId': 'WH-LA',
      'status': 'RECEIVED',
      'orderDate': iso(20),
      'expectedDeliveryDate': iso(2),
      'currency': 'USD',
      'totalAmount': 15000.0,
    },
  ];
  for (var doc in purchaseOrders) {
    batch.set(
      firestore.tenantCollection(tenantId, 'purchase_orders').doc(doc['id']),
      doc,
    );
  }

  // SCM - Assets
  final assets = <Map<String, dynamic>>[
    {
      'id': 'ASST-001',
      'assetTag': 'CNC-01',
      'name': 'CNC Milling Machine',
      'category': 'MACHINERY',
      'serialNumber': 'SN-998877',
      'manufacturer': 'Haas',
      'model': 'VF-2',
      'status': 'IN_USE',
      'warehouseId': 'WH-NY',
      'purchasePrice': 75000.0,
      'createdAt': iso(500),
    },
    {
      'id': 'ASST-002',
      'assetTag': 'FL-05',
      'name': 'Forklift 05',
      'category': 'VEHICLE',
      'serialNumber': 'SN-FL-554',
      'manufacturer': 'Toyota',
      'model': '8FGCU25',
      'status': 'AVAILABLE',
      'warehouseId': 'WH-LA',
      'purchasePrice': 25000.0,
      'createdAt': iso(300),
    },
  ];
  for (var doc in assets) {
    batch.set(
      firestore.tenantCollection(tenantId, 'assets').doc(doc['id']),
      doc,
    );
  }

  debugPrint('--- Seeding Operations ---');
  // Operations - Work Orders
  final workOrders = <Map<String, dynamic>>[
    {
      'id': 'WO-001',
      'title': 'Server Rack Assembly',
      'description': 'Assemble 50 server racks',
      'priority': 'High',
      'status': 'IN_PROGRESS',
      'assignedTo': 'EMP-008',
      'tenantId': tenantId,
      'createdAt': iso(2),
    },
    {
      'id': 'WO-002',
      'title': 'HVAC Maintenance',
      'description': 'Quarterly preventative maintenance',
      'priority': 'Medium',
      'status': 'PENDING',
      'assignedTo': 'EMP-009',
      'tenantId': tenantId,
      'createdAt': iso(1),
    },
  ];
  for (var doc in workOrders) {
    batch.set(
      firestore.tenantCollection(tenantId, 'work_orders').doc(doc['id']),
      doc,
    );
  }

  // Operations - Action Trackers
  final actionTrackers = <Map<String, dynamic>>[
    {
      'id': 'ACT-001',
      'title': 'Safety Audit Follow-up',
      'description': 'Fix loose railing on catwalk',
      'assigneeId': 'EMP-010',
      'priority': 'High',
      'status': 'OPEN',
      'dueDate': iso(-2),
      'tenantId': tenantId,
      'createdAt': iso(1),
    },
    {
      'id': 'ACT-002',
      'title': 'Update ISO Documentation',
      'description': 'Revise section 4.2',
      'assigneeId': 'EMP-011',
      'priority': 'Medium',
      'status': 'IN_PROGRESS',
      'dueDate': iso(-5),
      'tenantId': tenantId,
      'createdAt': iso(3),
    },
  ];
  for (var doc in actionTrackers) {
    batch.set(
      firestore.tenantCollection(tenantId, 'action_trackers').doc(doc['id']),
      doc,
    );
  }

  debugPrint('--- Seeding Customer Service ---');
  // Customer Service - Tickets
  final tickets = <Map<String, dynamic>>[
    {
      'id': 'TKT-001',
      'ticketNumber': 'T-1001',
      'customerId': 'ACC-002',
      'contactId': 'CON-002',
      'subject': 'Batmobile engine stall',
      'description': 'Engine stalls at high RPM.',
      'priority': 'Critical',
      'status': 'Open',
      'source': 'Email',
      'ownerId': 'EMP-012',
      'createdAt': iso(1),
    },
    {
      'id': 'TKT-002',
      'ticketNumber': 'T-1002',
      'customerId': 'ACC-001',
      'contactId': 'CON-001',
      'subject': 'Arc Reactor calibration',
      'description': 'Needs recalibration software update.',
      'priority': 'High',
      'status': 'In Progress',
      'source': 'Portal',
      'ownerId': 'EMP-013',
      'createdAt': iso(2),
    },
  ];
  for (var doc in tickets) {
    batch.set(
      firestore.tenantCollection(tenantId, 'tickets').doc(doc['id']),
      doc,
    );
  }

  // Customer Service - Knowledge Articles
  final knowledgeArticles = <Map<String, dynamic>>[
    {
      'id': 'KA-001',
      'title': 'How to restart the CNC Machine',
      'content': 'Press the green button for 5 seconds.',
      'category': 'Troubleshooting',
      'status': 'Published',
      'authorId': 'EMP-006',
      'viewCount': 142,
      'createdAt': iso(50),
    },
    {
      'id': 'KA-002',
      'title': 'Forklift Safety Guidelines',
      'content': 'Always wear seatbelt. Honk at intersections.',
      'category': 'Safety',
      'status': 'Published',
      'authorId': 'EMP-010',
      'viewCount': 89,
      'createdAt': iso(45),
    },
  ];
  for (var doc in knowledgeArticles) {
    batch.set(
      firestore.tenantCollection(tenantId, 'knowledge_articles').doc(doc['id']),
      doc,
    );
  }

  debugPrint('--- Seeding Field Service ---');
  // Field Service - Dispatchers
  final dispatchers = <Map<String, dynamic>>[
    {
      'id': 'DISP-001',
      'name': 'Central Command',
      'region': 'North America',
      'activeAgentsCount': 12,
      'tenantId': tenantId,
    },
    {
      'id': 'DISP-002',
      'name': 'Euro Hub',
      'region': 'Europe',
      'activeAgentsCount': 8,
      'tenantId': tenantId,
    },
  ];
  for (var doc in dispatchers) {
    batch.set(
      firestore.tenantCollection(tenantId, 'dispatchers').doc(doc['id']),
      doc,
    );
  }

  // Field Service - Field Agents
  final fieldAgents = <Map<String, dynamic>>[
    {
      'id': 'FA-001',
      'name': 'Clark Kent',
      'skills': ['HVAC', 'Electrical'],
      'status': 'AVAILABLE',
      'currentLocation': {'lat': 40.7128, 'lng': -74.0060},
      'tenantId': tenantId,
    },
    {
      'id': 'FA-002',
      'name': 'Barry Allen',
      'skills': ['Mechanical', 'Software'],
      'status': 'ON_JOB',
      'currentLocation': {'lat': 34.0522, 'lng': -118.2437},
      'tenantId': tenantId,
    },
  ];
  for (var doc in fieldAgents) {
    batch.set(
      firestore.tenantCollection(tenantId, 'field_agents').doc(doc['id']),
      doc,
    );
  }

  debugPrint('--- Seeding HR / People ---');
  // HR - Employees
  final employees = <Map<String, dynamic>>[
    {
      'id': 'EMP-001',
      'firstName': 'Pepper',
      'lastName': 'Potts',
      'email': 'pepper@sentinel.com',
      'department': 'Sales',
      'jobTitle': 'VP Sales',
      'status': 'Active',
      'hireDate': iso(1000),
      'tenantId': tenantId,
    },
    {
      'id': 'EMP-002',
      'firstName': 'Happy',
      'lastName': 'Hogan',
      'email': 'happy@sentinel.com',
      'department': 'Operations',
      'jobTitle': 'Head of Security',
      'status': 'Active',
      'hireDate': iso(800),
      'tenantId': tenantId,
    },
    {
      'id': 'EMP-003',
      'firstName': 'Peter',
      'lastName': 'Parker',
      'email': 'peter@sentinel.com',
      'department': 'Engineering',
      'jobTitle': 'Intern',
      'status': 'Active',
      'hireDate': iso(100),
      'tenantId': tenantId,
    },
  ];
  for (var doc in employees) {
    batch.set(
      firestore.tenantCollection(tenantId, 'employees').doc(doc['id']),
      doc,
    );
  }

  // HR - Leave Requests
  final leaveRequests = <Map<String, dynamic>>[
    {
      'id': 'LR-001',
      'employeeId': 'EMP-003',
      'leaveType': 'Sick',
      'startDate': iso(-1),
      'endDate': iso(-3),
      'status': 'Approved',
      'reason': 'Spider bite',
      'tenantId': tenantId,
    },
    {
      'id': 'LR-002',
      'employeeId': 'EMP-002',
      'leaveType': 'Vacation',
      'startDate': iso(-10),
      'endDate': iso(-15),
      'status': 'Pending',
      'reason': 'Trip to Europe',
      'tenantId': tenantId,
    },
  ];
  for (var doc in leaveRequests) {
    batch.set(
      firestore.tenantCollection(tenantId, 'leave_requests').doc(doc['id']),
      doc,
    );
  }

  debugPrint('--- Seeding PMO (Projects) ---');
  // PMO - Projects
  final projects = <Map<String, dynamic>>[
    {
      'id': 'PRJ-001',
      'name': 'Project Insight',
      'description': 'Global defense grid',
      'status': 'In Progress',
      'managerId': 'EMP-002',
      'startDate': iso(200),
      'endDate': iso(-300),
      'budget': 100000000.0,
      'tenantId': tenantId,
    },
    {
      'id': 'PRJ-002',
      'name': 'Stark Tower Renovation',
      'description': 'Repair damage from alien invasion',
      'status': 'Planning',
      'managerId': 'EMP-001',
      'startDate': iso(-5),
      'endDate': iso(-150),
      'budget': 15000000.0,
      'tenantId': tenantId,
    },
  ];
  for (var doc in projects) {
    batch.set(
      firestore.tenantCollection(tenantId, 'projects').doc(doc['id']),
      doc,
    );
  }

  // PMO - Tasks
  final pmoTasks = <Map<String, dynamic>>[
    {
      'id': 'PT-001',
      'projectId': 'PRJ-001',
      'name': 'Launch Helicarriers',
      'status': 'Not Started',
      'assigneeId': 'EMP-002',
      'dueDate': iso(-250),
      'tenantId': tenantId,
    },
    {
      'id': 'PT-002',
      'projectId': 'PRJ-002',
      'name': 'Replace A logo',
      'status': 'In Progress',
      'assigneeId': 'EMP-001',
      'dueDate': iso(-10),
      'tenantId': tenantId,
    },
  ];
  for (var doc in pmoTasks) {
    batch.set(
      firestore.tenantCollection(tenantId, 'project_tasks').doc(doc['id']),
      doc,
    );
  }

  await batch.commit();
}
