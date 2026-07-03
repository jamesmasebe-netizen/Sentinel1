import 'package:cloud_firestore/cloud_firestore.dart';

enum SubscriptionTier { free, pro, enterprise }

extension SubscriptionTierX on SubscriptionTier {
  String get name {
    switch (this) {
      case SubscriptionTier.free:
        return 'free';
      case SubscriptionTier.pro:
        return 'pro';
      case SubscriptionTier.enterprise:
        return 'enterprise';
    }
  }

  static SubscriptionTier fromString(String tier) {
    switch (tier.toLowerCase()) {
      case 'pro':
        return SubscriptionTier.pro;
      case 'enterprise':
        return SubscriptionTier.enterprise;
      case 'free':
      default:
        return SubscriptionTier.free;
    }
  }
}

class TenantSubscription {
  final String id;
  final String tenantId;
  final SubscriptionTier tier;
  final String status;
  final String? stripeCustomerId;
  final String? stripeSubscriptionId;
  final DateTime? currentPeriodEnd;

  TenantSubscription({
    required this.id,
    required this.tenantId,
    required this.tier,
    required this.status,
    this.stripeCustomerId,
    this.stripeSubscriptionId,
    this.currentPeriodEnd,
  });

  factory TenantSubscription.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>?;
    if (data == null) {
      return TenantSubscription(
        id: doc.id,
        tenantId: '',
        tier: SubscriptionTier.free,
        status: 'inactive',
      );
    }

    final currentPeriodEndData = data['currentPeriodEnd'];
    DateTime? currentPeriodEnd;
    if (currentPeriodEndData is Timestamp) {
      currentPeriodEnd = currentPeriodEndData.toDate();
    } else if (currentPeriodEndData is String) {
      currentPeriodEnd = DateTime.tryParse(currentPeriodEndData);
    }

    return TenantSubscription(
      id: doc.id,
      tenantId: data['tenantId'] as String? ?? '',
      tier: SubscriptionTierX.fromString(data['tier'] as String? ?? 'free'),
      status: data['status'] as String? ?? 'inactive',
      stripeCustomerId: data['stripeCustomerId'] as String?,
      stripeSubscriptionId: data['stripeSubscriptionId'] as String?,
      currentPeriodEnd: currentPeriodEnd,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'tenantId': tenantId,
      'tier': tier.name,
      'status': status,
      if (stripeCustomerId != null) 'stripeCustomerId': stripeCustomerId,
      if (stripeSubscriptionId != null)
        'stripeSubscriptionId': stripeSubscriptionId,
      if (currentPeriodEnd != null)
        'currentPeriodEnd': Timestamp.fromDate(currentPeriodEnd!),
    };
  }

  TenantSubscription copyWith({
    String? id,
    String? tenantId,
    SubscriptionTier? tier,
    String? status,
    String? stripeCustomerId,
    String? stripeSubscriptionId,
    DateTime? currentPeriodEnd,
  }) {
    return TenantSubscription(
      id: id ?? this.id,
      tenantId: tenantId ?? this.tenantId,
      tier: tier ?? this.tier,
      status: status ?? this.status,
      stripeCustomerId: stripeCustomerId ?? this.stripeCustomerId,
      stripeSubscriptionId: stripeSubscriptionId ?? this.stripeSubscriptionId,
      currentPeriodEnd: currentPeriodEnd ?? this.currentPeriodEnd,
    );
  }
}
