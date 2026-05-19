import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/salon_model.dart';
import '../theme/app_theme.dart';

class PanelFiltros extends StatefulWidget {
  final FiltrosBusqueda filtros;
  final Function(FiltrosBusqueda) onFiltrosChanged;
  final VoidCallback onBuscar;
  final bool buscando;

  const PanelFiltros({
    super.key,
    required this.filtros,
    required this.onFiltrosChanged,
    required this.onBuscar,
    this.buscando = false,
  });

  @override
  State<PanelFiltros> createState() => _PanelFiltrosState();
}

class _PanelFiltrosState extends State<PanelFiltros> {
  late FiltrosBusqueda _filtros;
  bool _expandido = false;

  @override
  void initState() {
    super.initState();
    _filtros = widget.filtros;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppTheme.fondoTarjeta,
        border: Border(bottom: BorderSide(color: AppTheme.borde)),
      ),
      child: Column(
        children: [
          // Fila principal siempre visible
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Row(
              children: [
                // Radio slider
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(
                            Icons.radar,
                            color: AppTheme.dorado,
                            size: 16,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'Radio: ${_filtros.radioKm.toStringAsFixed(0)} km',
                            style: const TextStyle(
                              color: AppTheme.textoClaro,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      SliderTheme(
                        data: SliderTheme.of(context).copyWith(
                          trackHeight: 3,
                        ),
                        child: Slider(
                          value: _filtros.radioKm,
                          min: 1,
                          max: 50,
                          divisions: 49,
                          label: '${_filtros.radioKm.toStringAsFixed(0)} km',
                          onChanged: (v) {
                            setState(() => _filtros = _filtros.copyWith(radioKm: v));
                            widget.onFiltrosChanged(_filtros);
                          },
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(width: 12),

                // Botón buscar
                ElevatedButton.icon(
                  onPressed: widget.buscando ? null : widget.onBuscar,
                  icon: widget.buscando
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppTheme.fondoOscuro,
                          ),
                        )
                      : const Icon(Icons.search, size: 18),
                  label: Text(widget.buscando ? 'Buscando...' : 'Buscar'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Toggle filtros avanzados
          InkWell(
            onTap: () => setState(() => _expandido = !_expandido),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
              child: Row(
                children: [
                  Icon(
                    _expandido
                        ? Icons.keyboard_arrow_up
                        : Icons.keyboard_arrow_down,
                    color: AppTheme.dorado,
                    size: 18,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    _expandido ? 'Ocultar filtros' : 'Más filtros',
                    style: const TextStyle(
                      color: AppTheme.dorado,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  if (_tieneFiltrosActivos) ...[
                    const SizedBox(width: 8),
                    Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: AppTheme.dorado,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),

          // Filtros avanzados
          AnimatedSize(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeInOut,
            child: _expandido
                ? _buildFiltrosAvanzados()
                : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }

  bool get _tieneFiltrosActivos =>
      _filtros.soloDisponibles ||
      _filtros.fechaFiltro != null ||
      _filtros.capacidadMinima != null;

  Widget _buildFiltrosAvanzados() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Divider(color: AppTheme.borde, height: 1),
          const SizedBox(height: 16),

          // Solo disponibles
          _buildSwitch(
            'Solo disponibles',
            'Filtrar por disponibilidad en la fecha seleccionada',
            Icons.event_available_outlined,
            _filtros.soloDisponibles,
            (v) {
              setState(() => _filtros = _filtros.copyWith(soloDisponibles: v));
              widget.onFiltrosChanged(_filtros);
            },
          ),

          if (_filtros.soloDisponibles) ...[
            const SizedBox(height: 16),

            // Fecha
            _buildLabel('Fecha del evento', Icons.calendar_today_outlined),
            const SizedBox(height: 8),
            _buildFechaSelector(),
            const SizedBox(height: 16),

            // Horarios
            _buildLabel('Horario', Icons.access_time_outlined),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _buildHoraSelector(
                    'Desde',
                    _filtros.horaInicio,
                    (h) {
                      setState(
                          () => _filtros = _filtros.copyWith(horaInicio: h));
                      widget.onFiltrosChanged(_filtros);
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildHoraSelector(
                    'Hasta',
                    _filtros.horaFin,
                    (h) {
                      setState(
                          () => _filtros = _filtros.copyWith(horaFin: h));
                      widget.onFiltrosChanged(_filtros);
                    },
                  ),
                ),
              ],
            ),
          ],

          const SizedBox(height: 16),

          // Capacidad mínima
          _buildLabel('Capacidad mínima', Icons.people_outline),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: [null, 50, 100, 200, 500].map((cap) {
              final selected = _filtros.capacidadMinima == cap;
              return ChoiceChip(
                label: Text(cap == null ? 'Cualquiera' : '$cap+'),
                selected: selected,
                onSelected: (_) {
                  setState(
                      () => _filtros = _filtros.copyWith(capacidadMinima: cap));
                  widget.onFiltrosChanged(_filtros);
                },
                selectedColor: AppTheme.dorado.withOpacity(0.2),
                labelStyle: TextStyle(
                  color: selected ? AppTheme.dorado : AppTheme.textoSecundario,
                  fontWeight:
                      selected ? FontWeight.w700 : FontWeight.w400,
                  fontSize: 13,
                ),
                backgroundColor: AppTheme.fondoSuperficie,
                side: BorderSide(
                  color: selected
                      ? AppTheme.dorado.withOpacity(0.5)
                      : AppTheme.borde,
                ),
              );
            }).toList(),
          ),

          if (_tieneFiltrosActivos) ...[
            const SizedBox(height: 16),
            TextButton.icon(
              onPressed: _limpiarFiltros,
              icon: const Icon(Icons.clear, size: 16),
              label: const Text('Limpiar filtros'),
              style: TextButton.styleFrom(
                foregroundColor: AppTheme.acento,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildLabel(String texto, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: AppTheme.textoSecundario, size: 15),
        const SizedBox(width: 6),
        Text(
          texto,
          style: const TextStyle(
            color: AppTheme.textoSecundario,
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildSwitch(
    String titulo,
    String subtitulo,
    IconData icon,
    bool value,
    Function(bool) onChanged,
  ) {
    return Row(
      children: [
        Icon(icon, color: AppTheme.dorado, size: 20),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                titulo,
                style: const TextStyle(
                  color: AppTheme.textoClaro,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                subtitulo,
                style: const TextStyle(
                  color: AppTheme.textoSecundario,
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ),
        Switch(
          value: value,
          onChanged: onChanged,
          activeColor: AppTheme.dorado,
          activeTrackColor: AppTheme.dorado.withOpacity(0.3),
          inactiveThumbColor: AppTheme.textoSecundario,
          inactiveTrackColor: AppTheme.borde,
        ),
      ],
    );
  }

  Widget _buildFechaSelector() {
    final fmt = DateFormat('dd/MM/yyyy');
    return InkWell(
      onTap: _seleccionarFecha,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: AppTheme.fondoSuperficie,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: _filtros.fechaFiltro != null
                ? AppTheme.dorado.withOpacity(0.5)
                : AppTheme.borde,
          ),
        ),
        child: Row(
          children: [
            const Icon(Icons.calendar_month, color: AppTheme.dorado, size: 18),
            const SizedBox(width: 10),
            Text(
              _filtros.fechaFiltro != null
                  ? fmt.format(_filtros.fechaFiltro!)
                  : 'Seleccionar fecha',
              style: TextStyle(
                color: _filtros.fechaFiltro != null
                    ? AppTheme.textoClaro
                    : AppTheme.textoSecundario,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _seleccionarFecha() async {
    final fecha = await showDatePicker(
      context: context,
      initialDate: _filtros.fechaFiltro ?? DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.dark(
            primary: AppTheme.dorado,
            surface: AppTheme.fondoTarjeta,
          ),
        ),
        child: child!,
      ),
    );
    if (fecha != null) {
      setState(() => _filtros = _filtros.copyWith(fechaFiltro: fecha));
      widget.onFiltrosChanged(_filtros);
    }
  }

  Widget _buildHoraSelector(
    String label,
    String? horaActual,
    Function(String?) onChanged,
  ) {
    return InkWell(
      onTap: () => _seleccionarHora(label, horaActual, onChanged),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: AppTheme.fondoSuperficie,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: horaActual != null
                ? AppTheme.dorado.withOpacity(0.5)
                : AppTheme.borde,
          ),
        ),
        child: Row(
          children: [
            const Icon(Icons.schedule, color: AppTheme.dorado, size: 16),
            const SizedBox(width: 8),
            Text(
              horaActual ?? label,
              style: TextStyle(
                color: horaActual != null
                    ? AppTheme.textoClaro
                    : AppTheme.textoSecundario,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _seleccionarHora(
    String label,
    String? horaActual,
    Function(String?) onChanged,
  ) async {
    TimeOfDay initial = const TimeOfDay(hour: 18, minute: 0);
    if (horaActual != null) {
      final parts = horaActual.split(':');
      initial = TimeOfDay(
        hour: int.parse(parts[0]),
        minute: int.parse(parts[1]),
      );
    }

    final hora = await showTimePicker(
      context: context,
      initialTime: initial,
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.dark(
            primary: AppTheme.dorado,
            surface: AppTheme.fondoTarjeta,
          ),
        ),
        child: child!,
      ),
    );
    if (hora != null) {
      final formatted =
          '${hora.hour.toString().padLeft(2, '0')}:${hora.minute.toString().padLeft(2, '0')}';
      onChanged(formatted);
    }
  }

  void _limpiarFiltros() {
    setState(() {
      _filtros = FiltrosBusqueda(radioKm: _filtros.radioKm);
    });
    widget.onFiltrosChanged(_filtros);
  }
}
