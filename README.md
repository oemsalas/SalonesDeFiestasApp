# Salon Mapa — Flutter App

Mapa interactivo para buscar salones de fiestas cercanos conectado a la API REST. Prueba Maxi!

## Requisitos

- Flutter SDK >= 3.10.0
- Android Studio con Android SDK
- Dispositivo Android o emulador con Google Play Services

## Configuración inicial

### 1. Abrir en Android Studio

Abrí Android Studio → **Open** → seleccioná la carpeta `salon_mapa`.

### 2. Instalar dependencias

En la terminal del proyecto:

```bash
flutter pub get
```

### 3. Ejecutar

```bash
flutter run
```

---

## Estructura del proyecto

```
lib/
├── main.dart                    # Punto de entrada
├── theme/
│   └── app_theme.dart           # Tema visual (colores, tipografía)
├── models/
│   └── salon_model.dart         # Modelos: Salon, Disponibilidad, Filtros
├── services/
│   ├── api_service.dart         # Cliente HTTP → API REST
│   └── location_service.dart    # Geolocalización del dispositivo
├── screens/
│   └── mapa_screen.dart         # Pantalla principal con mapa y lista
└── widgets/
    ├── panel_filtros.dart        # Panel de filtros (radio, fecha, horario, capacidad)
    ├── salon_card.dart           # Tarjeta de salón para la lista
    ├── marker_salon.dart         # Marcadores del mapa
    └── detalle_salon_sheet.dart  # Bottom sheet con detalles del salón
```

---

## Funcionalidades

### Mapa interactivo
- Mapa OpenStreetMap con tema oscuro
- Marcadores con colores según disponibilidad:
  - 🟡 Dorado: sin filtro de disponibilidad
  - 🟢 Verde: disponible
  - 🔴 Rojo: no disponible
- Círculo de radio de búsqueda visible en el mapa
- Marcador azul de tu ubicación actual
- Al tocar un marcador se muestra la tarjeta del salón

### Vista lista
- Listado de salones ordenados por distancia
- Botón "Ver en mapa" para centrar el mapa en ese salón
- Botón "Detalle" para ver toda la info

### Filtros
- **Radio de búsqueda**: 1 a 50 km (slider)
- **Solo disponibles**: activa la consulta de disponibilidad
  - Selector de fecha del evento
  - Selector de hora inicio/fin
- **Capacidad mínima**: Cualquiera / 50+ / 100+ / 200+ / 500+

### Detalle del salón (bottom sheet)
- Estado de disponibilidad con color
- Capacidad, precio/hora, estado, ID
- Descripción
- Coordenadas GPS y distancia

---

## API utilizada

**Base URL:** `http://159.112.149.218:8080/api`

| Endpoint | Uso |
|---|---|
| `GET /v1/salones/cercanos?lat=&lon=&radioKm=` | Salones cercanos |
| `POST /v1/salones/disponibilidad` | Consulta disponibilidad |
| `GET /v1/salones/{id}` | Detalle de un salón |

---

## Notas importantes

### HTTP (no HTTPS)
La API usa HTTP. En `AndroidManifest.xml` está habilitado `android:usesCleartextTraffic="true"` para permitirlo. En producción, migrá la API a HTTPS y remové esa opción.

### Permisos
La app solicita permiso de ubicación (`ACCESS_FINE_LOCATION`) en tiempo de ejecución. Si el usuario lo deniega, se muestra un mensaje descriptivo.

### Tiles del mapa
Se usan los tiles de OpenStreetMap (gratuitos, sin API key). Para producción considerá usar Mapbox o Google Maps para mayor calidad.

---

## Dependencias principales

```yaml
flutter_map: ^6.1.0       # Mapa basado en Leaflet
latlong2: ^0.9.0           # Coordenadas
http: ^1.2.0               # Cliente HTTP
geolocator: ^11.0.0        # GPS del dispositivo
intl: ^0.19.0              # Formato de fechas
```
