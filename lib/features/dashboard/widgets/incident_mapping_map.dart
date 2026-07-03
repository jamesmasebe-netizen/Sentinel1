import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:go_router/go_router.dart';
import '../../property/providers/property_providers.dart';

class IncidentMappingMap extends ConsumerWidget {
  const IncidentMappingMap({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final propertiesAsync = ref.watch(propertiesProvider);
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(16),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: propertiesAsync.when(
          data: (properties) {
            final markers =
                properties
                    .map(
                      (p) => Marker(
                        markerId: MarkerId(p.id),
                        position: LatLng(p.lat, p.lng),
                        infoWindow: InfoWindow(
                          title: p.name,
                          snippet: p.type,
                        ),
                        onTap: () => context.go('/properties'),
                      ),
                    )
                    .toSet();

            return GoogleMap(
              initialCameraPosition: const CameraPosition(
                target: LatLng(-26.1075, 28.0567),
                zoom: 10,
              ),
              markers: markers,
              zoomControlsEnabled: false,
              mapToolbarEnabled: false,
              myLocationButtonEnabled: false,
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error:
              (_, __) => const Center(
                child: Icon(
                  Icons.map_outlined,
                  color: Colors.white24,
                  size: 48,
                ),
              ),
        ),
      ),
    );
  }
}
