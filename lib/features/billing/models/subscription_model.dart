import 'package:cloud_firestore/cloud_firestore.dart';

class TenantSubscription {
  final String status;
  final DateTime currentPeriodEnd;
  final String tier;
  final String stripeSubscriptionId;

  TenantSubscription({
    required this.status,
    required this.currentPeriodEnd,
    required this.tier,
    required this.stripeSubscriptionId,
  });

  factory TenantSubscription.fromJson(Map<String, dynamic> json) {
    DateTime parsedDate;
    final dynamic dateVal = json['currentPeriodEnd'];
    if (dateVal is Timestamp) {
      parsedDate = dateVal.toDate();
    } else if (dateVal is String) {
      parsedDate = DateTime.parse(dateVal);
    } else {
      parsedDate = DateTime.now();
    }

    return TenantSubscription(
      status: json['status'] as String? ?? '',
      currentPeriodEnd: parsedDate,
      tier: json['tier'] as String? ?? 'free',
      stripeSubscriptionId: json['stripeSubscriptionId'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'status': status,
      'currentPeriodEnd': Timestamp.fromDate(currentPeriodEnd),
      'tier': tier,
      'stripeSubscriptionId': stripeSubscriptionId,
    };
  }
}
