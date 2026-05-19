import 'package:flutter/material.dart';
import '../models/salon_model.dart';
import '../theme/app_theme.dart';
import 'galeria_imagenes.dart';

class DetalleSalonSheet extends StatelessWidget {
  final Salon salon;
  final bool? disponible;
  final double? distanciaKm;

  const DetalleSalonSheet({
    super.key,
    required this.salon,
    this.disponible,
    this.distanciaKm,
  });

  static void mostrar(
    BuildContext context,
    Salon salon, {
    bool? disponible,
    double? distanciaKm,
  }) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => DetalleSalonSheet(
        salon: salon,
        disponible: disponible,
        distanciaKm: distanciaKm,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.4,
      maxChildSize: 0.95,
      builder: (_, controller) {
        return Container(
          decoration: const BoxDecoration(
            color: AppTheme.fondoTarjeta,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            border: Border(
              top: BorderSide(color: AppTheme.borde),
              left: BorderSide(color: AppTheme.borde),
              right: BorderSide(color: AppTheme.borde),
            ),
          ),
          child: Column(
            children: [
              Center(
                child: Container(
                  margin: const EdgeInsets.only(top: 12),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppTheme.borde,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Expanded(
                child: ListView(
                  controller: controller,
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
                  children: [

                    // Galería de imágenes
                    GaleriaImagenes(salonId: salon.id),

                    const SizedBox(height: 20),

                    // Header nombre + dirección
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: AppTheme.dorado.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: AppTheme.dorado.withOpacity(0.3)),
                          ),
                          child: const Icon(Icons.celebration, color: AppTheme.dorado, size: 24),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                salon.nombre,
                                style: const TextStyle(
                                  color: AppTheme.textoClaro,
                                  fontSize: 20,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              if (salon.direccion != null) ...[
                                const SizedBox(height: 5),
                                Row(
                                  children: [
                                    const Icon(Icons.location_on, color: AppTheme.dorado, size: 13),
                                    const SizedBox(width: 4),
                                    Expanded(
                                      child: Text(
                                        salon.direccion!,
                                        style: const TextStyle(color: AppTheme.textoSecundario, fontSize: 12),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 20),

                    // Disponibilidad
                    if (disponible != null)
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: (disponible! ? AppTheme.acentoVerde : AppTheme.acento).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: (disponible! ? AppTheme.acentoVerde : AppTheme.acento).withOpacity(0.3),
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              disponible! ? Icons.check_circle : Icons.cancel,
                              color: disponible! ? AppTheme.acentoVerde : AppTheme.acento,
                              size: 20,
                            ),
                            const SizedBox(width: 10),
                            Text(
                              disponible!
                                  ? 'Disponible para la fecha seleccionada'
                                  : 'No disponible para esa fecha',
                              style: TextStyle(
                                color: disponible! ? AppTheme.acentoVerde : AppTheme.acento,
                                fontWeight: FontWeight.w700,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),

                    const SizedBox(height: 20),

                    _buildSectionTitle('Información'),
                    const SizedBox(height: 10),
                    _buildInfoGrid(),

                    if (salon.descripcion != null) ...[
                      const SizedBox(height: 20),
                      _buildSectionTitle('Descripción'),
                      const SizedBox(height: 8),
                      Text(
                        salon.descripcion!,
                        style: const TextStyle(
                          color: AppTheme.textoSecundario,
                          fontSize: 14,
                          height: 1.6,
                        ),
                      ),
                    ],

                    if (salon.tieneUbicacion) ...[
                      const SizedBox(height: 20),
                      _buildSectionTitle('Ubicación GPS'),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppTheme.fondoSuperficie,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: AppTheme.borde),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.my_location, color: AppTheme.dorado, size: 16),
                            const SizedBox(width: 8),
                            Text(
                              '${salon.latitud!.toStringAsFixed(6)}, ${salon.longitud!.toStringAsFixed(6)}',
                              style: const TextStyle(
                                color: AppTheme.textoSecundario,
                                fontSize: 12,
                                fontFamily: 'monospace',
                              ),
                            ),
                            if (distanciaKm != null) ...[
                              const Spacer(),
                              Text(
                                '${distanciaKm!.toStringAsFixed(1)} km',
                                style: const TextStyle(
                                  color: AppTheme.dorado,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSectionTitle(String titulo) {
    return Text(
      titulo.toUpperCase(),
      style: const TextStyle(
        color: AppTheme.textoSecundario,
        fontSize: 11,
        fontWeight: FontWeight.w700,
        letterSpacing: 1.5,
      ),
    );
  }

  Widget _buildInfoGrid() {
    final items = <_InfoItem>[
      if (salon.capacidadMaxima != null)
        _InfoItem(Icons.people_outline, 'Capacidad', '${salon.capacidadMaxima} personas', AppTheme.dorado),
      if (salon.precioPorHora != null)
        _InfoItem(Icons.monetization_on_outlined, 'Precio/hora', '\$${salon.precioPorHora!.toStringAsFixed(0)}', AppTheme.acentoVerde),
      _InfoItem(Icons.info_outline, 'Estado', salon.estado, salon.estaActivo ? AppTheme.acentoVerde : AppTheme.textoSecundario),
      _InfoItem(Icons.tag, 'ID', '#${salon.id}', AppTheme.textoSecundario),
    ];

    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 8,
      crossAxisSpacing: 8,
      childAspectRatio: 2.5,
      children: items.map((item) => Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppTheme.fondoSuperficie,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppTheme.borde),
        ),
        child: Row(
          children: [
            Icon(item.icon, color: item.color, size: 18),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(item.label, style: const TextStyle(color: AppTheme.textoSecundario, fontSize: 10, letterSpacing: 0.5)),
                  Text(item.valor, style: TextStyle(color: item.color, fontSize: 13, fontWeight: FontWeight.w700), maxLines: 1, overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
          ],
        ),
      )).toList(),
    );
  }
}

class _InfoItem {
  final IconData icon;
  final String label;
  final String valor;
  final Color color;
  _InfoItem(this.icon, this.label, this.valor, this.color);
}
