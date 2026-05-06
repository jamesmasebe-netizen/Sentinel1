import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../config/theme.dart';
import '../providers/property_providers.dart';
import '../models/property_models.dart';

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
                onPressed: () {},
              ),
              IconButton(
                icon: const Icon(Icons.share_outlined),
                onPressed: () {},
              ),
            ],
          ),
          body: Column(
            children: [
              _buildHeroHeader(property),
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
                    _buildOperationsTab(property),
                    _buildFacilityTab(property),
                    _buildAssetsTab(property),
                    _buildLeasesTab(property),
                    _buildESGTab(property),
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

  Widget _buildHeroHeader(Property property) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [XMTheme.primary, XMTheme.primary.withValues(alpha: 0.8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(XMTheme.radiusLg),
              image: const DecorationImage(
                image: NetworkImage(
                  'https://images.unsplash.com/photo-1486406146926-c627a92ad1ab?auto=format&fit=crop&q=80&w=300',
                ),
                fit: BoxFit.cover,
              ),
            ),
          ),
          const SizedBox(width: 24),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      property.type,
                      style: TextStyle(
                        color: XMTheme.secondaryLight,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      width: 4,
                      height: 4,
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      property.status,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  property.name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(
                      Icons.location_on_outlined,
                      color: Colors.white70,
                      size: 14,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      property.address,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 32,
                  runSpacing: 16,
                  children: [
                    _buildHeroStat('AREA', property.totalArea),
                    _buildHeroStat('FLOORS', property.floors.toString()),
                    _buildHeroStat(
                      'COMPLIANCE',
                      '${property.complianceScore}%',
                    ),
                    _buildHeroStat('ASSETS', property.totalAssets.toString()),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeroStat(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(right: 32.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: Colors.white54,
              fontSize: 10,
              fontWeight: FontWeight.bold,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOperationsTab(Property property) {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        _buildSectionHeader('Live Occupancy', Icons.people_outline),
        _buildOccupancyCard(property),
        const SizedBox(height: 32),
        _buildSectionHeader('Linked Incidents', Icons.warning_amber_rounded),
        const Text(
          'Displaying recent safety events at this location',
          style: TextStyle(color: Colors.grey, fontSize: 13),
        ),
        const SizedBox(height: 16),
        _buildLinkedEventsList('incidents', property.name),
        const SizedBox(height: 32),
        _buildSectionHeader('Active Permits', Icons.assignment_outlined),
        _buildLinkedEventsList('permits', property.name),
      ],
    );
  }

  Widget _buildFacilityTab(Property property) {
    final projectsAsync = ref.watch(propertyProjectsProvider(property.id));
    final appointmentsAsync = ref.watch(
      propertyAppointmentsProvider(property.id),
    );

    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        _buildSectionHeader(
          'Facility Projects & Maintenance',
          Icons.build_circle_outlined,
        ),
        projectsAsync.when(
          data:
              (projects) => Column(
                children: projects.map((p) => _buildProjectCard(p)).toList(),
              ),
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, _) => Text('Error: $err'),
        ),
        const SizedBox(height: 32),
        _buildSectionHeader('Legal Appointments', Icons.verified_user_outlined),
        appointmentsAsync.when(
          data:
              (appointments) => GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  childAspectRatio: 3,
                ),
                itemCount: appointments.length,
                itemBuilder:
                    (context, index) =>
                        _buildAppointmentCard(appointments[index]),
              ),
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, _) => Text('Error: $err'),
        ),
      ],
    );
  }

  Widget _buildESGTab(Property property) {
    final utilitiesAsync = ref.watch(propertyUtilitiesProvider(property.id));

    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        _buildSectionHeader(
          'Environmental Impact & Utilities',
          Icons.eco_outlined,
        ),
        utilitiesAsync.when(
          data:
              (data) => Column(
                children: [
                  _buildUtilityCard(
                    'Electricity (kWh)',
                    data.map((d) => d.electricity).toList(),
                    XMTheme.warning,
                  ),
                  const SizedBox(height: 24),
                  _buildUtilityCard(
                    'Water (kL)',
                    data.map((d) => d.water).toList(),
                    Colors.blue,
                  ),
                  const SizedBox(height: 24),
                  _buildUtilityCard(
                    'Carbon Footprint (tCO2e)',
                    data.map((d) => d.carbon).toList(),
                    XMTheme.error,
                  ),
                ],
              ),
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, _) => Text('Error: $err'),
        ),
      ],
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        children: [
          Icon(icon, color: XMTheme.primary, size: 20),
          const SizedBox(width: 8),
          Text(
            title,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildOccupancyCard(Property property) {
    double percent = property.occupancy / property.capacity;
    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(XMTheme.radiusLg),
        side: BorderSide(color: Colors.grey.withValues(alpha: 0.1)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${property.occupancy}',
                      style: const TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const Text(
                      'Current Souls on Site',
                      style: TextStyle(
                        color: Colors.grey,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
                Text(
                  '/ ${property.capacity} limit',
                  style: const TextStyle(color: Colors.grey, fontSize: 14),
                ),
              ],
            ),
            const SizedBox(height: 20),
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: LinearProgressIndicator(
                value: percent,
                minHeight: 12,
                backgroundColor: Colors.grey.withValues(alpha: 0.1),
                valueColor: AlwaysStoppedAnimation<Color>(
                  percent > 0.9 ? XMTheme.error : XMTheme.success,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLinkedEventsList(String collection, String location) {
    // Simplified placeholder for linked events
    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      color: Colors.grey.withValues(alpha: 0.05),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(XMTheme.radiusLg),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            const Icon(Icons.info_outline, color: Colors.grey),
            const SizedBox(width: 12),
            Text(
              '3 items linked to "$location"',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            const Spacer(),
            TextButton(onPressed: () {}, child: const Text('View Details')),
          ],
        ),
      ),
    );
  }

  Widget _buildProjectCard(PropertyProject project) {
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(XMTheme.radiusLg),
        side: BorderSide(color: Colors.grey.withValues(alpha: 0.1)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: XMTheme.secondary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.settings_suggest_outlined,
                color: XMTheme.secondary,
                size: 20,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    project.title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  Text(
                    '${project.type} • Assigned to ${project.assignedTo}',
                    style: const TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${project.progress}%',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: XMTheme.secondary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  project.status,
                  style: const TextStyle(
                    color: Colors.grey,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAppointmentCard(LegalAppointment appointment) {
    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(XMTheme.radiusLg),
        side: BorderSide(color: Colors.grey.withValues(alpha: 0.1)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: XMTheme.success.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.person, color: XMTheme.success, size: 16),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    appointment.role,
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey,
                    ),
                  ),
                  Text(
                    appointment.personName,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.check_circle,
              color:
                  appointment.status == 'Appointed'
                      ? XMTheme.success
                      : XMTheme.warning,
              size: 16,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUtilityCard(String title, List<double> values, Color color) {
    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(XMTheme.radiusLg),
        side: BorderSide(color: Colors.grey.withValues(alpha: 0.1)),
      ),
      child: Container(
        height: 200,
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
            const Spacer(),
            SizedBox(
              height: 100,
              child: LineChart(
                LineChartData(
                  gridData: const FlGridData(show: false),
                  titlesData: const FlTitlesData(show: false),
                  borderData: FlBorderData(show: false),
                  lineBarsData: [
                    LineChartBarData(
                      spots:
                          values
                              .asMap()
                              .entries
                              .map((e) => FlSpot(e.key.toDouble(), e.value))
                              .toList(),
                      isCurved: true,
                      color: color,
                      barWidth: 3,
                      isStrokeCapRound: true,
                      dotData: const FlDotData(show: false),
                      belowBarData: BarAreaData(
                        show: true,
                        color: color.withValues(alpha: 0.1),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAssetsTab(Property property) {
    final assetsAsync = ref.watch(propertyAssetsProvider(property.id));

    return assetsAsync.when(
      data:
          (assets) => ListView(
            padding: const EdgeInsets.all(24),
            children: [
              _buildSectionHeader(
                'CRITICAL ASSETS',
                Icons.inventory_2_outlined,
              ),
              const SizedBox(height: 16),
              if (assets.isEmpty)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(32),
                    child: Text(
                      'No assets recorded',
                      style: TextStyle(color: Colors.grey),
                    ),
                  ),
                )
              else
                ...assets.map(
                  (asset) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _buildAssetCard(asset),
                  ),
                ),
            ],
          ),
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, _) => Center(child: Text('Error: $err')),
    );
  }

  Widget _buildLeasesTab(Property property) {
    final leasesAsync = ref.watch(propertyLeasesProvider(property.id));

    return leasesAsync.when(
      data:
          (leases) => ListView(
            padding: const EdgeInsets.all(24),
            children: [
              _buildSectionHeader('TENANT LEASES', Icons.description_outlined),
              const SizedBox(height: 16),
              if (leases.isEmpty)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(32),
                    child: Text(
                      'No leases recorded',
                      style: TextStyle(color: Colors.grey),
                    ),
                  ),
                )
              else
                ...leases.map(
                  (lease) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _buildLeaseCard(lease),
                  ),
                ),
            ],
          ),
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, _) => Center(child: Text('Error: $err')),
    );
  }

  Widget _buildAssetCard(AssetInfo asset) {
    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(XMTheme.radiusLg),
        side: BorderSide(color: Colors.grey.withValues(alpha: 0.1)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: XMTheme.primary.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(XMTheme.radiusSm),
              ),
              child: const Icon(
                Icons.inventory_2_outlined,
                color: XMTheme.primary,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    asset.category.toUpperCase(),
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    asset.name,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text(
                        'Condition: ',
                        style: const TextStyle(
                          color: Colors.grey,
                          fontSize: 12,
                        ),
                      ),
                      Text(
                        asset.condition,
                        style: TextStyle(
                          color:
                              asset.condition == 'Good' ||
                                      asset.condition == 'Excellent'
                                  ? XMTheme.success
                                  : XMTheme.warning,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color:
                        asset.condition == 'Operational' ||
                                asset.condition == 'Good'
                            ? XMTheme.success.withValues(alpha: 0.1)
                            : XMTheme.warning.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(XMTheme.radiusXl),
                  ),
                  child: Text(
                    asset.condition.toUpperCase(),
                    style: TextStyle(
                      color:
                          asset.condition == 'Operational' ||
                                  asset.condition == 'Good'
                              ? XMTheme.success
                              : XMTheme.warning,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLeaseCard(LeaseInfo lease) {
    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(XMTheme.radiusLg),
        side: BorderSide(color: Colors.grey.withValues(alpha: 0.1)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  lease.tenantName,
                  style: const TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 16,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color:
                        lease.status == 'Active'
                            ? XMTheme.success.withValues(alpha: 0.1)
                            : XMTheme.warning.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(XMTheme.radiusXl),
                  ),
                  child: Text(
                    lease.status.toUpperCase(),
                    style: TextStyle(
                      color:
                          lease.status == 'Active'
                              ? XMTheme.success
                              : XMTheme.warning,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                _buildLeaseDetail(
                  Icons.calendar_today_outlined,
                  'Start',
                  lease.startDate.toIso8601String().split('T')[0],
                ),
                const SizedBox(width: 24),
                _buildLeaseDetail(
                  Icons.event_busy_outlined,
                  'End',
                  lease.endDate.toIso8601String().split('T')[0],
                ),
                const SizedBox(width: 24),
                _buildLeaseDetail(
                  Icons.payments_outlined,
                  'Monthly',
                  '\$${(lease.monthlyRent / 1000).toStringAsFixed(0)}k',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLeaseDetail(IconData icon, String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 12, color: Colors.grey),
            const SizedBox(width: 4),
            Text(
              label.toUpperCase(),
              style: const TextStyle(
                fontSize: 10,
                color: Colors.grey,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
        ),
      ],
    );
  }
}
