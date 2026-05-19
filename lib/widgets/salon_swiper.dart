import 'dart:math';
import 'package:flutter/material.dart';
import '../models/salon_model.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import '../widgets/detalle_salon_sheet.dart';

class SalonSwiper extends StatefulWidget {
  final List<Salon> salones;
  final Map<int, bool> disponibilidadMap;
  final Map<int, double> distanciasMap;

  const SalonSwiper({
    super.key,
    required this.salones,
    required this.disponibilidadMap,
    required this.distanciasMap,
  });

  @override
  State<SalonSwiper> createState() => _SalonSwiperState();
}

class _SalonSwiperState extends State<SalonSwiper>
    with SingleTickerProviderStateMixin {
  int _indiceActual = 0;
  Offset _arrastre = Offset.zero;
  double _rotacion = 0;
  bool _animando = false;

  late AnimationController _resetController;
  late Animation<Offset> _resetAnimation;
  late Animation<double> _rotacionAnimation;

  static const double _umbralSwipe = 100;

  @override
  void initState() {
    super.initState();
    _resetController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _resetAnimation = Tween<Offset>(
      begin: Offset.zero,
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _resetController,
      curve: Curves.elasticOut,
    ));
    _rotacionAnimation = Tween<double>(begin: 0, end: 0).animate(
      CurvedAnimation(parent: _resetController, curve: Curves.elasticOut),
    );
  }

  @override
  void dispose() {
    _resetController.dispose();
    super.dispose();
  }

  void _onPanStart(DragStartDetails d) {
    if (_animando) return;
    _resetController.stop();
  }

  void _onPanUpdate(DragUpdateDetails d) {
    if (_animando) return;
    setState(() {
      _arrastre += d.delta;
      _rotacion = (_arrastre.dx / 300) * 0.25;
    });
  }

  void _onPanEnd(DragEndDetails d) {
    if (_animando) return;

    final velocidad = d.velocity.pixelsPerSecond.dx;
    final distancia = _arrastre.dx.abs();

    if (distancia > _umbralSwipe || velocidad.abs() > 600) {
      _hacerSwipe(_arrastre.dx > 0 ? 1 : -1);
    } else {
      _resetarCarta();
    }
  }

  void _hacerSwipe(int direccion) {
    if (_animando) return;
    setState(() => _animando = true);

    final destino = Offset(direccion * 500.0, _arrastre.dy + direccion * 80);
    final rotDestino = direccion * 0.4;

    _resetAnimation = Tween<Offset>(
      begin: _arrastre,
      end: destino,
    ).animate(CurvedAnimation(
      parent: _resetController,
      curve: Curves.easeInCubic,
    ));
    _rotacionAnimation = Tween<double>(
      begin: _rotacion,
      end: rotDestino,
    ).animate(CurvedAnimation(
      parent: _resetController,
      curve: Curves.easeInCubic,
    ));

    _resetController.duration = const Duration(milliseconds: 350);
    _resetController.forward(from: 0).then((_) {
      setState(() {
        _indiceActual =
            (_indiceActual + 1).clamp(0, widget.salones.length);
        _arrastre = Offset.zero;
        _rotacion = 0;
        _animando = false;
      });
      _resetController.duration = const Duration(milliseconds: 300);
    });
  }

  void _resetarCarta() {
    _resetAnimation = Tween<Offset>(
      begin: _arrastre,
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _resetController,
      curve: Curves.elasticOut,
    ));
    _rotacionAnimation = Tween<double>(
      begin: _rotacion,
      end: 0,
    ).animate(CurvedAnimation(
      parent: _resetController,
      curve: Curves.elasticOut,
    ));
    _resetController.forward(from: 0).then((_) {
      setState(() {
        _arrastre = Offset.zero;
        _rotacion = 0;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    if (widget.salones.isEmpty) return _buildVacio();

    if (_indiceActual >= widget.salones.length) return _buildFin();

    final restantes = widget.salones.length - _indiceActual;

    return Column(
      children: [
        // Indicador de progreso
        _buildProgreso(),

        // Stack de cartas
        Expanded(
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Carta de fondo (la siguiente)
              if (_indiceActual + 1 < widget.salones.length)
                _buildCartaFondo(_indiceActual + 1),

              // Carta de más atrás (la que viene después)
              if (_indiceActual + 2 < widget.salones.length)
                _buildCartaFondolejana(_indiceActual + 2),

              // Carta principal (arrastrable)
              AnimatedBuilder(
                animation: _resetController,
                builder: (_, __) {
                  final offset = _animando
                      ? _resetAnimation.value
                      : _arrastre;
                  final rot = _animando
                      ? _rotacionAnimation.value
                      : _rotacion;

                  return Transform.translate(
                    offset: offset,
                    child: Transform.rotate(
                      angle: rot,
                      child: GestureDetector(
                        onPanStart: _onPanStart,
                        onPanUpdate: _onPanUpdate,
                        onPanEnd: _onPanEnd,
                        onTap: () => DetalleSalonSheet.mostrar(
                          context,
                          widget.salones[_indiceActual],
                          disponible: widget.disponibilidadMap[
                              widget.salones[_indiceActual].id],
                          distanciaKm: widget.distanciasMap[
                              widget.salones[_indiceActual].id],
                        ),
                        child: _buildCarta(
                          widget.salones[_indiceActual],
                          esPrincipal: true,
                          arrastre: _arrastre.dx,
                        ),
                      ),
                    ),
                  );
                },
              ),

              // Badges de like/nope
              if (!_animando) ...[
                _buildBadgeLike(),
                _buildBadgeNope(),
              ],
            ],
          ),
        ),

        // Botones de acción
        _buildBotones(restantes),
      ],
    );
  }

  Widget _buildProgreso() {
    final total = widget.salones.length;
    final vistos = _indiceActual;
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 4),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${_indiceActual + 1} de $total salones',
                style: const TextStyle(
                  color: AppTheme.textoSecundario,
                  fontSize: 12,
                ),
              ),
              Text(
                '${total - _indiceActual} restantes',
                style: const TextStyle(
                  color: AppTheme.dorado,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: total > 0 ? vistos / total : 0,
              backgroundColor: AppTheme.borde,
              valueColor:
                  const AlwaysStoppedAnimation<Color>(AppTheme.dorado),
              minHeight: 3,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCartaFondo(int indice) {
    return Transform.scale(
      scale: 0.93,
      child: Transform.translate(
        offset: const Offset(0, 16),
        child: _buildCarta(widget.salones[indice], esPrincipal: false),
      ),
    );
  }

  Widget _buildCartaFondolejana(int indice) {
    return Transform.scale(
      scale: 0.86,
      child: Transform.translate(
        offset: const Offset(0, 32),
        child: _buildCarta(widget.salones[indice], esPrincipal: false),
      ),
    );
  }

  Widget _buildCarta(
    Salon salon, {
    required bool esPrincipal,
    double arrastre = 0,
  }) {
    final disponible = widget.disponibilidadMap[salon.id];
    final distancia = widget.distanciasMap[salon.id];

    // Color del borde según dirección del arrastre
    Color bordColor = AppTheme.borde;
    if (esPrincipal && arrastre > 40) {
      bordColor = AppTheme.acentoVerde.withOpacity(
          (arrastre / _umbralSwipe).clamp(0.0, 1.0));
    } else if (esPrincipal && arrastre < -40) {
      bordColor = AppTheme.acento.withOpacity(
          (-arrastre / _umbralSwipe).clamp(0.0, 1.0));
    }

    return Container(
      width: MediaQuery.of(context).size.width - 32,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: AppTheme.fondoTarjeta,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: bordColor, width: esPrincipal ? 1.5 : 1),
        boxShadow: esPrincipal
            ? [
                BoxShadow(
                  color: Colors.black.withOpacity(0.3),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ]
            : [],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header con imagen real del salón
          _SwiperImagenHeader(
            salonId: salon.id,
            disponible: disponible,
            child: Stack(
              children: [
                // Número de carta
                Positioned(
                  top: 12,
                  right: 14,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppTheme.fondoOscuro.withOpacity(0.7),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '#${salon.id}',
                      style: const TextStyle(
                        color: AppTheme.textoSecundario,
                        fontSize: 11,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Info del salón
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Nombre
                  Text(
                    salon.nombre,
                    style: const TextStyle(
                      color: AppTheme.textoClaro,
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      height: 1.2,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),

                  // Dirección
                  if (salon.direccion != null)
                    Row(
                      children: [
                        const Icon(Icons.location_on,
                            color: AppTheme.dorado, size: 15),
                        const SizedBox(width: 5),
                        Expanded(
                          child: Text(
                            salon.direccion!,
                            style: const TextStyle(
                              color: AppTheme.textoSecundario,
                              fontSize: 13,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),

                  const Spacer(),

                  // Chips de info
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      if (distancia != null)
                        _buildChip(Icons.directions_walk,
                            '${distancia.toStringAsFixed(1)} km',
                            AppTheme.dorado),
                      if (salon.capacidadMaxima != null)
                        _buildChip(Icons.people_outline,
                            '${salon.capacidadMaxima} pers.',
                            AppTheme.textoSecundario),
                      if (salon.precioPorHora != null)
                        _buildChip(Icons.attach_money,
                            '\$${salon.precioPorHora!.toStringAsFixed(0)}/h',
                            AppTheme.acentoVerde),
                    ],
                  ),

                  const SizedBox(height: 12),

                  // Hint de toque
                  if (esPrincipal)
                    Center(
                      child: Text(
                        'Tocá para ver detalles',
                        style: TextStyle(
                          color: AppTheme.textoSecundario.withOpacity(0.5),
                          fontSize: 12,
                        ),
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

  Widget _buildChip(IconData icon, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBadgeLike() {
    final opacidad = (_arrastre.dx / _umbralSwipe).clamp(0.0, 1.0);
    if (opacidad < 0.05) return const SizedBox.shrink();
    return Positioned(
      top: 60,
      left: 40,
      child: Transform.rotate(
        angle: -0.3,
        child: Opacity(
          opacity: opacidad,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              border: Border.all(color: AppTheme.acentoVerde, width: 3),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Text(
              'ME GUSTA',
              style: TextStyle(
                color: AppTheme.acentoVerde,
                fontSize: 20,
                fontWeight: FontWeight.w900,
                letterSpacing: 2,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBadgeNope() {
    final opacidad = (-_arrastre.dx / _umbralSwipe).clamp(0.0, 1.0);
    if (opacidad < 0.05) return const SizedBox.shrink();
    return Positioned(
      top: 60,
      right: 40,
      child: Transform.rotate(
        angle: 0.3,
        child: Opacity(
          opacity: opacidad,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              border: Border.all(color: AppTheme.acento, width: 3),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Text(
              'SIGUIENTE',
              style: TextStyle(
                color: AppTheme.acento,
                fontSize: 20,
                fontWeight: FontWeight.w900,
                letterSpacing: 2,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBotones(int restantes) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(40, 8, 40, 24),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          // Botón anterior
          _buildBotonAccion(
            icon: Icons.arrow_back_ios_rounded,
            color: AppTheme.textoSecundario,
            size: 44,
            onTap: _indiceActual > 0
                ? () => setState(() => _indiceActual--)
                : null,
            tooltip: 'Anterior',
          ),

          // Botón nope (izquierda)
          _buildBotonAccion(
            icon: Icons.close_rounded,
            color: AppTheme.acento,
            size: 56,
            onTap: restantes > 0 ? () => _hacerSwipe(-1) : null,
            tooltip: 'Siguiente',
          ),

          // Botón detalle (centro)
          _buildBotonAccion(
            icon: Icons.info_outline_rounded,
            color: AppTheme.dorado,
            size: 44,
            onTap: restantes > 0
                ? () => DetalleSalonSheet.mostrar(
                      context,
                      widget.salones[_indiceActual],
                      disponible: widget
                          .disponibilidadMap[widget.salones[_indiceActual].id],
                      distanciaKm: widget
                          .distanciasMap[widget.salones[_indiceActual].id],
                    )
                : null,
            tooltip: 'Ver detalle',
          ),

          // Botón like (derecha)
          _buildBotonAccion(
            icon: Icons.favorite_rounded,
            color: AppTheme.acentoVerde,
            size: 56,
            onTap: restantes > 0 ? () => _hacerSwipe(1) : null,
            tooltip: 'Me gusta',
          ),

          // Botón reiniciar
          _buildBotonAccion(
            icon: Icons.refresh_rounded,
            color: AppTheme.textoSecundario,
            size: 44,
            onTap: () => setState(() => _indiceActual = 0),
            tooltip: 'Reiniciar',
          ),
        ],
      ),
    );
  }

  Widget _buildBotonAccion({
    required IconData icon,
    required Color color,
    required double size,
    VoidCallback? onTap,
    String? tooltip,
  }) {
    return Tooltip(
      message: tooltip ?? '',
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: onTap != null
                ? color.withOpacity(0.1)
                : AppTheme.borde.withOpacity(0.3),
            shape: BoxShape.circle,
            border: Border.all(
              color: onTap != null
                  ? color.withOpacity(0.4)
                  : AppTheme.borde.withOpacity(0.3),
              width: 1.5,
            ),
          ),
          child: Icon(
            icon,
            color: onTap != null
                ? color
                : AppTheme.textoSecundario.withOpacity(0.3),
            size: size * 0.42,
          ),
        ),
      ),
    );
  }

  Widget _buildVacio() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.search_off, color: AppTheme.textoSecundario, size: 48),
          const SizedBox(height: 16),
          const Text(
            'Sin salones para explorar',
            style: TextStyle(
                color: AppTheme.textoClaro,
                fontSize: 18,
                fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          const Text(
            'Buscá con otro radio o filtros distintos',
            style: TextStyle(color: AppTheme.textoSecundario, fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildFin() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: AppTheme.dorado.withOpacity(0.1),
              shape: BoxShape.circle,
              border: Border.all(color: AppTheme.dorado.withOpacity(0.4)),
            ),
            child: const Icon(Icons.celebration,
                color: AppTheme.dorado, size: 40),
          ),
          const SizedBox(height: 20),
          const Text(
            '¡Viste todos los salones!',
            style: TextStyle(
                color: AppTheme.textoClaro,
                fontSize: 20,
                fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          Text(
            '${widget.salones.length} salones explorados',
            style: const TextStyle(
                color: AppTheme.textoSecundario, fontSize: 14),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => setState(() => _indiceActual = 0),
            icon: const Icon(Icons.refresh),
            label: const Text('Volver a explorar'),
          ),
        ],
      ),
    );
  }
}

// ─── Header con imagen real ───────────────────────────────────────────────────

class _SwiperImagenHeader extends StatefulWidget {
  final int salonId;
  final bool? disponible;
  final Widget child; // overlay encima de la imagen

  const _SwiperImagenHeader({
    required this.salonId,
    required this.disponible,
    required this.child,
  });

  @override
  State<_SwiperImagenHeader> createState() => _SwiperImagenHeaderState();
}

class _SwiperImagenHeaderState extends State<_SwiperImagenHeader> {
  String? _urlImagen;
  bool _cargando = true;

  @override
  void initState() {
    super.initState();
    _cargarPrincipal();
  }

  Future<void> _cargarPrincipal() async {
    try {
      final imagenes = await ApiService.listarImagenes(widget.salonId);
      if (imagenes.isNotEmpty && mounted) {
        setState(() {
          _urlImagen = ApiService.urlImagen(widget.salonId, imagenes.first.id);
          _cargando = false;
        });
      } else {
        if (mounted) setState(() => _cargando = false);
      }
    } catch (_) {
      if (mounted) setState(() => _cargando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(23)),
      child: SizedBox(
        height: 200,
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Imagen de fondo
            if (_urlImagen != null)
              Image.network(
                _urlImagen!,
                fit: BoxFit.cover,
                loadingBuilder: (_, child, progress) =>
                    progress == null ? child : _buildFondoFallback(),
                errorBuilder: (_, __, ___) => _buildFondoFallback(),
              )
            else if (_cargando)
              _buildFondoCargando()
            else
              _buildFondoFallback(),

            // Gradiente oscuro abajo para que el texto sea legible
            if (_urlImagen != null)
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                height: 80,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                      colors: [
                        Colors.black.withOpacity(0.7),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),

            // Badge disponibilidad
            if (widget.disponible != null)
              Positioned(
                bottom: 12,
                left: 14,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                  decoration: BoxDecoration(
                    color: widget.disponible!
                        ? AppTheme.acentoVerde.withOpacity(0.9)
                        : AppTheme.acento.withOpacity(0.9),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 5),
                      Text(
                        widget.disponible! ? 'Disponible' : 'Ocupado',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

            // Overlay extra (número de carta, etc.)
            widget.child,
          ],
        ),
      ),
    );
  }

  Widget _buildFondoFallback() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppTheme.dorado.withOpacity(0.15),
            AppTheme.doradoOscuro.withOpacity(0.08),
          ],
        ),
      ),
      child: Center(
        child: Icon(
          Icons.celebration,
          color: AppTheme.dorado.withOpacity(0.4),
          size: 56,
        ),
      ),
    );
  }

  Widget _buildFondoCargando() {
    return Container(
      color: AppTheme.fondoSuperficie,
      child: const Center(
        child: CircularProgressIndicator(
          color: AppTheme.dorado,
          strokeWidth: 2,
        ),
      ),
    );
  }
}

// Patrón decorativo de fondo para las cartas
class _PatronPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppTheme.dorado.withOpacity(0.04)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    const spacing = 40.0;
    for (double x = 0; x < size.width + spacing; x += spacing) {
      for (double y = 0; y < size.height + spacing; y += spacing) {
        canvas.drawCircle(Offset(x, y), 16, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
