import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../config/theme.dart';
import '../providers/property_providers.dart';
import '../../../core/utils/ui_utils.dart';
import '../widgets/property_assets_tab.dart';
import '../widgets/property_operations_tab.dart';
import '../widgets/property_facility_tab.dart';
import '../widgets/property_esg_tab.dart';
import '../widgets/property_leases_tab.dart';
import '../widgets/property_hero_header.dart';

class PropertyDetailsScreen extends ConsumerStatefulWidget {
  final String propertyId;
  const PropertyDetailsScreen({super.key, required this.propertyId});

  @override
  ConsumerState<PropertyDetailsScreen> createState() =>
      _PropertyDetailsScreenState();
}

class _PropertyDetailsScreenState extends ConsumerState<PropertyDetailsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final propertiesAsync = ref.watch(propertiesProvider);

    return propertiesAsync.when(
      data: (properties) {
        final property = properties.firstWhere(
          (p) => p.id == widget.propertyId,
          orElse: () => throw 'Property not found',
        );
        return Scaffold(
          appBar: AppBar(
            title: Text(
              property.name,
              style: const TextStyle(fontWeight: FontWeight.w900),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.edit_outlined),
                onPressed: () {
                  UIUtils.showToast(context, 'Edit Property form opened');
                },
              ),
              IconButton(
                icon: const Icon(Icons.share_outlined),
                onPressed: () {
                  UIUtils.showToast(context, 'Share Property dialog opened');
                },
              ),
            ],
          ),
          body: Column(
            children: [
              PropertyHeroHeader(property: property),
              TabBar(
                controller: _tabController,
                labelColor: XMTheme.secondary,
                unselectedLabelColor: Colors.grey,
                indicatorColor: XMTheme.secondary,
                indicatorWeight: 3,
                isScrollable: true,
                tabs: const [
                  Tab(text: 'OPERATIONS'),
                  Tab(text: 'FACILITY MGMT'),
                  Tab(text: 'ASSETS'),
                  Tab(text: 'LEASES'),
                  Tab(text: 'ESG & UTILITIES'),
                ],
              ),
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    PropertyOperationsTab(property: property),
                    PropertyFacilityTab(property: property),
                    PropertyAssetsTab(property: property),
                    PropertyLeasesTab(property: property),
                    PropertyEsgTab(property: property),
                  ],
                ),
              ),
            ],
          ),
        );
      },
      loading:
          () =>
              const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (err, _) => Scaffold(body: Center(child: Text('Error: $err'))),
    );
  }
}
