import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:go_router/go_router.dart';
import '../../../config/theme.dart';
import '../models/property_models.dart';
import '../../../core/widgets/ds_widgets.dart';

class PropertyMapCard extends StatelessWidget {
  final AsyncValue<List<Property>> propertiesAsync;
  
  const PropertyMapCard({super.key, required this.propertiesAsync});

  @override
  Widget build(BuildContext context) {
    const initialPosition = LatLng(-26.1075, 28.0567); // JHB focus

    return GCard(
      padding: EdgeInsets.zero,
      child: Container(
        height: 400,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(XMTheme.radiusXl),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(XMTheme.radiusXl),
          child: propertiesAsync.when(
            data: (properties) {
              final markers = properties.map((p) => Marker(
                markerId: MarkerId(p.id),
                position: LatLng(p.lat, p.lng),
                infoWindow: InfoWindow(title: p.name, snippet: p.type),
                onTap: () => context.push('/property/${p.id}'),
              )).toSet();

              return GoogleMap(
                initialCameraPosition: const CameraPosition(target: initialPosition, zoom: 10),
                markers: markers,
                myLocationEnabled: false,
                zoomControlsEnabled: true,
                mapToolbarEnabled: false,
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (_, __) => const Center(child: Icon(Icons.map_outlined, size: 64, color: Colors.grey)),
          ),
        ),
      ),
    );
  }
}
