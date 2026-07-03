import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/account.dart';
import '../models/contact.dart';
import '../models/opportunity.dart';
import '../models/quote.dart';

final accountsProvider = StateProvider<List<Account>>((ref) => []);
final contactsProvider = StateProvider<List<Contact>>((ref) => []);
final opportunitiesProvider = StateProvider<List<Opportunity>>((ref) => []);
final quotesProvider = StateProvider<List<Quote>>((ref) => []);
