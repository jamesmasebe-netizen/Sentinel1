import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/crm_models.dart';
import '../services/crm_service.dart';

final accountsProvider = StateProvider<List<Account>>((ref) => []);
final contactsProvider = StateProvider<List<Contact>>((ref) => []);
final opportunitiesProvider = StateProvider<List<Opportunity>>((ref) => []);
final quotesProvider = StateProvider<List<Quote>>((ref) => []);

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
  (ref, id) => ref.watch(crmServiceProvider).getAccount(id).asStream(),
);
final leadsStreamProvider = StreamProvider<List<Lead>>(
  (ref) => ref.watch(crmServiceProvider).streamLeads(),
);
final campaignsStreamProvider = StreamProvider<List<Campaign>>(
  (ref) => ref.watch(crmServiceProvider).streamCampaigns(),
);
