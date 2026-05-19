import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class MarkerSalon extends StatelessWidget {
  final String nombre;
  final bool? disponible;
  final bool seleccionado;
  final VoidCallback? onTap;

  const MarkerSalon({
    super.key,
    required this.nombre,
    this.disponible,
    this.seleccionado = false,
    this.onTap,
  });

  Color get _color {
    if (disponible == true) return AppTheme.acentoVerde;
    if (disponible == false) return AppTheme.acento;
    return AppTheme.dorado;
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Etiqueta flotante si está seleccionado
          if (seleccionado)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              margin: const EdgeInsets.only(bottom: 4),
              decoration: BoxDecoration(
                color: AppTheme.fondoOscuro.withOpacity(0.9),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: _color, width: 1),
              ),
              child: Text(
                nombre,
                style: TextStyle(
                  color: _color,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),

          // Pin del marcador
          Container(
            width: seleccionado ? 40 : 32,
            height: seleccionado ? 40 : 32,
            decoration: BoxDecoration(
              color: _color,
              shape: BoxShape.circle,
              border: Border.all(
                color: Colors.white,
                width: seleccionado ? 3 : 2,
              ),
              boxShadow: [
                BoxShadow(
                  color: _color.withOpacity(0.4),
                  blurRadius: seleccionado ? 12 : 6,
                  spreadRadius: seleccionado ? 2 : 0,
                ),
              ],
            ),
            child: Icon(
              Icons.celebration,
              color: Colors.white,
              size: seleccionado ? 20 : 16,
            ),
          ),

          // Puntero
          CustomPaint(
            size: const Size(12, 8),
            painter: _PointerPainter(color: _color),
          ),
        ],
      ),
    );
  }
}

class _PointerPainter extends CustomPainter {
  final Color color;
  _PointerPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final path = Path()
      ..moveTo(0, 0)
      ..lineTo(size.width, 0)
      ..lineTo(size.width / 2, size.height)
      ..close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// Marcador de ubicación del usuario
class MarkerUsuario extends StatelessWidget {
  const MarkerUsuario({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 24,
      height: 24,
      decoration: BoxDecoration(
        color: Colors.blue,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 3),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.withOpacity(0.4),
            blurRadius: 8,
            spreadRadius: 2,
          ),
        ],
      ),
    );
  }
}
