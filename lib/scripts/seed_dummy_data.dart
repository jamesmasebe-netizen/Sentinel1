import 'package:cloud_firestore/cloud_firestore.dart';

/// Seeds exhaustive dummy data across ALL modules.
/// Every dropdown option gets at least one record.
/// The story: "Site A Expansion & Retrofit Project"
Future<void> seedAllDummyData(FirebaseFirestore firestore) async {
  // Firestore batches max 500 ops. We'll use multiple batches.
  final batch1 = firestore.batch();

  // ─── Helpers ───
  DateTime daysAgo(int days) => DateTime.now().subtract(Duration(days: days));
  String iso(int daysAgoVal) => daysAgo(daysAgoVal).toIso8601String();

  // The siteId must match the dev bypass profile: 'Site A'
  const siteA = 'Site A';

  // ════════════════════════════════════════════════════════════════
  // ─── INCIDENTS ───
  // Dropdowns → Status: [Open, Investigating, Resolved, Closed]
  //           → Severity: [Minor, Moderate, Major, Critical]
  //           → Type: [Injury, Near Miss, Property Damage, Environmental, Hazard Observation]
  // ════════════════════════════════════════════════════════════════
  final incidents = <Map<String, dynamic>>[
    // Exhaust ALL Status options
    {'title': 'Scaffolding collapse on South Wing', 'type': 'Property Damage', 'severity': 'Critical', 'status': 'Open', 'description': 'Section B scaffolding buckled under load. Area cordoned off immediately.', 'reporterName': 'Alice Smith', 'location': 'South Wing Level 3', 'dateOfIncident': iso(1), 'totalCost': 45000, 'siteId': siteA, 'createdAt': iso(1)},
    {'title': 'Unauthorized entry into HV zone', 'type': 'Near Miss', 'severity': 'Major', 'status': 'Investigating', 'description': 'Sparky Electrics crew entered high-voltage switchroom without clearance.', 'reporterName': 'Bob Jones', 'location': 'Substation Room A', 'dateOfIncident': iso(2), 'contractorName': 'Sparky Electrics', 'siteId': siteA, 'createdAt': iso(2)},
    {'title': 'Worker slipped on wet floor in canteen', 'type': 'Injury', 'severity': 'Moderate', 'status': 'Resolved', 'description': 'Worker sustained a sprained ankle. Wet floor sign was not placed after mopping.', 'reporterName': 'Charlie Brown', 'location': 'Canteen', 'dateOfIncident': iso(5), 'totalCost': 3200, 'siteId': siteA, 'createdAt': iso(5)},
    {'title': 'Hand laceration during drywall install', 'type': 'Injury', 'severity': 'Minor', 'status': 'Closed', 'description': 'Small cut on left hand from utility knife. First aid applied on site.', 'reporterName': 'David Lee', 'location': 'Admin Block Room 204', 'dateOfIncident': iso(15), 'totalCost': 150, 'siteId': siteA, 'createdAt': iso(15)},
    // Exhaust remaining Types
    {'title': 'Diesel spill near stormwater drain', 'type': 'Environmental', 'severity': 'Major', 'status': 'Open', 'description': '20L diesel leaked from generator fuel line into stormwater catchment area.', 'reporterName': 'Alice Smith', 'location': 'Generator Yard', 'dateOfIncident': iso(0), 'siteId': siteA, 'createdAt': iso(0)},
    {'title': 'Loose railing on stairwell B', 'type': 'Hazard Observation', 'severity': 'Moderate', 'status': 'Open', 'description': 'Railing on stairwell B between floors 2-3 is loose and wobbles when gripped.', 'reporterName': 'Bob Jones', 'location': 'Stairwell B', 'dateOfIncident': iso(3), 'siteId': siteA, 'createdAt': iso(3)},
    // Extra for story depth
    {'title': 'Near miss: Crane load swung over workers', 'type': 'Near Miss', 'severity': 'Critical', 'status': 'Investigating', 'description': 'Tower crane operator swung load over occupied walkway. No injuries.', 'reporterName': 'Bob Jones', 'location': 'Tower Crane Zone', 'dateOfIncident': iso(1), 'siteId': siteA, 'createdAt': iso(1)},
    {'title': 'Vehicle collision in parking lot', 'type': 'Property Damage', 'severity': 'Minor', 'status': 'Closed', 'description': 'Delivery truck reversed into bollard. Minor bumper damage.', 'reporterName': 'David Lee', 'location': 'Parking Bay C', 'dateOfIncident': iso(30), 'totalCost': 800, 'siteId': siteA, 'createdAt': iso(30)},
  ];
  for (var i = 0; i < incidents.length; i++) {
    batch1.set(firestore.collection('incidents').doc('INC-${(i+1).toString().padLeft(3,'0')}'), incidents[i]);
  }

  // ════════════════════════════════════════════════════════════════
  // ─── BBS OBSERVATIONS ───
  // Dropdowns → observationType: [Safe Act, Unsafe Act, Unsafe Condition]
  // ════════════════════════════════════════════════════════════════
  final bbs = <Map<String, dynamic>>[
    {'observationType': 'Unsafe Act', 'description': 'Worker removed safety glasses due to lens fogging while grinding.', 'location': 'Workshop Bay 2', 'observerName': 'Alice Smith', 'pointsAwarded': 5, 'authorId': 'dev-admin-123', 'siteId': siteA, 'createdAt': iso(1)},
    {'observationType': 'Safe Act', 'description': 'Excellent traffic control around crane operation zone — spotter always present.', 'location': 'Tower Crane Zone', 'observerName': 'Bob Jones', 'pointsAwarded': 10, 'authorId': 'dev-admin-123', 'siteId': siteA, 'createdAt': iso(2)},
    {'observationType': 'Unsafe Condition', 'description': 'Oil slick on walkway near generator. No absorbent or signage placed.', 'location': 'Generator Yard', 'observerName': 'Alice Smith', 'pointsAwarded': 5, 'authorId': 'dev-admin-123', 'siteId': siteA, 'createdAt': iso(3)},
    {'observationType': 'Safe Act', 'description': 'Team followed full LOTO procedure before servicing conveyor belt.', 'location': 'Maintenance Shop', 'observerName': 'Charlie Brown', 'pointsAwarded': 10, 'authorId': 'dev-admin-123', 'siteId': siteA, 'createdAt': iso(0)},
    {'observationType': 'Unsafe Act', 'description': 'Lifting heavy boxes without bending knees — improper posture.', 'location': 'Warehouse', 'observerName': 'Bob Jones', 'pointsAwarded': 5, 'authorId': 'dev-admin-123', 'siteId': siteA, 'createdAt': iso(4)},
    {'observationType': 'Unsafe Condition', 'description': 'Fire extinguisher near exit obstructed by stacked materials.', 'location': 'South Wing Level 1', 'observerName': 'David Lee', 'pointsAwarded': 5, 'authorId': 'dev-admin-123', 'siteId': siteA, 'createdAt': iso(6)},
  ];
  for (var i = 0; i < bbs.length; i++) {
    batch1.set(firestore.collection('bbs_observations').doc('BBS-${(i+1).toString().padLeft(3,'0')}'), bbs[i]);
  }

  // ════════════════════════════════════════════════════════════════
  // ─── PERMITS TO WORK ───
  // Dropdowns → type: [Hot Work, Working at Heights, Confined Space, Electrical, Excavation, Other]
  //           → status: [Requested, Approved, Active, Closed]
  // ════════════════════════════════════════════════════════════════
  final permits = <Map<String, dynamic>>[
    {'title': 'HVAC Welding - South Wing', 'type': 'Hot Work', 'status': 'Active', 'applicantName': 'John from Acme Builders', 'location': 'South Wing Roof', 'validUntil': iso(-1), 'lotoRequired': true, 'siteId': siteA, 'createdAt': iso(0)},
    {'title': 'Roof Retrofit Access', 'type': 'Working at Heights', 'status': 'Approved', 'applicantName': 'Bob Jones', 'location': 'Admin Block Roof', 'validUntil': iso(-3), 'lotoRequired': false, 'siteId': siteA, 'createdAt': iso(1)},
    {'title': 'Basement Plumbing Inspection', 'type': 'Confined Space', 'status': 'Closed', 'applicantName': 'ClearFlow Plumbing', 'location': 'Basement Level B2', 'validUntil': iso(5), 'lotoRequired': true, 'siteId': siteA, 'createdAt': iso(6)},
    {'title': 'Server Room Rewire', 'type': 'Electrical', 'status': 'Requested', 'applicantName': 'Sparky Electrics', 'location': 'Server Room', 'validUntil': iso(-5), 'lotoRequired': true, 'siteId': siteA, 'createdAt': iso(0)},
    {'title': 'Foundation Trenching Phase 2', 'type': 'Excavation', 'status': 'Active', 'applicantName': 'Acme Builders', 'location': 'North Perimeter', 'validUntil': iso(-2), 'lotoRequired': false, 'siteId': siteA, 'createdAt': iso(1)},
    {'title': 'Temporary Fence Installation', 'type': 'Other', 'status': 'Closed', 'applicantName': 'David Lee', 'location': 'East Boundary', 'validUntil': iso(10), 'lotoRequired': false, 'siteId': siteA, 'createdAt': iso(12)},
  ];
  for (var i = 0; i < permits.length; i++) {
    batch1.set(firestore.collection('permits').doc('PTW-${(i+1).toString().padLeft(3,'0')}'), permits[i]);
  }

  // ════════════════════════════════════════════════════════════════
  // ─── CAPAs (Corrective & Preventive Actions) ───
  // Status workflow: [Open, In Progress, Completed, Verified]
  // ════════════════════════════════════════════════════════════════
  final capas = <Map<String, dynamic>>[
    {'description': 'Conduct immediate structural audit of all scaffolding on site', 'rca': 'Root cause: Corroded base plates not inspected during last audit', 'assignedToName': 'Bob Jones', 'dueDate': iso(-3), 'status': 'Open', 'incidentId': 'INC-001', 'createdById': 'dev-admin-123', 'siteId': siteA, 'createdAt': iso(1)},
    {'description': 'Procure anti-fog safety glasses for high-humidity work areas', 'rca': 'Workers removing PPE due to lens fogging — inadequate PPE spec', 'assignedToName': 'Alice Smith', 'dueDate': iso(-5), 'status': 'In Progress', 'createdById': 'dev-admin-123', 'siteId': siteA, 'createdAt': iso(2)},
    {'description': 'Update LOTO training module with new switchgear procedures', 'rca': 'Unauthorized entry incident linked to outdated training material', 'assignedToName': 'Charlie Brown', 'dueDate': iso(0), 'status': 'Completed', 'incidentId': 'INC-002', 'createdById': 'dev-admin-123', 'siteId': siteA, 'createdAt': iso(10)},
    {'description': 'Install wet floor signage dispensers in all break areas', 'rca': 'Slip incident caused by absence of wet floor signs after mopping', 'assignedToName': 'Facilities Team', 'dueDate': iso(5), 'status': 'Verified', 'incidentId': 'INC-003', 'createdById': 'dev-admin-123', 'siteId': siteA, 'createdAt': iso(20)},
    {'description': 'Repair loose railing on Stairwell B between floors 2-3', 'rca': 'Fasteners corroded due to water ingress from leaking roof', 'assignedToName': 'Maintenance Dept', 'dueDate': iso(-1), 'status': 'Open', 'incidentId': 'INC-006', 'createdById': 'dev-admin-123', 'siteId': siteA, 'createdAt': iso(3)},
  ];
  for (var i = 0; i < capas.length; i++) {
    batch1.set(firestore.collection('capas').doc('CAPA-${(i+1).toString().padLeft(3,'0')}'), capas[i]);
  }

  await batch1.commit();

  // ─── Second batch ───
  final batch2 = firestore.batch();

  // ════════════════════════════════════════════════════════════════
  // ─── HAZARD REGISTER ───
  // Severity: [Low, Medium, High, Critical]
  // ════════════════════════════════════════════════════════════════
  final hazards = <Map<String, dynamic>>[
    {'title': 'Unguarded floor opening on Level 4', 'description': 'Floor opening for HVAC ducting left unguarded overnight', 'severity': 'Critical', 'location': 'South Wing Level 4', 'status': 'Open', 'siteId': siteA, 'createdAt': iso(0)},
    {'title': 'Exposed electrical wiring in corridor', 'description': 'Wiring exposed from ongoing rewiring project', 'severity': 'High', 'location': 'Admin Block Corridor B', 'status': 'Open', 'siteId': siteA, 'createdAt': iso(2)},
    {'title': 'Poor lighting in basement parking', 'description': '3 of 8 LED panels not working in basement parking P2', 'severity': 'Medium', 'location': 'Basement P2', 'status': 'Open', 'siteId': siteA, 'createdAt': iso(5)},
    {'title': 'Minor trip hazard from cable tray', 'description': 'Temporary cable tray across walkway near server room', 'severity': 'Low', 'location': 'Server Room Entrance', 'status': 'Resolved', 'siteId': siteA, 'createdAt': iso(10)},
  ];
  for (var i = 0; i < hazards.length; i++) {
    batch2.set(firestore.collection('hazards').doc('HAZ-${(i+1).toString().padLeft(3,'0')}'), hazards[i]);
  }

  // ════════════════════════════════════════════════════════════════
  // ─── EMPLOYEES ───
  // ════════════════════════════════════════════════════════════════
  final employees = <Map<String, dynamic>>[
    {'fullName': 'Alice Smith', 'role': 'Safety Officer', 'department': 'HSE', 'status': 'Active', 'siteId': siteA, 'createdAt': iso(365)},
    {'fullName': 'Bob Jones', 'role': 'Site Supervisor', 'department': 'Operations', 'status': 'Active', 'siteId': siteA, 'createdAt': iso(200)},
    {'fullName': 'Charlie Brown', 'role': 'Technician', 'department': 'Maintenance', 'status': 'Active', 'siteId': siteA, 'createdAt': iso(100)},
    {'fullName': 'David Lee', 'role': 'Project Manager', 'department': 'Projects', 'status': 'Active', 'siteId': siteA, 'createdAt': iso(500)},
    {'fullName': 'Emily Davis', 'role': 'Environmental Officer', 'department': 'HSE', 'status': 'Active', 'siteId': siteA, 'createdAt': iso(90)},
  ];
  for (var i = 0; i < employees.length; i++) {
    batch2.set(firestore.collection('employees').doc('EMP-${(i+1).toString().padLeft(3,'0')}'), employees[i]);
  }

  // ════════════════════════════════════════════════════════════════
  // ─── CONTRACTORS ───
  // ════════════════════════════════════════════════════════════════
  final contractors = <Map<String, dynamic>>[
    {'name': 'Acme Builders', 'trade': 'Construction', 'status': 'Approved', 'complianceScore': 92, 'contactPerson': 'John Doe', 'contactEmail': 'john@acme.co.za', 'siteId': siteA, 'createdAt': iso(120)},
    {'name': 'Sparky Electrics', 'trade': 'Electrical', 'status': 'Probation', 'complianceScore': 65, 'contactPerson': 'Mark Volt', 'contactEmail': 'mark@sparky.co.za', 'siteId': siteA, 'createdAt': iso(80)},
    {'name': 'ClearFlow Plumbing', 'trade': 'Plumbing', 'status': 'Approved', 'complianceScore': 88, 'contactPerson': 'Jane Flow', 'contactEmail': 'jane@clearflow.co.za', 'siteId': siteA, 'createdAt': iso(200)},
    {'name': 'SafeScaffold Co', 'trade': 'Scaffolding', 'status': 'Suspended', 'complianceScore': 40, 'contactPerson': 'Peter Frame', 'contactEmail': 'peter@safescaffold.co.za', 'siteId': siteA, 'createdAt': iso(300)},
  ];
  for (var i = 0; i < contractors.length; i++) {
    batch2.set(firestore.collection('contractors').doc('CON-${(i+1).toString().padLeft(3,'0')}'), contractors[i]);
  }

  // ════════════════════════════════════════════════════════════════
  // ─── EQUIPMENT ───
  // ════════════════════════════════════════════════════════════════
  final equipment = <Map<String, dynamic>>[
    {'name': 'Tower Crane TS-400', 'type': 'Heavy Machinery', 'status': 'Operational', 'nextMaintenance': iso(-15), 'siteId': siteA, 'createdAt': iso(60)},
    {'name': 'Diesel Generator 50kVA', 'type': 'Power', 'status': 'Maintenance Required', 'nextMaintenance': iso(5), 'siteId': siteA, 'createdAt': iso(90)},
    {'name': 'Scissor Lift SL-200', 'type': 'Access', 'status': 'Out of Service', 'nextMaintenance': iso(20), 'siteId': siteA, 'createdAt': iso(120)},
    {'name': 'Excavator CAT 320', 'type': 'Heavy Machinery', 'status': 'Operational', 'nextMaintenance': iso(-30), 'siteId': siteA, 'createdAt': iso(45)},
  ];
  for (var i = 0; i < equipment.length; i++) {
    batch2.set(firestore.collection('equipment').doc('EQ-${(i+1).toString().padLeft(3,'0')}'), equipment[i]);
  }

  // ════════════════════════════════════════════════════════════════
  // ─── ENVIRONMENTAL SPILLS ───
  // ════════════════════════════════════════════════════════════════
  final spills = <Map<String, dynamic>>[
    {'substance': 'Hydraulic Fluid', 'type': 'Oil/Fuel', 'severity': 'Minor', 'volume': '5L', 'contained': true, 'siteId': siteA, 'createdAt': iso(2)},
    {'substance': 'Diesel', 'type': 'Oil/Fuel', 'severity': 'Moderate', 'volume': '20L', 'contained': false, 'siteId': siteA, 'createdAt': iso(0)},
    {'substance': 'Paint Thinner', 'type': 'Chemical', 'severity': 'Moderate', 'volume': '10L', 'contained': true, 'siteId': siteA, 'createdAt': iso(8)},
  ];
  for (var i = 0; i < spills.length; i++) {
    batch2.set(firestore.collection('environmental_spills').doc('SPILL-${(i+1).toString().padLeft(3,'0')}'), spills[i]);
  }

  // ════════════════════════════════════════════════════════════════
  // ─── WASTE MANIFESTS ───
  // ════════════════════════════════════════════════════════════════
  final waste = <Map<String, dynamic>>[
    {'type': 'Hazardous', 'description': 'Paint thinner and solvent drums', 'quantity': '500kg', 'destination': 'SafeDisposal Inc', 'status': 'In Transit', 'siteId': siteA, 'createdAt': iso(1)},
    {'type': 'General', 'description': 'Demolition rubble and concrete', 'quantity': '2 Tons', 'destination': 'City Landfill', 'status': 'Delivered', 'siteId': siteA, 'createdAt': iso(5)},
    {'type': 'Recyclable', 'description': 'Scrap metal and copper wiring', 'quantity': '1.5 Tons', 'destination': 'GreenRecycle', 'status': 'Pending Pickup', 'siteId': siteA, 'createdAt': iso(0)},
  ];
  for (var i = 0; i < waste.length; i++) {
    batch2.set(firestore.collection('waste_manifests').doc('WST-${(i+1).toString().padLeft(3,'0')}'), waste[i]);
  }

  // ════════════════════════════════════════════════════════════════
  // ─── ESG METRICS ───
  // ════════════════════════════════════════════════════════════════
  final esg = <Map<String, dynamic>>[
    {'metric': 'Carbon Footprint', 'value': '12.5 tCO2e', 'target': '10 tCO2e', 'status': 'Off Track', 'siteId': siteA, 'createdAt': iso(0)},
    {'metric': 'Water Usage', 'value': '450 kL', 'target': '500 kL', 'status': 'On Track', 'siteId': siteA, 'createdAt': iso(0)},
    {'metric': 'Community Investment Hours', 'value': '120 hrs', 'target': '100 hrs', 'status': 'Achieved', 'siteId': siteA, 'createdAt': iso(0)},
  ];
  for (var i = 0; i < esg.length; i++) {
    batch2.set(firestore.collection('esg_metrics').doc('ESG-${(i+1).toString().padLeft(3,'0')}'), esg[i]);
  }

  // ════════════════════════════════════════════════════════════════
  // ─── DYNAMIC RISK ASSESSMENTS ───
  // ════════════════════════════════════════════════════════════════
  final dra = <Map<String, dynamic>>[
    {'task': 'Roofing Retrofit — Fall Risk', 'riskLevel': 'Extreme', 'mitigations': 'Full body harness, safety nets, 2-person buddy system', 'approved': false, 'assessorName': 'Alice Smith', 'siteId': siteA, 'createdAt': iso(1)},
    {'task': 'Painting Admin Block Interior', 'riskLevel': 'Low', 'mitigations': 'Proper ventilation, respiratory PPE', 'approved': true, 'assessorName': 'Bob Jones', 'siteId': siteA, 'createdAt': iso(10)},
    {'task': 'HVAC Duct Installation', 'riskLevel': 'Medium', 'mitigations': 'LOTO on power, certified electricians only', 'approved': true, 'assessorName': 'Alice Smith', 'siteId': siteA, 'createdAt': iso(3)},
    {'task': 'Trench Digging for Water Main', 'riskLevel': 'High', 'mitigations': 'Shoring, ground penetrating radar, daily inspections', 'approved': false, 'assessorName': 'Bob Jones', 'siteId': siteA, 'createdAt': iso(0)},
  ];
  for (var i = 0; i < dra.length; i++) {
    batch2.set(firestore.collection('dynamic_risk_assessments').doc('DRA-${(i+1).toString().padLeft(3,'0')}'), dra[i]);
  }

  // ════════════════════════════════════════════════════════════════
  // ─── PPE COMPLIANCE ───
  // Status: [Compliant, Non-Compliant, Expired]
  // ════════════════════════════════════════════════════════════════
  final ppe = <Map<String, dynamic>>[
    {'employeeName': 'Alice Smith', 'ppeType': 'Hard Hat', 'status': 'Compliant', 'expiryDate': iso(-90), 'siteId': siteA, 'createdAt': iso(30)},
    {'employeeName': 'Bob Jones', 'ppeType': 'Safety Boots', 'status': 'Non-Compliant', 'expiryDate': iso(10), 'siteId': siteA, 'createdAt': iso(30)},
    {'employeeName': 'Charlie Brown', 'ppeType': 'Safety Glasses', 'status': 'Expired', 'expiryDate': iso(15), 'siteId': siteA, 'createdAt': iso(60)},
    {'employeeName': 'David Lee', 'ppeType': 'High-Vis Vest', 'status': 'Compliant', 'expiryDate': iso(-180), 'siteId': siteA, 'createdAt': iso(30)},
  ];
  for (var i = 0; i < ppe.length; i++) {
    batch2.set(firestore.collection('ppe_compliance').doc('PPE-${(i+1).toString().padLeft(3,'0')}'), ppe[i]);
  }

  await batch2.commit();

  // ─── Third batch — new modules ───
  final batch3 = firestore.batch();

  // ════════════════════════════════════════════════════════════════
  // ─── HIRA (Baseline Risk Assessments) ───
  // ════════════════════════════════════════════════════════════════
  final hira = <Map<String, dynamic>>[
    {'title': 'Scaffolding Erection & Dismantling', 'hazard': 'Collapse due to improper bracing or corroded components', 'consequence': 'Fatality or multiple serious injuries', 'likelihood': 'Possible', 'severity': 'Catastrophic', 'riskScore': 15, 'riskLevel': 'Extreme', 'controlMeasure': 'Engineering Controls', 'status': 'Active', 'assessorId': 'dev-admin-123', 'siteId': siteA, 'createdAt': iso(2)},
    {'title': 'Manual Handling of Heavy Materials', 'hazard': 'Back injury from lifting concrete blocks without mechanical aids', 'consequence': 'Chronic musculoskeletal injury', 'likelihood': 'Likely', 'severity': 'Moderate', 'riskScore': 12, 'riskLevel': 'High', 'controlMeasure': 'Administrative Controls', 'status': 'Active', 'assessorId': 'dev-admin-123', 'siteId': siteA, 'createdAt': iso(5)},
    {'title': 'Electrical Work on Live Systems', 'hazard': 'Electrocution from contact with live conductors', 'consequence': 'Fatality', 'likelihood': 'Unlikely', 'severity': 'Catastrophic', 'riskScore': 10, 'riskLevel': 'High', 'controlMeasure': 'Elimination', 'status': 'Active', 'assessorId': 'dev-admin-123', 'siteId': siteA, 'createdAt': iso(8)},
    {'title': 'Office Ergonomics — Admin Block', 'hazard': 'RSI from prolonged computer work', 'consequence': 'Wrist pain, carpal tunnel', 'likelihood': 'Possible', 'severity': 'Minor', 'riskScore': 6, 'riskLevel': 'Medium', 'controlMeasure': 'PPE', 'status': 'Active', 'assessorId': 'dev-admin-123', 'siteId': siteA, 'createdAt': iso(30)},
    {'title': 'Vehicle Movement in Laydown Area', 'hazard': 'Pedestrian struck by reversing truck', 'consequence': 'Serious injury or fatality', 'likelihood': 'Rare', 'severity': 'Major', 'riskScore': 4, 'riskLevel': 'Low', 'controlMeasure': 'Substitution', 'status': 'Active', 'assessorId': 'dev-admin-123', 'siteId': siteA, 'createdAt': iso(15)},
  ];
  for (var i = 0; i < hira.length; i++) {
    batch3.set(firestore.collection('risk_assessments').doc('HIRA-${(i+1).toString().padLeft(3,'0')}'), hira[i]);
  }

  // ════════════════════════════════════════════════════════════════
  // ─── BOW-TIE ANALYSES ───
  // ════════════════════════════════════════════════════════════════
  final bowties = <Map<String, dynamic>>[
    {'title': 'Scaffolding Collapse Scenario', 'topEvent': 'Structural Collapse', 'threats': 'Corroded base plates, overloading, wind', 'consequences': 'Fatalities, project delay, legal action', 'preventiveBarriers': 'Load calculations, inspections, wind meters', 'mitigationBarriers': 'Emergency response, rescue teams, insurance', 'status': 'Active', 'authorId': 'dev-admin-123', 'siteId': siteA, 'createdAt': iso(1)},
    {'title': 'HVAC Hot Work Fire', 'topEvent': 'Fire / Explosion', 'threats': 'Sparks near flammables, no fire watch', 'consequences': 'Building fire, injuries, asset loss', 'preventiveBarriers': 'Hot work permit, fire watch, area clearance', 'mitigationBarriers': 'Fire extinguishers, fire brigade, sprinklers', 'status': 'Draft', 'authorId': 'dev-admin-123', 'siteId': siteA, 'createdAt': iso(3)},
    {'title': 'Confined Space Entry — Basement', 'topEvent': 'Confined Space Emergency', 'threats': 'O2 depletion, toxic gas, engulfment', 'consequences': 'Asphyxiation, rescue failure', 'preventiveBarriers': 'Gas testing, ventilation, entry permit', 'mitigationBarriers': 'Rescue team, breathing apparatus, alarm', 'status': 'Active', 'authorId': 'dev-admin-123', 'siteId': siteA, 'createdAt': iso(5)},
  ];
  for (var i = 0; i < bowties.length; i++) {
    batch3.set(firestore.collection('bowtie_analyses').doc('BT-${(i+1).toString().padLeft(3,'0')}'), bowties[i]);
  }

  // ════════════════════════════════════════════════════════════════
  // ─── STRATEGIC RISK REGISTER ───
  // ════════════════════════════════════════════════════════════════
  final strategicRisks = <Map<String, dynamic>>[
    {'title': 'Regulatory Non-Compliance — OHS Act', 'description': 'Risk of enforcement action due to incomplete section 16.2 appointments', 'category': 'Regulatory', 'owner': 'Alice Smith', 'likelihood': 'Possible', 'impact': 'Severe', 'riskScore': 15, 'riskRating': 'Critical', 'mitigation': 'Conduct compliance gap analysis, appoint responsible persons', 'status': 'Open', 'authorId': 'dev-admin-123', 'siteId': siteA, 'createdAt': iso(0)},
    {'title': 'Contractor Insolvency — SafeScaffold Co', 'description': 'Key scaffolding contractor facing financial difficulties, may default on project', 'category': 'Financial', 'owner': 'David Lee', 'likelihood': 'Likely', 'impact': 'Significant', 'riskScore': 16, 'riskRating': 'Critical', 'mitigation': 'Pre-qualify alternative scaffolding contractors, retain performance guarantee', 'status': 'Mitigating', 'authorId': 'dev-admin-123', 'siteId': siteA, 'createdAt': iso(2)},
    {'title': 'Reputational Damage from Incident', 'description': 'Potential media coverage if scaffolding collapse results in fatality', 'category': 'Reputational', 'owner': 'David Lee', 'likelihood': 'Unlikely', 'impact': 'Severe', 'riskScore': 10, 'riskRating': 'High', 'mitigation': 'Crisis comms plan, media training for spokespersons', 'status': 'Monitoring', 'authorId': 'dev-admin-123', 'siteId': siteA, 'createdAt': iso(5)},
    {'title': 'Climate Event Disruption', 'description': 'Severe weather could halt construction for extended periods', 'category': 'Environmental', 'owner': 'Bob Jones', 'likelihood': 'Possible', 'impact': 'Moderate', 'riskScore': 9, 'riskRating': 'Medium', 'mitigation': 'Weather monitoring, schedule float, covered work areas', 'status': 'Monitoring', 'authorId': 'dev-admin-123', 'siteId': siteA, 'createdAt': iso(10)},
  ];
  for (var i = 0; i < strategicRisks.length; i++) {
    batch3.set(firestore.collection('strategic_risks').doc('SR-${(i+1).toString().padLeft(3,'0')}'), strategicRisks[i]);
  }

  // ════════════════════════════════════════════════════════════════
  // ─── SKILLS MATRIX ───
  // ════════════════════════════════════════════════════════════════
  final skills = <Map<String, dynamic>>[
    {'employeeName': 'Alice Smith', 'skill': 'First Aid', 'proficiency': 'Expert', 'lastAssessed': iso(30), 'siteId': siteA, 'createdAt': iso(30)},
    {'employeeName': 'Alice Smith', 'skill': 'Fire Safety', 'proficiency': 'Advanced', 'lastAssessed': iso(60), 'siteId': siteA, 'createdAt': iso(60)},
    {'employeeName': 'Alice Smith', 'skill': 'Incident Investigation', 'proficiency': 'Expert', 'lastAssessed': iso(15), 'siteId': siteA, 'createdAt': iso(15)},
    {'employeeName': 'Bob Jones', 'skill': 'LOTO Procedure', 'proficiency': 'Advanced', 'lastAssessed': iso(45), 'siteId': siteA, 'createdAt': iso(45)},
    {'employeeName': 'Bob Jones', 'skill': 'Working at Heights', 'proficiency': 'Expert', 'lastAssessed': iso(20), 'siteId': siteA, 'createdAt': iso(20)},
    {'employeeName': 'Bob Jones', 'skill': 'Crane Operation', 'proficiency': 'Intermediate', 'lastAssessed': iso(90), 'siteId': siteA, 'createdAt': iso(90)},
    {'employeeName': 'Charlie Brown', 'skill': 'Forklift Operation', 'proficiency': 'Expert', 'lastAssessed': iso(10), 'siteId': siteA, 'createdAt': iso(10)},
    {'employeeName': 'Charlie Brown', 'skill': 'Confined Space Entry', 'proficiency': 'Beginner', 'lastAssessed': iso(5), 'siteId': siteA, 'createdAt': iso(5)},
    {'employeeName': 'David Lee', 'skill': 'Scaffolding Inspection', 'proficiency': 'Intermediate', 'lastAssessed': iso(30), 'siteId': siteA, 'createdAt': iso(30)},
    {'employeeName': 'David Lee', 'skill': 'Fall Protection', 'proficiency': 'Advanced', 'lastAssessed': iso(40), 'siteId': siteA, 'createdAt': iso(40)},
    {'employeeName': 'Emily Davis', 'skill': 'Hazmat Handling', 'proficiency': 'Expert', 'lastAssessed': iso(15), 'siteId': siteA, 'createdAt': iso(15)},
    {'employeeName': 'Emily Davis', 'skill': 'First Aid', 'proficiency': 'Intermediate', 'lastAssessed': iso(60), 'siteId': siteA, 'createdAt': iso(60)},
  ];
  for (var i = 0; i < skills.length; i++) {
    batch3.set(firestore.collection('skills_matrix').doc('SKL-${(i+1).toString().padLeft(3,'0')}'), skills[i]);
  }

  // ════════════════════════════════════════════════════════════════
  // ─── COMPETENCY PASSPORTS ───
  // ════════════════════════════════════════════════════════════════
  final competencies = <Map<String, dynamic>>[
    {'employeeName': 'Alice Smith', 'certification': 'SAMTRAC', 'issuer': 'NOSA', 'status': 'Valid', 'expiryDate': iso(-365), 'siteId': siteA, 'createdAt': iso(100)},
    {'employeeName': 'Alice Smith', 'certification': 'Level 3 First Aid', 'issuer': 'St Johns', 'status': 'Expiring Soon', 'expiryDate': iso(-30), 'siteId': siteA, 'createdAt': iso(200)},
    {'employeeName': 'Bob Jones', 'certification': 'Rigging Certificate', 'issuer': 'ECSA', 'status': 'Valid', 'expiryDate': iso(-180), 'siteId': siteA, 'createdAt': iso(90)},
    {'employeeName': 'Bob Jones', 'certification': 'Working at Heights', 'issuer': 'SafeTraining SA', 'status': 'Expired', 'expiryDate': iso(15), 'siteId': siteA, 'createdAt': iso(400)},
    {'employeeName': 'Charlie Brown', 'certification': 'Forklift Operator License', 'issuer': 'TETA', 'status': 'Valid', 'expiryDate': iso(-730), 'siteId': siteA, 'createdAt': iso(60)},
    {'employeeName': 'David Lee', 'certification': 'Project Management (PMP)', 'issuer': 'PMI', 'status': 'Valid', 'expiryDate': iso(-540), 'siteId': siteA, 'createdAt': iso(500)},
    {'employeeName': 'Emily Davis', 'certification': 'ISO 14001 Lead Auditor', 'issuer': 'IRCA', 'status': 'Valid', 'expiryDate': iso(-200), 'siteId': siteA, 'createdAt': iso(90)},
    {'employeeName': 'Emily Davis', 'certification': 'Hazmat Response', 'issuer': 'NFPA', 'status': 'Revoked', 'expiryDate': iso(5), 'siteId': siteA, 'createdAt': iso(300)},
  ];
  for (var i = 0; i < competencies.length; i++) {
    batch3.set(firestore.collection('competency_passports').doc('COMP-${(i+1).toString().padLeft(3,'0')}'), competencies[i]);
  }

  await batch3.commit();

  // ─── Fourth batch — Property & Facility Management ───
  final batch4 = firestore.batch();

  // ════════════════════════════════════════════════════════════════
  // ─── PROPERTIES (Sites/Facilities) ───
  // ════════════════════════════════════════════════════════════════
  final properties = <Map<String, dynamic>>[
    {
      'name': 'Sentinel HQ - North Tower',
      'type': 'Commercial Office',
      'address': '123 Enterprise Way, Sandton, Johannesburg',
      'lat': -26.1075,
      'lng': 28.0567,
      'totalArea': '45,000 m²',
      'floors': 12,
      'occupancy': 850,
      'capacity': 1200,
      'status': 'Optimal',
      'complianceScore': 94,
      'totalAssets': 1250,
      'constructionDate': '2015-06-01',
      'manager': 'Alice Smith',
      'siteId': siteA,
      'createdAt': iso(365),
    },
    {
      'name': 'Industrial Hub - Warehouse A',
      'type': 'Industrial / Logistics',
      'address': '45 Logistics Dr, Midrand, Johannesburg',
      'lat': -25.9992,
      'lng': 28.1262,
      'totalArea': '120,000 m²',
      'floors': 2,
      'occupancy': 45,
      'capacity': 200,
      'status': 'Maintenance Required',
      'complianceScore': 78,
      'totalAssets': 450,
      'constructionDate': '2010-11-15',
      'manager': 'Bob Jones',
      'siteId': siteA,
      'createdAt': iso(500),
    },
    {
      'name': 'Corporate Park - South Wing',
      'type': 'Commercial Office',
      'address': '88 Business Blvd, Cape Town',
      'lat': -33.9249,
      'lng': 18.4241,
      'totalArea': '15,000 m²',
      'floors': 4,
      'occupancy': 380,
      'capacity': 400,
      'status': 'Critical Alerts',
      'complianceScore': 62,
      'totalAssets': 180,
      'constructionDate': '2018-02-10',
      'manager': 'Emily Davis',
      'siteId': siteA,
      'createdAt': iso(200),
    },
  ];
  for (var i = 0; i < properties.length; i++) {
    batch4.set(firestore.collection('properties').doc('PROP-${(i+1).toString().padLeft(3,'0')}'), properties[i]);
  }

  // ════════════════════════════════════════════════════════════════
  // ─── PROPERTY PROJECTS / MAINTENANCE ───
  // ════════════════════════════════════════════════════════════════
  final propertyProjects = <Map<String, dynamic>>[
    {
      'propertyId': 'PROP-001',
      'title': 'HVAC System Overhaul',
      'type': 'Preventative Maintenance',
      'description': 'Quarterly servicing and filter replacement for central HVAC units.',
      'status': 'Ongoing',
      'assignedTo': 'Acme Builders',
      'dueDate': iso(-5),
      'progress': 65,
      'siteId': siteA,
      'createdAt': iso(10),
    },
    {
      'propertyId': 'PROP-001',
      'title': 'LED Lighting Retrofit',
      'type': 'Energy Efficiency',
      'description': 'Replacing all T5 tubes with energy-efficient LED panels across floors 1-6.',
      'status': 'Planned',
      'assignedTo': 'Sparky Electrics',
      'dueDate': iso(-20),
      'progress': 0,
      'siteId': siteA,
      'createdAt': iso(30),
    },
    {
      'propertyId': 'PROP-002',
      'title': 'Roof Leak Repair - Bay 4',
      'type': 'Reactive Repair',
      'description': 'Sealing joints and replacing damaged sheets in the northwest corner.',
      'status': 'Completed',
      'assignedTo': 'Acme Builders',
      'dueDate': iso(2),
      'progress': 100,
      'siteId': siteA,
      'createdAt': iso(5),
    },
  ];
  for (var i = 0; i < propertyProjects.length; i++) {
    batch4.set(firestore.collection('property_projects').doc('PROJ-${(i+1).toString().padLeft(3,'0')}'), propertyProjects[i]);
  }

  // ════════════════════════════════════════════════════════════════
  // ─── UTILITY USAGE (ESG TRACEABILITY) ───
  // ════════════════════════════════════════════════════════════════
  final utilities = <Map<String, dynamic>>[
    {'propertyId': 'PROP-001', 'month': 'April', 'electricity': 45000, 'water': 1200, 'waste': 4.2, 'carbon': 25.5, 'siteId': siteA, 'createdAt': iso(5)},
    {'propertyId': 'PROP-001', 'month': 'March', 'electricity': 48000, 'water': 1350, 'waste': 5.1, 'carbon': 27.8, 'siteId': siteA, 'createdAt': iso(35)},
    {'propertyId': 'PROP-002', 'month': 'April', 'electricity': 120000, 'water': 800, 'waste': 12.5, 'carbon': 85.0, 'siteId': siteA, 'createdAt': iso(5)},
  ];
  for (var i = 0; i < utilities.length; i++) {
    batch4.set(firestore.collection('property_utilities').doc('UTIL-${(i+1).toString().padLeft(3,'0')}'), utilities[i]);
  }

  // ════════════════════════════════════════════════════════════════
  // ─── LEGAL APPOINTMENTS ───
  // ════════════════════════════════════════════════════════════════
  final appointments = <Map<String, dynamic>>[
    {'propertyId': 'PROP-001', 'role': 'Fire Marshal', 'personName': 'Sarah Jenkins', 'status': 'Appointed', 'expiry': iso(-730), 'siteId': siteA, 'createdAt': iso(100)},
    {'propertyId': 'PROP-001', 'role': 'First Aider', 'personName': 'David Cho', 'status': 'Appointed', 'expiry': iso(-365), 'siteId': siteA, 'createdAt': iso(150)},
    {'propertyId': 'PROP-001', 'role': 'SHE Rep', 'personName': 'Michael Ross', 'status': 'Pending Approval', 'expiry': null, 'siteId': siteA, 'createdAt': iso(10)},
    {'propertyId': 'PROP-001', 'role': 'Security Chief', 'personName': 'Anita Patel', 'status': 'Appointed', 'expiry': iso(-1095), 'siteId': siteA, 'createdAt': iso(50)},
  ];
  for (var i = 0; i < appointments.length; i++) {
    batch4.set(firestore.collection('legal_appointments').doc('APT-${(i+1).toString().padLeft(3,'0')}'), appointments[i]);
  }

  // ════════════════════════════════════════════════════════════════
  // ─── LEASES ───
  // ════════════════════════════════════════════════════════════════
  final leases = <Map<String, dynamic>>[
    {'propertyId': 'PROP-001', 'tenantName': 'Global Logistics Corp', 'leaseStart': iso(365), 'leaseEnd': iso(-365), 'monthlyRent': 250000, 'status': 'Active', 'siteId': siteA, 'createdAt': iso(365)},
    {'propertyId': 'PROP-001', 'tenantName': 'Tech Startups Inc', 'leaseStart': iso(180), 'leaseEnd': iso(-540), 'monthlyRent': 45000, 'status': 'Active', 'siteId': siteA, 'createdAt': iso(180)},
    {'propertyId': 'PROP-002', 'tenantName': 'Industrial Supplies Ltd', 'leaseStart': iso(200), 'leaseEnd': iso(10), 'monthlyRent': 85000, 'status': 'Expiring Soon', 'siteId': siteA, 'createdAt': iso(200)},
  ];
  for (var i = 0; i < leases.length; i++) {
    batch4.set(firestore.collection('property_leases').doc('LSE-${(i+1).toString().padLeft(3,'0')}'), leases[i]);
  }

  // ════════════════════════════════════════════════════════════════
  // ─── ASSETS ───
  // ════════════════════════════════════════════════════════════════
  final assets = <Map<String, dynamic>>[
    {'propertyId': 'PROP-001', 'assetName': 'Primary Elevator Bank A', 'category': 'Vertical Transport', 'condition': 'Good', 'purchaseDate': iso(1000), 'value': 2500000, 'status': 'Operational', 'siteId': siteA, 'createdAt': iso(1000)},
    {'propertyId': 'PROP-001', 'assetName': 'Central Cooling Plant', 'category': 'HVAC', 'condition': 'Fair', 'purchaseDate': iso(800), 'value': 4500000, 'status': 'Maintenance Required', 'siteId': siteA, 'createdAt': iso(800)},
    {'propertyId': 'PROP-002', 'assetName': 'Industrial Racking System', 'category': 'Equipment', 'condition': 'Excellent', 'purchaseDate': iso(200), 'value': 1200000, 'status': 'Operational', 'siteId': siteA, 'createdAt': iso(200)},
  ];
  for (var i = 0; i < assets.length; i++) {
    batch4.set(firestore.collection('property_assets').doc('AST-${(i+1).toString().padLeft(3,'0')}'), assets[i]);
  }

  await batch4.commit();
}
