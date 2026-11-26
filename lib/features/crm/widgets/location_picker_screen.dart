import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../../../core/theme/app_colors.dart';
import 'event_location.dart';
import 'location_service.dart';

class LocationPickerScreen extends StatefulWidget {
  final EventLocation? initialLocation;
  final String? capturedBy;

  const LocationPickerScreen({
    super.key,
    this.initialLocation,
    this.capturedBy,
  });

  @override
  State<LocationPickerScreen> createState() => _LocationPickerScreenState();
}

class _LocationPickerScreenState extends State<LocationPickerScreen> {
  // Centro padrão (São Paulo) caso ainda não haja localização inicial nem GPS
  static const _defaultCenter = LatLng(-23.55052, -46.633308);

  final MapController _mapController = MapController();
  final LocationService _locationService = LocationService();
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();

  late LatLng _selectedPoint;
  bool _hasSelection = false;
  bool _isLocating = false;
  bool _isResolvingAddress = false;
  bool _isSearching = false;
  List<AddressSuggestion> _suggestions = const [];

  @override
  void initState() {
    super.initState();
    final initial = widget.initialLocation;
    if (initial != null && initial.isValid) {
      _selectedPoint = initial.latLng;
      _hasSelection = true;
      _addressController.text = initial.address;
    } else {
      _selectedPoint = _defaultCenter;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _captureCurrentGps(silentOnError: true);
      });
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _addressController.dispose();
    _mapController.dispose();
    super.dispose();
  }

  Future<void> _captureCurrentGps({bool silentOnError = false}) async {
    if (_isLocating) return;
    setState(() {
      _isLocating = true;
      _suggestions = const [];
    });

    try {
      final point = await _locationService.getCurrentPosition();
      if (!mounted) return;
      await _selectPoint(point, zoom: 17);
    } catch (e) {
      if (!mounted || silentOnError) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    } finally {
      if (mounted) {
        setState(() => _isLocating = false);
      }
    }
  }

  Future<void> _selectPoint(LatLng point, {double? zoom}) async {
    setState(() {
      _selectedPoint = point;
      _hasSelection = true;
      _isResolvingAddress = true;
      _suggestions = const [];
    });

    _mapController.move(point, zoom ?? _mapController.camera.zoom);

    final address = await _locationService.reverseGeocode(
      point.latitude,
      point.longitude,
    );
    if (!mounted) return;
    setState(() {
      _addressController.text = address;
      _isResolvingAddress = false;
    });
  }

  Future<void> _searchAddress() async {
    final query = _searchController.text.trim();
    if (query.length < 3) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Digite ao menos 3 caracteres para buscar um endereço.'),
        ),
      );
      return;
    }

    setState(() => _isSearching = true);
    try {
      final results = await _locationService.searchAddress(query);
      if (!mounted) return;
      setState(() => _suggestions = results);
      if (results.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Nenhum endereço encontrado. Tente ajustar a busca ou toque no mapa.'),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    } finally {
      if (mounted) setState(() => _isSearching = false);
    }
  }

  void _confirmSelection() {
    if (!_hasSelection) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Toque no mapa ou use o GPS para marcar o local.'),
        ),
      );
      return;
    }

    final result = EventLocation(
      latitude: _selectedPoint.latitude,
      longitude: _selectedPoint.longitude,
      address: _addressController.text.trim(),
      capturedAt: DateTime.now(),
      capturedBy: widget.capturedBy,
    );
    Navigator.pop(context, result);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Marcar Localização no Mapa',
          style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
        ),
        actions: [
          TextButton.icon(
            onPressed: _hasSelection ? _confirmSelection : null,
            icon: const Icon(Icons.check),
            label: const Text('Confirmar'),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    textInputAction: TextInputAction.search,
                    onSubmitted: (_) => _searchAddress(),
                    decoration: InputDecoration(
                      hintText: 'Buscar rua, número, bairro ou cidade...',
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: _isSearching
                          ? const Padding(
                              padding: EdgeInsets.all(12),
                              child: SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              ),
                            )
                          : IconButton(
                              tooltip: 'Buscar endereço',
                              icon: const Icon(Icons.arrow_forward),
                              onPressed: _searchAddress,
                            ),
                      isDense: true,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Tooltip(
                  message: 'Capturar minha localização atual (GPS)',
                  child: FilledButton.icon(
                    onPressed: _isLocating ? null : () => _captureCurrentGps(),
                    icon: _isLocating
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.my_location, size: 18),
                    label: const Text('GPS'),
                  ),
                ),
              ],
            ),
          ),
          if (_suggestions.isNotEmpty)
            Container(
              constraints: const BoxConstraints(maxHeight: 180),
              margin: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white12),
              ),
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: _suggestions.length,
                separatorBuilder: (_, _) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final item = _suggestions[index];
                  return ListTile(
                    dense: true,
                    leading: Icon(
                      Icons.place_outlined,
                      color: theme.colorScheme.primary,
                    ),
                    title: Text(
                      item.displayName,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 13),
                    ),
                    onTap: () async {
                      FocusScope.of(context).unfocus();
                      setState(() {
                        _selectedPoint = item.latLng;
                        _hasSelection = true;
                        _addressController.text = item.displayName;
                        _suggestions = const [];
                      });
                      _mapController.move(item.latLng, 17);
                    },
                  );
                },
              ),
            ),
          Expanded(
            child: Stack(
              children: [
                FlutterMap(
                  mapController: _mapController,
                  options: MapOptions(
                    initialCenter: _selectedPoint,
                    initialZoom: _hasSelection ? 17 : 13,
                    onTap: (_, point) => _selectPoint(point),
                  ),
                  children: [
                    TileLayer(
                      urlTemplate:
                          'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      userAgentPackageName: 'com.example.ul_business',
                    ),
                    if (_hasSelection)
                      MarkerLayer(
                        markers: [
                          Marker(
                            point: _selectedPoint,
                            width: 48,
                            height: 48,
                            alignment: Alignment.topCenter,
                            child: Icon(
                              Icons.location_on,
                              size: 44,
                              color: theme.colorScheme.primary,
                              shadows: const [
                                Shadow(
                                  blurRadius: 8,
                                  color: Colors.black54,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
                Positioned(
                  top: 12,
                  left: 12,
                  right: 12,
                  child: IgnorePointer(
                    child: Center(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.7),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Text(
                          'Toque no mapa para ajustar o pino do local',
                          style: TextStyle(fontSize: 12, color: Colors.white),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            decoration: BoxDecoration(
              color: context.tokens.surfaceElevated1,
              border: Border(
                top: BorderSide(color: context.tokens.borderSubtle),
              ),
            ),
            child: SafeArea(
              top: false,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.pin_drop,
                        size: 16,
                        color: _hasSelection
                            ? context.tokens.success
                            : context.tokens.textSecondary,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          _hasSelection
                              ? 'Coordenadas: ${_selectedPoint.latitude.toStringAsFixed(6)}, ${_selectedPoint.longitude.toStringAsFixed(6)}'
                              : 'Nenhuma posição selecionada ainda',
                          style: TextStyle(
                            fontSize: 12,
                            color: context.tokens.textSecondary,
                          ),
                        ),
                      ),
                      if (_isResolvingAddress)
                        const SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _addressController,
                    maxLines: 2,
                    minLines: 1,
                    decoration: InputDecoration(
                      labelText: 'Endereço / Ponto de referência',
                      hintText: 'Ex: Av. Paulista, 1000 - Portão lateral',
                      isDense: true,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    height: 46,
                    child: FilledButton.icon(
                      onPressed: _hasSelection ? _confirmSelection : null,
                      icon: const Icon(Icons.check_circle_outline),
                      label: const Text('Usar esta localização'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
