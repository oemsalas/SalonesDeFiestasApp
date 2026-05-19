import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:intl/intl.dart';
import '../models/salon_model.dart';
import '../services/api_service.dart';
import '../services/location_service.dart';
import '../theme/app_theme.dart';
import '../widgets/salon_card.dart';
import '../widgets/panel_filtros.dart';
import '../widgets/marker_salon.dart';
import '../widgets/detalle_salon_sheet.dart';
import '../widgets/salon_swiper.dart';

class MapaScreen extends StatefulWidget {
  const MapaScreen({super.key});

  @override
  State<MapaScreen> createState() => _MapaScreenState();
}

class _MapaScreenState extends State<MapaScreen>
    with TickerProviderStateMixin {
  // Controladores
  final MapController _mapController = MapController();
  final DraggableScrollableController _sheetController =
  DraggableScrollableController();

  // Estado
  LatLng? _miUbicacion;
  List<Salon> _salones = [];
  Map<int, bool> _disponibilidadMap = {};
  Map<int, double> _distanciasMap = {};
  FiltrosBusqueda _filtros = FiltrosBusqueda();
  Salon? _salonSeleccionado;

  // Loading states
  bool _cargandoUbicacion = true;
  bool _buscando = false;
  String? _errorMensaje;

  // Vista: 'mapa' | 'lista' | 'swiper'
  String _vista = 'mapa';

  @override
  void initState() {
    super.initState();
    _iniciarUbicacion();
  }

  Future<void> _iniciarUbicacion() async {
    setState(() {
      _cargandoUbicacion = true;
      _errorMensaje = null;
    });

    try {
      final pos = await LocationService.obtenerPosicionActual();
      setState(() {
        _miUbicacion = pos;
        _cargandoUbicacion = false;
      });
      await _buscarSalones();
    } catch (e) {
      setState(() {
        _cargandoUbicacion = false;
        _errorMensaje = e.toString();
      });
    }
  }

  Future<void> _buscarSalones() async {
    if (_miUbicacion == null) return;

    setState(() {
      _buscando = true;
      _errorMensaje = null;
      _salonSeleccionado = null;
    });

    try {
      // 1. Obtener salones cercanos
      final salones = await ApiService.obtenerSalonesCercanos(
        lat: _miUbicacion!.latitude,
        lon: _miUbicacion!.longitude,
        radioKm: _filtros.radioKm,
      );

      // 2. Calcular distancias
      final distancias = <int, double>{};
      for (final s in salones) {
        if (s.tieneUbicacion) {
          distancias[s.id] = LocationService.calcularDistanciaKm(
            _miUbicacion!,
            LatLng(s.latitud!, s.longitud!),
          );
        }
      }

      // 3. Consultar disponibilidad si está el filtro activo
      Map<int, bool> disponibilidad = {};
      if (_filtros.soloDisponibles && _filtros.fechaFiltro != null) {
        final fmt = DateFormat('yyyy-MM-dd');
        final fechaStr = fmt.format(_filtros.fechaFiltro!);

        final dispResponse = await ApiService.consultarDisponibilidad(
          ConsultaDisponibilidadRequest(
            fechaInicio: fechaStr,
            fechaFin: fechaStr,
            horaInicio: _filtros.horaInicio,
            horaFin: _filtros.horaFin,
          ),
        );

        for (final d in dispResponse) {
          disponibilidad[d.salonId] = d.disponible;
        }
      }

      // 4. Filtrar por disponibilidad si es necesario
      List<Salon> salonsFiltrados = salones;
      if (_filtros.soloDisponibles && disponibilidad.isNotEmpty) {
        salonsFiltrados = salones.where((s) {
          return disponibilidad[s.id] == true;
        }).toList();
      }

      // 5. Filtrar por capacidad
      if (_filtros.capacidadMinima != null) {
        salonsFiltrados = salonsFiltrados.where((s) {
          return (s.capacidadMaxima ?? 0) >= _filtros.capacidadMinima!;
        }).toList();
      }

      // 6. Ordenar por distancia
      salonsFiltrados.sort((a, b) {
        final dA = distancias[a.id] ?? 9999;
        final dB = distancias[b.id] ?? 9999;
        return dA.compareTo(dB);
      });

      setState(() {
        _salones = salonsFiltrados;
        _disponibilidadMap = disponibilidad;
        _distanciasMap = distancias;
        _buscando = false;
      });

      // Ajustar mapa para mostrar todos
      if (_salones.isNotEmpty && _miUbicacion != null) {
        _ajustarMapaASalones();
      }
    } catch (e) {
      setState(() {
        _buscando = false;
        _errorMensaje = 'Error al buscar salones: ${e.toString()}';
      });
    }
  }

  void _ajustarMapaASalones() {
    if (_miUbicacion == null) return;

    final puntos = [
      _miUbicacion!,
      ..._salones
          .where((s) => s.tieneUbicacion)
          .map((s) => LatLng(s.latitud!, s.longitud!)),
    ];

    if (puntos.length <= 1) {
      _mapController.move(_miUbicacion!, 13);
      return;
    }

    final bounds = LatLngBounds.fromPoints(puntos);
    _mapController.fitCamera(
      CameraFit.bounds(
        bounds: bounds,
        padding: const EdgeInsets.all(60),
      ),
    );
  }

  void _seleccionarSalon(Salon salon) {
    setState(() => _salonSeleccionado = salon);
    if (salon.tieneUbicacion) {
      _mapController.move(LatLng(salon.latitud!, salon.longitud!), 15);
    }
  }

  void _verDetallesSalon(Salon salon) {
    DetalleSalonSheet.mostrar(
      context,
      salon,
      disponible: _disponibilidadMap[salon.id],
      distanciaKm: _distanciasMap[salon.id],
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_cargandoUbicacion) return _buildCargandoUbicacion();

    return Scaffold(
      backgroundColor: AppTheme.fondoOscuro,
      body: Column(
        children: [
          _buildAppBar(),
          PanelFiltros(
            filtros: _filtros,
            buscando: _buscando,
            onFiltrosChanged: (f) => setState(() => _filtros = f),
            onBuscar: _buscarSalones,
          ),
          _buildVistaSelectorBar(),
          Expanded(
            child: _vista == 'mapa'
                ? _buildMapa()
                : _vista == 'swiper'
                ? _buildSwiper()
                : _buildLista(),
          ),
        ],
      ),
    );
  }

  Widget _buildAppBar() {
    return Container(
      color: AppTheme.fondoOscuro,
      padding: EdgeInsets.fromLTRB(
        20,
        MediaQuery.of(context).padding.top + 12,
        20,
        12,
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppTheme.dorado.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppTheme.dorado.withOpacity(0.3)),
            ),
            child: const Icon(
              Icons.celebration,
              color: AppTheme.dorado,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Salones Cercanos',
                style: TextStyle(
                  color: AppTheme.textoClaro,
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.3,
                ),
              ),
              if (_miUbicacion != null)
                Text(
                  '${_miUbicacion!.latitude.toStringAsFixed(4)}, '
                      '${_miUbicacion!.longitude.toStringAsFixed(4)}',
                  style: const TextStyle(
                    color: AppTheme.textoSecundario,
                    fontSize: 11,
                  ),
                ),
            ],
          ),
          const Spacer(),
          // Contador de resultados
          if (!_buscando)
            Container(
              padding:
              const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: AppTheme.dorado.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppTheme.dorado.withOpacity(0.3)),
              ),
              child: Text(
                '${_salones.length} salones',
                style: const TextStyle(
                  color: AppTheme.dorado,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          const SizedBox(width: 8),
          IconButton(
            onPressed: _iniciarUbicacion,
            icon: const Icon(Icons.my_location),
            color: AppTheme.textoSecundario,
            iconSize: 22,
            tooltip: 'Actualizar ubicación',
          ),
        ],
      ),
    );
  }

  Widget _buildVistaSelectorBar() {
    return Container(
      color: AppTheme.fondoTarjeta,
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
      child: Row(
        children: [
          Expanded(child: _buildVistaBoton('mapa', Icons.map_outlined, 'Mapa')),
          const SizedBox(width: 6),
          Expanded(child: _buildVistaBoton('lista', Icons.list_outlined, 'Lista')),
          const SizedBox(width: 6),
          Expanded(child: _buildVistaBoton('swiper', Icons.swipe_outlined, 'Explorar')),
        ],
      ),
    );
  }

  Widget _buildVistaBoton(String id, IconData icon, String label) {
    final activo = _vista == id;
    return GestureDetector(
      onTap: () => setState(() => _vista = id),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 9),
        decoration: BoxDecoration(
          color: activo ? AppTheme.dorado.withOpacity(0.15) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: activo ? AppTheme.dorado.withOpacity(0.5) : AppTheme.borde,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: activo ? AppTheme.dorado : AppTheme.textoSecundario,
              size: 20,
            ),
            const SizedBox(height: 3),
            Text(
              label,
              style: TextStyle(
                color: activo ? AppTheme.dorado : AppTheme.textoSecundario,
                fontSize: 11,
                fontWeight: activo ? FontWeight.w700 : FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMapa() {
    return Stack(
      children: [
        FlutterMap(
          mapController: _mapController,
          options: MapOptions(
            initialCenter: _miUbicacion ?? const LatLng(-34.6037, -58.3816),
            initialZoom: 12,
            onTap: (_, __) => setState(() => _salonSeleccionado = null),
          ),
          children: [
            // Capa de tiles (OpenStreetMap)
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'com.salon.mapa',
              tileBuilder: _darkTileBuilder,
            ),

            // Círculo de radio
            if (_miUbicacion != null)
              CircleLayer(
                circles: [
                  CircleMarker(
                    point: _miUbicacion!,
                    radius: _filtros.radioKm * 1000,
                    useRadiusInMeter: true,
                    color: AppTheme.dorado.withOpacity(0.05),
                    borderColor: AppTheme.dorado.withOpacity(0.3),
                    borderStrokeWidth: 1.5,
                  ),
                ],
              ),

            // Marcadores de salones
            MarkerLayer(
              markers: _salones
                  .where((s) => s.tieneUbicacion)
                  .map(
                    (s) => Marker(
                  point: LatLng(s.latitud!, s.longitud!),
                  width: 120,
                  height: _salonSeleccionado?.id == s.id ? 90 : 70,
                  child: MarkerSalon(
                    nombre: s.nombre,
                    disponible: _disponibilidadMap[s.id],
                    seleccionado: _salonSeleccionado?.id == s.id,
                    onTap: () => _seleccionarSalon(s),
                  ),
                ),
              )
                  .toList(),
            ),

            // Marcador usuario
            if (_miUbicacion != null)
              MarkerLayer(
                markers: [
                  Marker(
                    point: _miUbicacion!,
                    width: 30,
                    height: 30,
                    child: const MarkerUsuario(),
                  ),
                ],
              ),
          ],
        ),

        // Error overlay
        if (_errorMensaje != null) _buildErrorOverlay(),

        // Loading overlay
        if (_buscando) _buildLoadingOverlay(),

        // Tarjeta de salón seleccionado
        if (_salonSeleccionado != null)
          Positioned(
            bottom: 16,
            left: 16,
            right: 16,
            child: SalonCard(
              salon: _salonSeleccionado!,
              disponible: _disponibilidadMap[_salonSeleccionado!.id],
              distanciaKm: _distanciasMap[_salonSeleccionado!.id],
              onTap: () => _verDetallesSalon(_salonSeleccionado!),
              onVerEnMapa: null,
            ),
          ),

        // Botón centrar mapa
        Positioned(
          top: 16,
          right: 16,
          child: _buildMapaBoton(
            Icons.my_location,
                () {
              if (_miUbicacion != null) {
                _mapController.move(_miUbicacion!, 13);
              }
            },
          ),
        ),
        Positioned(
          top: 64,
          right: 16,
          child: _buildMapaBoton(
            Icons.fit_screen,
            _ajustarMapaASalones,
          ),
        ),
      ],
    );
  }

  Widget _buildMapaBoton(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: AppTheme.fondoTarjeta,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppTheme.borde),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 8,
            ),
          ],
        ),
        child: Icon(icon, color: AppTheme.textoClaro, size: 20),
      ),
    );
  }

  Widget _buildLista() {
    if (_buscando) {
      return const Center(
        child: CircularProgressIndicator(color: AppTheme.dorado),
      );
    }

    if (_errorMensaje != null) {
      return _buildEstadoVacio(
        Icons.error_outline,
        'Error',
        _errorMensaje!,
        mostrarReintentar: true,
      );
    }

    if (_salones.isEmpty) {
      return _buildEstadoVacio(
        Icons.search_off,
        'Sin resultados',
        'No se encontraron salones en el radio seleccionado.\nProbá aumentar el radio de búsqueda.',
        mostrarReintentar: true,
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _salones.length,
      itemBuilder: (_, i) {
        final s = _salones[i];
        return SalonCard(
          salon: s,
          disponible: _disponibilidadMap[s.id],
          distanciaKm: _distanciasMap[s.id],
          onTap: () => _verDetallesSalon(s),
          onVerEnMapa: s.tieneUbicacion
              ? () {
            setState(() {
              _vista = 'mapa';
              _salonSeleccionado = s;
            });
            Future.delayed(const Duration(milliseconds: 100), () {
              _mapController.move(
                  LatLng(s.latitud!, s.longitud!), 15);
            });
          }
              : null,
        );
      },
    );
  }

  Widget _buildSwiper() {
    if (_buscando) {
      return const Center(
        child: CircularProgressIndicator(color: AppTheme.dorado),
      );
    }
    if (_errorMensaje != null) {
      return _buildEstadoVacio(
        Icons.error_outline,
        'Error',
        _errorMensaje!,
        mostrarReintentar: true,
      );
    }
    return SalonSwiper(
      salones: _salones,
      disponibilidadMap: _disponibilidadMap,
      distanciasMap: _distanciasMap,
    );
  }

  Widget _buildEstadoVacio(
      IconData icon,
      String titulo,
      String subtitulo, {
        bool mostrarReintentar = false,
      }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: AppTheme.textoSecundario, size: 48),
            const SizedBox(height: 16),
            Text(
              titulo,
              style: const TextStyle(
                color: AppTheme.textoClaro,
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              subtitulo,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppTheme.textoSecundario,
                fontSize: 14,
                height: 1.5,
              ),
            ),
            if (mostrarReintentar) ...[
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: _buscarSalones,
                icon: const Icon(Icons.refresh),
                label: const Text('Reintentar'),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildCargandoUbicacion() {
    return Scaffold(
      backgroundColor: AppTheme.fondoOscuro,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppTheme.dorado.withOpacity(0.1),
                shape: BoxShape.circle,
                border:
                Border.all(color: AppTheme.dorado.withOpacity(0.3), width: 2),
              ),
              child: const Icon(
                Icons.celebration,
                color: AppTheme.dorado,
                size: 40,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Salones Cercanos',
              style: TextStyle(
                color: AppTheme.textoClaro,
                fontSize: 24,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            if (_errorMensaje == null) ...[
              const SizedBox(height: 24),
              const CircularProgressIndicator(color: AppTheme.dorado),
              const SizedBox(height: 16),
              const Text(
                'Obteniendo tu ubicación...',
                style: TextStyle(color: AppTheme.textoSecundario, fontSize: 14),
              ),
            ] else ...[
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Text(
                  _errorMensaje!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: AppTheme.acento,
                    fontSize: 14,
                    height: 1.5,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: _iniciarUbicacion,
                icon: const Icon(Icons.location_on),
                label: const Text('Permitir ubicación'),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildErrorOverlay() {
    return Positioned(
      top: 12,
      left: 16,
      right: 16,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppTheme.acento.withOpacity(0.9),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white, size: 18),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                _errorMensaje!,
                style:
                const TextStyle(color: Colors.white, fontSize: 13),
              ),
            ),
            GestureDetector(
              onTap: () => setState(() => _errorMensaje = null),
              child: const Icon(Icons.close, color: Colors.white, size: 18),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingOverlay() {
    return Positioned(
      top: 12,
      left: 16,
      right: 16,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: AppTheme.fondoTarjeta.withOpacity(0.95),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppTheme.dorado.withOpacity(0.3)),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: AppTheme.dorado,
              ),
            ),
            SizedBox(width: 10),
            Text(
              'Buscando salones...',
              style: TextStyle(
                color: AppTheme.textoClaro,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Filtro oscuro para tiles del mapa
  Widget _darkTileBuilder(
      BuildContext context,
      Widget tileWidget,
      TileImage tile,
      ) {
    return ColorFiltered(
      colorFilter: const ColorFilter.matrix([
        -0.8, 0, 0, 0, 255,
        0, -0.8, 0, 0, 255,
        0, 0, -0.8, 0, 255,
        0, 0, 0, 1, 0,
      ]),
      child: tileWidget,
    );
  }
}