import 'bpf_models.dart';

final procureToPayDefinition = BpfDefinition(
  id: 'procure_to_pay',
  title: 'Procure to Pay',
  stages: [
    BpfStageDefinition(
      id: 'requisition',
      title: 'Requisition',
      description: 'Department requests items needed.',
      expectedRecordType: 'purchase_order',
    ),
    BpfStageDefinition(
      id: 'purchase_order',
      title: 'Purchase Order',
      description: 'Approved request converts to purchase order.',
      expectedRecordType: 'purchase_order',
    ),
    BpfStageDefinition(
      id: 'goods_receipt',
      title: 'Goods Receipt',
      description: 'Items arrive at warehouse.',
      expectedRecordType: 'purchase_order',
    ),
    BpfStageDefinition(
      id: 'ap_invoice',
      title: 'AP Invoice',
      description: 'Finance receives bill from vendor.',
      expectedRecordType: 'invoice',
    ),
    BpfStageDefinition(
      id: 'payment',
      title: 'Payment',
      description: 'Finance marks bill as paid.',
      expectedRecordType: 'invoice',
    ),
  ],
);
