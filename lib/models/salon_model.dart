// ─── Salon ────────────────────────────────────────────────────────────────────

class Salon {
  final int id;
  final String nombre;
  final String? descripcion;
  final String? direccion;
  final double? latitud;
  final double? longitud;
  final int? capacidadMaxima;
  final double? precioPorHora;
  final String estado;
  final List<String>? imagenes;

  Salon({
    required this.id,
    required this.nombre,
    this.descripcion,
    this.direccion,
    this.latitud,
    this.longitud,
    this.capacidadMaxima,
    this.precioPorHora,
    required this.estado,
    this.imagenes,
  });

  factory Salon.fromJson(Map<String, dynamic> json) {
    return Salon(
      id: json['id'] as int,
      nombre: json['nombre'] as String? ?? 'Sin nombre',
      descripcion: json['descripcion'] as String?,
      direccion: json['direccion'] as String?,
      latitud: (json['latitud'] as num?)?.toDouble(),
      longitud: (json['longitud'] as num?)?.toDouble(),
      capacidadMaxima: json['capacidadMaxima'] as int?,
      precioPorHora: (json['precioPorHora'] as num?)?.toDouble(),
      estado: json['estado'] as String? ?? 'ACTIVO',
      imagenes: (json['imagenes'] as List<dynamic>?)
          ?.map((e) => e.toString())
          .toList(),
    );
  }

  bool get tieneUbicacion => latitud != null && longitud != null;

  bool get estaActivo =>
      estado.toUpperCase() == 'ACTIVO' || estado.toUpperCase() == 'DISPONIBLE';
}

// ─── Imagen ───────────────────────────────────────────────────────────────────

class ImagenSalon {
  final int id;
  final int salonId;
  final String? descripcion;
  final int? orden;
  final bool esPrincipal;
  final String? nombreArchivo;
  final String? contentType;

  ImagenSalon({
    required this.id,
    required this.salonId,
    this.descripcion,
    this.orden,
    this.esPrincipal = false,
    this.nombreArchivo,
    this.contentType,
  });

  factory ImagenSalon.fromJson(Map<String, dynamic> json) {
    return ImagenSalon(
      id: json['id'] as int,
      salonId: json['salonId'] as int? ?? 0,
      descripcion: json['descripcion'] as String?,
      orden: json['orden'] as int?,
      esPrincipal: json['esPrincipal'] as bool? ?? false,
      nombreArchivo: json['nombreArchivo'] as String?,
      contentType: json['contentType'] as String?,
    );
  }

  /// URL directa para cargar la imagen binaria
  String urlArchivo(String baseUrl) =>
      '$baseUrl/v1/salones/$salonId/imagenes/$id/archivo';
}

// ─── Disponibilidad ───────────────────────────────────────────────────────────

class ConsultaDisponibilidadRequest {
  final String fechaInicio;
  final String fechaFin;
  final String? horaInicio;
  final String? horaFin;

  ConsultaDisponibilidadRequest({
    required this.fechaInicio,
    required this.fechaFin,
    this.horaInicio,
    this.horaFin,
  });

  Map<String, dynamic> toJson() => {
        'fechaInicio': fechaInicio,
        'fechaFin': fechaFin,
        if (horaInicio != null) 'horaInicio': horaInicio,
        if (horaFin != null) 'horaFin': horaFin,
      };
}

class DisponibilidadResponse {
  final int salonId;
  final String nombreSalon;
  final bool disponible;
  final String? motivo;

  DisponibilidadResponse({
    required this.salonId,
    required this.nombreSalon,
    required this.disponible,
    this.motivo,
  });

  factory DisponibilidadResponse.fromJson(Map<String, dynamic> json) {
    return DisponibilidadResponse(
      salonId: json['salonId'] as int? ?? 0,
      nombreSalon: json['nombreSalon'] as String? ?? '',
      disponible: json['disponible'] as bool? ?? false,
      motivo: json['motivo'] as String?,
    );
  }
}

// ─── Filtros ──────────────────────────────────────────────────────────────────

class FiltrosBusqueda {
  double radioKm;
  bool soloDisponibles;
  DateTime? fechaFiltro;
  String? horaInicio;
  String? horaFin;
  int? capacidadMinima;

  FiltrosBusqueda({
    this.radioKm = 10,
    this.soloDisponibles = false,
    this.fechaFiltro,
    this.horaInicio,
    this.horaFin,
    this.capacidadMinima,
  });

  FiltrosBusqueda copyWith({
    double? radioKm,
    bool? soloDisponibles,
    DateTime? fechaFiltro,
    String? horaInicio,
    String? horaFin,
    int? capacidadMinima,
  }) {
    return FiltrosBusqueda(
      radioKm: radioKm ?? this.radioKm,
      soloDisponibles: soloDisponibles ?? this.soloDisponibles,
      fechaFiltro: fechaFiltro ?? this.fechaFiltro,
      horaInicio: horaInicio ?? this.horaInicio,
      horaFin: horaFin ?? this.horaFin,
      capacidadMinima: capacidadMinima ?? this.capacidadMinima,
    );
  }
}
