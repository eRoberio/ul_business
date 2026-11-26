import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import 'event_location.dart';
import 'location_service.dart';

Future<void> showLocationNavigationSheet(
  BuildContext context, {
  required EventLocation location,
  required String title,
}) {
  final service = LocationService();

  return showModalBottomSheet<void>(
    context: context,
    useSafeArea: true,
    backgroundColor: context.tokens.surfaceElevated1,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (sheetContext) {
      final tokens = sheetContext.tokens;

      Future<void> abrir(Future<bool> Function() launcher, String app) async {
        final ok = await launcher();
        if (!sheetContext.mounted) return;
        Navigator.pop(sheetContext);
        if (!ok && context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Não foi possível abrir o $app.')),
          );
        }
      }

      return Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.directions, color: tokens.success),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Navegar até $title',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: tokens.textPrimary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.close, color: tokens.textSecondary),
                  onPressed: () => Navigator.pop(sheetContext),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              location.displayAddress,
              style: TextStyle(fontSize: 13, color: tokens.textPrimary),
            ),
            const SizedBox(height: 4),
            Text(
              'GPS: ${location.coordinatesLabel}',
              style: TextStyle(fontSize: 11, color: tokens.textSecondary),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: FilledButton.icon(
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.wazeAccent,
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    onPressed: () =>
                        abrir(() => service.openInWaze(location), 'Waze'),
                    icon: const Icon(Icons.navigation),
                    label: const Text(
                      'Abrir no Waze',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      side: BorderSide(color: tokens.success),
                      foregroundColor: tokens.success,
                    ),
                    onPressed: () => abrir(
                      () => service.openInGoogleMaps(location),
                      'Google Maps',
                    ),
                    icon: const Icon(Icons.map_outlined),
                    label: const Text(
                      'Google Maps',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    },
  );
}

class LocationActionButtons extends StatelessWidget {
  final EventLocation location;
  final String empresaNome;
  final bool compact;

  const LocationActionButtons({
    super.key,
    required this.location,
    required this.empresaNome,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final service = LocationService();

    Future<void> launch(Future<bool> Function() fn, String app) async {
      final ok = await fn();
      if (!ok && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Não foi possível abrir o $app.')),
        );
      }
    }

    if (compact) {
      return OutlinedButton.icon(
        style: OutlinedButton.styleFrom(
          visualDensity: VisualDensity.compact,
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          side: BorderSide(color: tokens.primary.withValues(alpha: 0.4)),
          foregroundColor: tokens.primary,
        ),
        onPressed: () => showLocationNavigationSheet(
          context,
          location: location,
          title: empresaNome,
        ),
        icon: const Icon(Icons.directions, size: 15),
        label: const Text('Ir ao local', style: TextStyle(fontSize: 12)),
      );
    }

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        FilledButton.icon(
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.wazeAccent,
            foregroundColor: Colors.black,
            visualDensity: VisualDensity.compact,
          ),
          onPressed: () => launch(() => service.openInWaze(location), 'Waze'),
          icon: const Icon(Icons.navigation, size: 16),
          label: const Text(
            'Waze',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
          ),
        ),
        OutlinedButton.icon(
          style: OutlinedButton.styleFrom(
            visualDensity: VisualDensity.compact,
            side: BorderSide(color: tokens.success),
            foregroundColor: tokens.success,
          ),
          onPressed: () => launch(
            () => service.openInGoogleMaps(location),
            'Google Maps',
          ),
          icon: const Icon(Icons.map_outlined, size: 16),
          label: const Text(
            'Google Maps',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
          ),
        ),
      ],
    );
  }
}
