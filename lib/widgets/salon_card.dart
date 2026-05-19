import 'package:flutter/material.dart';
import '../models/salon_model.dart';
import '../theme/app_theme.dart';

class SalonCard extends StatelessWidget {
  final Salon salon;
  final bool? disponible;
  final double? distanciaKm;
  final VoidCallback? onTap;
  final VoidCallback? onVerEnMapa;

  const SalonCard({
    super.key,
    required this.salon,
    this.disponible,
    this.distanciaKm,
    this.onTap,
    this.onVerEnMapa,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: AppTheme.fondoTarjeta,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: disponible == true
                ? AppTheme.acentoVerde.withOpacity(0.4)
                : disponible == false
                    ? AppTheme.acento.withOpacity(0.3)
                    : AppTheme.borde,
            width: 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Ícono de salón
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: AppTheme.dorado.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: AppTheme.dorado.withOpacity(0.3),
                      ),
                    ),
                    child: const Icon(
                      Icons.celebration_outlined,
                      color: AppTheme.dorado,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),

                  // Nombre y dirección
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          salon.nombre,
                          style: const TextStyle(
                            color: AppTheme.textoClaro,
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (salon.direccion != null) ...[
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              const Icon(
                                Icons.location_on_outlined,
                                color: AppTheme.textoSecundario,
                                size: 13,
                              ),
                              const SizedBox(width: 3),
                              Expanded(
                                child: Text(
                                  salon.direccion!,
                                  style: const TextStyle(
                                    color: AppTheme.textoSecundario,
                                    fontSize: 12,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),

                  // Badge disponibilidad
                  if (disponible != null) _buildDisponibilidadBadge(),
                ],
              ),
            ),

            // Info chips
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  if (distanciaKm != null)
                    _buildChip(
                      Icons.directions_walk,
                      '${distanciaKm!.toStringAsFixed(1)} km',
                      AppTheme.dorado,
                    ),
                  if (salon.capacidadMaxima != null)
                    _buildChip(
                      Icons.people_outline,
                      '${salon.capacidadMaxima} personas',
                      AppTheme.textoSecundario,
                    ),
                  if (salon.precioPorHora != null)
                    _buildChip(
                      Icons.attach_money,
                      '\$${salon.precioPorHora!.toStringAsFixed(0)}/h',
                      AppTheme.acentoVerde,
                    ),
                  _buildEstadoChip(),
                ],
              ),
            ),

            // Botones
            Container(
              decoration: const BoxDecoration(
                border: Border(
                  top: BorderSide(color: AppTheme.borde),
                ),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Row(
                children: [
                  if (onVerEnMapa != null)
                    TextButton.icon(
                      onPressed: onVerEnMapa,
                      icon: const Icon(Icons.map_outlined, size: 16),
                      label: const Text('Ver en mapa'),
                      style: TextButton.styleFrom(
                        foregroundColor: AppTheme.dorado,
                        textStyle: const TextStyle(fontSize: 13),
                      ),
                    ),
                  const Spacer(),
                  TextButton.icon(
                    onPressed: onTap,
                    icon: const Icon(Icons.info_outline, size: 16),
                    label: const Text('Detalle'),
                    style: TextButton.styleFrom(
                      foregroundColor: AppTheme.textoSecundario,
                      textStyle: const TextStyle(fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDisponibilidadBadge() {
    final isDisponible = disponible!;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: isDisponible
            ? AppTheme.acentoVerde.withOpacity(0.15)
            : AppTheme.acento.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDisponible
              ? AppTheme.acentoVerde.withOpacity(0.5)
              : AppTheme.acento.withOpacity(0.5),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: isDisponible ? AppTheme.acentoVerde : AppTheme.acento,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 5),
          Text(
            isDisponible ? 'Disponible' : 'Ocupado',
            style: TextStyle(
              color: isDisponible ? AppTheme.acentoVerde : AppTheme.acento,
              fontSize: 11,
              fontWeight: FontWeight.w600,
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

  Widget _buildEstadoChip() {
    final esActivo = salon.estaActivo;
    return _buildChip(
      esActivo ? Icons.check_circle_outline : Icons.cancel_outlined,
      salon.estado,
      esActivo ? AppTheme.dorado : AppTheme.textoSecundario,
    );
  }
}
