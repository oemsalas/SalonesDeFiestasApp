import 'package:flutter/material.dart';
import '../models/salon_model.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';

// ─── Widget principal de galería ──────────────────────────────────────────────

class GaleriaImagenes extends StatefulWidget {
  final int salonId;

  const GaleriaImagenes({super.key, required this.salonId});

  @override
  State<GaleriaImagenes> createState() => _GaleriaImagenesState();
}

class _GaleriaImagenesState extends State<GaleriaImagenes> {
  List<ImagenSalon> _imagenes = [];
  bool _cargando = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _cargarImagenes();
  }

  Future<void> _cargarImagenes() async {
    try {
      final imagenes = await ApiService.listarImagenes(widget.salonId);
      if (mounted) setState(() { _imagenes = imagenes; _cargando = false; });
    } catch (e) {
      if (mounted) setState(() { _error = e.toString(); _cargando = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_cargando) return _buildSkeleton();
    if (_error != null) return _buildError();
    if (_imagenes.isEmpty) return _buildVacio();
    return _buildGaleria();
  }

  Widget _buildGaleria() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Imagen principal grande
        _buildImagenPrincipal(),
        const SizedBox(height: 8),
        // Tira de miniaturas si hay más de 1
        if (_imagenes.length > 1) _buildTiraMiniaturas(),
      ],
    );
  }

  Widget _buildImagenPrincipal() {
    final principal = _imagenes.firstWhere(
      (i) => i.esPrincipal,
      orElse: () => _imagenes.first,
    );

    return GestureDetector(
      onTap: () => _abrirVisorCompleto(
        context,
        _imagenes,
        _imagenes.indexOf(principal),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Stack(
          children: [
            _NetworkImageWidget(
              url: ApiService.urlImagen(widget.salonId, principal.id),
              height: 220,
              width: double.infinity,
            ),
            // Badge "Principal"
            if (principal.esPrincipal)
              Positioned(
                top: 10,
                left: 10,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppTheme.dorado.withOpacity(0.9),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.star_rounded, color: AppTheme.fondoOscuro, size: 13),
                      SizedBox(width: 4),
                      Text(
                        'Principal',
                        style: TextStyle(
                          color: AppTheme.fondoOscuro,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            // Contador de fotos
            Positioned(
              bottom: 10,
              right: 10,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.6),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.photo_library_outlined, color: Colors.white, size: 13),
                    const SizedBox(width: 5),
                    Text(
                      '${_imagenes.length} foto${_imagenes.length != 1 ? 's' : ''}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // Hint expandir
            Positioned(
              top: 10,
              right: 10,
              child: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.fullscreen, color: Colors.white, size: 18),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTiraMiniaturas() {
    return SizedBox(
      height: 72,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: _imagenes.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (_, i) {
          final img = _imagenes[i];
          final esPrincipal = img.esPrincipal ||
              (_imagenes.none((x) => x.esPrincipal) && i == 0);
          return GestureDetector(
            onTap: () => _abrirVisorCompleto(context, _imagenes, i),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Stack(
                children: [
                  _NetworkImageWidget(
                    url: ApiService.urlImagen(widget.salonId, img.id),
                    height: 72,
                    width: 72,
                  ),
                  if (esPrincipal)
                    Positioned(
                      bottom: 0,
                      left: 0,
                      right: 0,
                      child: Container(
                        height: 3,
                        color: AppTheme.dorado,
                      ),
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSkeleton() {
    return Column(
      children: [
        Container(
          height: 220,
          decoration: BoxDecoration(
            color: AppTheme.fondoSuperficie,
            borderRadius: BorderRadius.circular(16),
          ),
          child: const Center(
            child: CircularProgressIndicator(
              color: AppTheme.dorado,
              strokeWidth: 2,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: List.generate(4, (_) => Expanded(
            child: Container(
              height: 72,
              margin: const EdgeInsets.only(right: 8),
              decoration: BoxDecoration(
                color: AppTheme.fondoSuperficie,
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          )),
        ),
      ],
    );
  }

  Widget _buildError() {
    return Container(
      height: 120,
      decoration: BoxDecoration(
        color: AppTheme.fondoSuperficie,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.borde),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.broken_image_outlined,
                color: AppTheme.textoSecundario, size: 28),
            const SizedBox(height: 6),
            Text(
              'No se pudieron cargar las fotos',
              style: const TextStyle(
                  color: AppTheme.textoSecundario, fontSize: 12),
            ),
            TextButton(
              onPressed: () {
                setState(() { _cargando = true; _error = null; });
                _cargarImagenes();
              },
              child: const Text('Reintentar',
                  style: TextStyle(color: AppTheme.dorado, fontSize: 12)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVacio() {
    return Container(
      height: 100,
      decoration: BoxDecoration(
        color: AppTheme.fondoSuperficie,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.borde),
      ),
      child: const Center(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.photo_outlined, color: AppTheme.textoSecundario, size: 22),
            SizedBox(width: 8),
            Text(
              'Sin fotos disponibles',
              style: TextStyle(color: AppTheme.textoSecundario, fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }

  static void _abrirVisorCompleto(
    BuildContext context,
    List<ImagenSalon> imagenes,
    int indiceInicial,
  ) {
    Navigator.of(context).push(
      PageRouteBuilder(
        opaque: false,
        barrierColor: Colors.black87,
        pageBuilder: (_, __, ___) => _VisorImagenesCompleto(
          imagenes: imagenes,
          indiceInicial: indiceInicial,
        ),
        transitionsBuilder: (_, anim, __, child) =>
            FadeTransition(opacity: anim, child: child),
      ),
    );
  }
}

// ─── Visor a pantalla completa ────────────────────────────────────────────────

class _VisorImagenesCompleto extends StatefulWidget {
  final List<ImagenSalon> imagenes;
  final int indiceInicial;

  const _VisorImagenesCompleto({
    required this.imagenes,
    required this.indiceInicial,
  });

  @override
  State<_VisorImagenesCompleto> createState() => _VisorImagenesCompletoState();
}

class _VisorImagenesCompletoState extends State<_VisorImagenesCompleto> {
  late PageController _pageController;
  late int _indiceActual;

  @override
  void initState() {
    super.initState();
    _indiceActual = widget.indiceInicial;
    _pageController = PageController(initialPage: widget.indiceInicial);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final imagen = widget.imagenes[_indiceActual];
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          // Fondo negro
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(color: Colors.black87),
          ),

          // PageView de imágenes
          PageView.builder(
            controller: _pageController,
            itemCount: widget.imagenes.length,
            onPageChanged: (i) => setState(() => _indiceActual = i),
            itemBuilder: (_, i) {
              final img = widget.imagenes[i];
              return InteractiveViewer(
                minScale: 0.8,
                maxScale: 4.0,
                child: Center(
                  child: _NetworkImageWidget(
                    url: ApiService.urlImagen(img.salonId, img.id),
                    height: MediaQuery.of(context).size.height * 0.75,
                    width: MediaQuery.of(context).size.width,
                    fit: BoxFit.contain,
                  ),
                ),
              );
            },
          ),

          // Header: cerrar + contador
          Positioned(
            top: MediaQuery.of(context).padding.top + 8,
            left: 0,
            right: 0,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.5),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.close, color: Colors.white, size: 22),
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.5),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '${_indiceActual + 1} / ${widget.imagenes.length}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Footer: descripción + indicadores
          Positioned(
            bottom: MediaQuery.of(context).padding.bottom + 16,
            left: 0,
            right: 0,
            child: Column(
              children: [
                // Descripción
                if (imagen.descripcion != null)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 0, 24, 12),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.6),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        imagen.descripcion!,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ),

                // Indicadores de página (puntos)
                if (widget.imagenes.length > 1)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                      widget.imagenes.length,
                      (i) => AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        margin: const EdgeInsets.symmetric(horizontal: 3),
                        width: i == _indiceActual ? 20 : 6,
                        height: 6,
                        decoration: BoxDecoration(
                          color: i == _indiceActual
                              ? AppTheme.dorado
                              : Colors.white.withOpacity(0.4),
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                    ),
                  ),

                const SizedBox(height: 8),

                // Badge principal
                if (imagen.esPrincipal)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppTheme.dorado.withOpacity(0.9),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.star_rounded, color: AppTheme.fondoOscuro, size: 13),
                        SizedBox(width: 4),
                        Text(
                          'Foto principal',
                          style: TextStyle(
                            color: AppTheme.fondoOscuro,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),

          // Flechas de navegación
          if (widget.imagenes.length > 1) ...[
            if (_indiceActual > 0)
              Positioned(
                left: 8,
                top: 0,
                bottom: 0,
                child: Center(
                  child: _buildFlechaNav(Icons.chevron_left, () {
                    _pageController.previousPage(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                    );
                  }),
                ),
              ),
            if (_indiceActual < widget.imagenes.length - 1)
              Positioned(
                right: 8,
                top: 0,
                bottom: 0,
                child: Center(
                  child: _buildFlechaNav(Icons.chevron_right, () {
                    _pageController.nextPage(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                    );
                  }),
                ),
              ),
          ],
        ],
      ),
    );
  }

  Widget _buildFlechaNav(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.4),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: Colors.white, size: 28),
      ),
    );
  }
}

// ─── Widget de imagen con red + placeholder ───────────────────────────────────

class _NetworkImageWidget extends StatefulWidget {
  final String url;
  final double height;
  final double width;
  final BoxFit fit;

  const _NetworkImageWidget({
    required this.url,
    required this.height,
    required this.width,
    this.fit = BoxFit.cover,
  });

  @override
  State<_NetworkImageWidget> createState() => _NetworkImageWidgetState();
}

class _NetworkImageWidgetState extends State<_NetworkImageWidget> {
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: widget.height,
      width: widget.width,
      child: Image.network(
        widget.url,
        height: widget.height,
        width: widget.width,
        fit: widget.fit,
        loadingBuilder: (_, child, progress) {
          if (progress == null) return child;
          return Container(
            color: AppTheme.fondoSuperficie,
            child: Center(
              child: CircularProgressIndicator(
                value: progress.expectedTotalBytes != null
                    ? progress.cumulativeBytesLoaded /
                        progress.expectedTotalBytes!
                    : null,
                color: AppTheme.dorado,
                strokeWidth: 2,
              ),
            ),
          );
        },
        errorBuilder: (_, __, ___) => Container(
          color: AppTheme.fondoSuperficie,
          child: const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.broken_image_outlined,
                    color: AppTheme.textoSecundario, size: 32),
                SizedBox(height: 6),
                Text(
                  'Sin imagen',
                  style: TextStyle(
                    color: AppTheme.textoSecundario,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// Helper extension
extension _ListExt<T> on List<T> {
  bool none(bool Function(T) test) => !any(test);
}
