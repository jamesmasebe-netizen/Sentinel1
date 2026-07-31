import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/crm_models.dart';
import '../services/crm_service.dart';

final opportunityStreamProvider = StreamProvider.family<Opportunity?, String>((
  ref,
  id,
) {
  return ref.watch(crmServiceProvider).streamOpportunity(id);
});

final leadStreamProvider = StreamProvider.family<Lead?, String>((ref, id) {
  return ref.watch(crmServiceProvider).streamLead(id);
});

final quoteStreamProvider = StreamProvider.family<Quote?, String>((ref, id) {
  return ref.watch(crmServiceProvider).streamQuote(id);
});

final opportunityQuotesStreamProvider =
    StreamProvider.family<List<Quote>, String>((ref, opportunityId) {
      return ref.watch(crmServiceProvider).streamQuotes(opportunityId);
    });

final accountsStreamProvider = StreamProvider<List<Account>>(
  (ref) => ref.watch(crmServiceProvider).streamAccounts(),
);
final accountStreamProvider = StreamProvider.family<Account?, String>(
  (ref, id) => ref.watch(crmServiceProvider).streamAccount(id),
);
final leadsStreamProvider = StreamProvider<List<Lead>>(
  (ref) => ref.watch(crmServiceProvider).streamLeads(),
);
final campaignsStreamProvider = StreamProvider<List<Campaign>>(
  (ref) => ref.watch(crmServiceProvider).streamCampaigns(),
);
final opportunitiesStreamProvider = StreamProvider<List<Opportunity>>(
  (ref) => ref.watch(crmServiceProvider).streamOpportunities(),
);
final contactsStreamProvider = StreamProvider.family<List<Contact>, String>((ref, accountId) {
  if (accountId.isEmpty) return Stream.value([]);
  return ref.watch(crmServiceProvider).streamContacts(accountId);
});

