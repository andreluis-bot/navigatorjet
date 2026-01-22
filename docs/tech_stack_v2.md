# NavigatorJet - Stack Tecnológica V2

## 🎯 DECISÕES EXECUTIVAS

### Framework
**Flutter 3.24+** (Dart 3.5+)
- **Por quê**: Único código para Android + Web + iOS (futuro)
- **Alternativas descartadas**: React Native (performance inferior em sensores), Native (duplicação de código)

### State Management
**Riverpod 2.x**
- **Por quê**: Compile-time safety, testável, mais robusto que Provider
- **Alternativas descartadas**: Bloc (verboso demais), GetX (má reputação)

### Banco de Dados Local
**Hive (NoSQL) + SQLite (relacional)**
- **Hive**: Trilhas, waypoints, fotos (JSONs grandes, rápido)
- **SQLite**: Gestão de jet, manutenção, consumo (relacional)
- **Por quê**: Cada um para o que faz melhor
- **Alternativas descartadas**: Apenas SQLite (lento para GPX grandes), Apenas Hive (ruim para queries relacionais)

### Sensores
**sensors_plus + flutter_compass**
- **Por quê**: Acesso direto a magnetômetro, giroscópio, acelerômetro
- **Alternativas descartadas**: geolocator sozinho (não tem bússola)

### Mapas
**flutter_map (OPCIONAL)**
- **Por quê**: Gratuito, customizável, tiles offline
- **Alternativas descartadas**: Google Maps (caro, sem offline), Mapbox (caro)

---

## 📦 DEPENDÊNCIAS DO PROJETO

### pubspec.yaml (COMPLETO)

```yaml
name: navigatorjet
description: Instrumento de navegação para Jet Ski e embarcações leves
publish_to: 'none'
version: 0.1.0+1

environment:
  sdk: '>=3.5.0 <4.0.0'

dependencies:
  flutter:
    sdk: flutter

  # ============================================
  # NÚCLEO DE NAVEGAÇÃO (CAMADA 1)
  # ============================================
  
  # Sensores
  sensors_plus: ^5.0.1              # Acelerômetro, giroscópio, magnetômetro
  flutter_compass: ^0.8.0           # Bússola magnética
  geolocator: ^13.0.2               # GPS
  location: ^7.0.0                  # Background location (alternativa)
  
  # Cálculos geoespaciais
  latlong2: ^0.9.1                  # Lat/lng, bearing, distância
  geodesy: ^1.0.0                   # Cross-track distance (buffer)
  
  # Gerenciamento de bateria
  battery_plus: ^6.0.2              # Nível de bateria + eventos
  screen_brightness: ^1.0.1         # Controle de brilho
  
  # ============================================
  # REGISTRO CONTEXTUAL (CAMADA 3)
  # ============================================
  
  # Câmera e fotos
  camera: ^0.11.0+2                 # Captura de fotos
  image_picker: ^1.1.2              # Galeria ou câmera
  flutter_image_compress: ^2.3.0    # Compressão
  exif: ^3.3.0                      # Metadados GPS em fotos
  
  # ============================================
  # PERSISTÊNCIA (CAMADAS 3 + 4)
  # ============================================
  
  # NoSQL (trilhas, waypoints)
  hive: ^2.2.3
  hive_flutter: ^1.1.0
  
  # SQL (gestão de jet, manutenção)
  sqflite: ^2.3.3+1
  path: ^1.9.0                      # Path helper
  
  # Arquivos
  path_provider: ^2.1.4             # Diretórios do app
  file_picker: ^8.1.4               # Import GPX externos
  
  # ============================================
  # MAPAS (CAMADA 5 - OPCIONAL)
  # ============================================
  
  # Mapa base
  flutter_map: ^7.0.2
  
  # Tiles offline
  flutter_map_tile_caching: ^10.0.0
  
  # Cache de imagens
  cached_network_image: ^3.4.1
  
  # ============================================
  # GPX/KML
  # ============================================
  
  gpx: ^2.2.2                       # Parser GPX
  xml: ^6.5.0                       # Parser KML manual
  
  # ============================================
  # SMARTWATCH (CAMADA 6 - PREPARADO)
  # ============================================
  
  wear: ^1.2.0                      # Android Wear OS
  health: ^10.2.0                   # Dados biométricos
  
  # ============================================
  # BACKEND E SINCRONIZAÇÃO
  # ============================================
  
  supabase_flutter: ^2.7.0          # Backend + Auth + Storage
  dio: ^5.7.0                       # HTTP client
  
  # ============================================
  # UI E STATE
  # ============================================
  
  flutter_riverpod: ^2.6.1
  riverpod_annotation: ^2.6.1
  
  # Navegação
  go_router: ^14.6.2
  
  # Componentes UI
  flutter_slidable: ^3.1.1          # Swipe actions
  flutter_speed_dial: ^7.0.0        # FAB com sub-ações
  
  # Animações
  lottie: ^3.1.3                    # Loading animations
  
  # Notificações
  flutter_local_notifications: ^18.0.1
  
  # Permissões
  permission_handler: ^11.3.1
  
  # ============================================
  # UTILS
  # ============================================
  
  uuid: ^4.5.1                      # IDs únicos
  intl: ^0.19.0                     # Formatação i18n
  logger: ^2.4.0                    # Logs
  easy_debounce: ^2.0.3             # Debounce de eventos
  share_plus: ^10.1.2               # Compartilhar arquivos
  url_launcher: ^6.3.1              # Abrir URLs externas
  
  # ============================================
  # ANALYTICS (OPCIONAL)
  # ============================================
  
  firebase_core: ^3.8.0
  firebase_crashlytics: ^4.2.0
  firebase_analytics: ^11.3.5

dev_dependencies:
  flutter_test:
    sdk: flutter
  
  # Linting
  flutter_lints: ^5.0.0
  very_good_analysis: ^6.0.0
  
  # Code generation
  build_runner: ^2.4.13
  hive_generator: ^2.0.1
  riverpod_generator: ^2.6.2
  json_serializable: ^6.8.0
  
  # Testes
  mocktail: ^1.0.4
  integration_test:
    sdk: flutter
  
  # Ícones
  flutter_launcher_icons: ^0.14.1

flutter:
  uses-material-design: true
  
  assets:
    - assets/icons/
    - assets/sounds/
    - assets/images/
  
  fonts:
    - family: Roboto
      fonts:
        - asset: assets/fonts/Roboto-Regular.ttf
        - asset: assets/fonts/Roboto-Bold.ttf
          weight: 700
```

---

## 🗂️ ESTRUTURA DE PASTAS (COMPLETA)

```
navigatorjet/
├── lib/
│   ├── core/
│   │   ├── config/
│   │   │   ├── app_config.dart              # Constantes (cores, URLs)
│   │   │   ├── theme.dart                   # Tema claro/escuro/alto contraste
│   │   │   └── constants.dart               # Valores fixos
│   │   ├── router/
│   │   │   └── app_router.dart              # go_router config
│   │   ├── utils/
│   │   │   ├── geo_utils.dart               # Bearing, distância, etc.
│   │   │   ├── date_utils.dart
│   │   │   └── validators.dart
│   │   └── errors/
│   │       ├── exceptions.dart
│   │       └── failures.dart
│   │
│   ├── data/
│   │   ├── models/
│   │   │   ├── track.dart                   # Track + TrackPoint
│   │   │   ├── waypoint.dart
│   │   │   ├── route.dart                   # Rota GPX
│   │   │   ├── jet.dart                     # Jet + FuelRecord + Maintenance
│   │   │   ├── navigation_context.dart
│   │   │   └── incident.dart
│   │   ├── repositories/
│   │   │   ├── track_repository.dart
│   │   │   ├── waypoint_repository.dart
│   │   │   ├── jet_repository.dart
│   │   │   └── settings_repository.dart
│   │   ├── services/
│   │   │   ├── gps_service.dart
│   │   │   ├── compass_service.dart
│   │   │   ├── sensor_fusion_service.dart
│   │   │   ├── battery_manager.dart
│   │   │   ├── weather_service.dart         # OpenWeatherMap
│   │   │   └── sync_service.dart            # Supabase sync
│   │   └── local/
│   │       ├── hive_setup.dart
│   │       ├── sqlite_setup.dart
│   │       └── secure_storage.dart
│   │
│   ├── features/
│   │   ├── navigation/                      # 🧭 CAMADA 1: NÚCLEO
│   │   │   ├── presentation/
│   │   │   │   ├── screens/
│   │   │   │   │   ├── navigation_screen.dart
│   │   │   │   │   └── instrument_mode_screen.dart
│   │   │   │   └── widgets/
│   │   │   │       ├── compass_widget.dart
│   │   │   │       ├── speedometer_widget.dart
│   │   │   │       ├── heading_indicator.dart
│   │   │   │       └── buffer_status_widget.dart
│   │   │   ├── controllers/
│   │   │   │   ├── navigation_controller.dart
│   │   │   │   └── sensor_controller.dart
│   │   │   └── logic/
│   │   │       ├── navigation_engine.dart
│   │   │       ├── route_buffer.dart
│   │   │       └── alert_manager.dart
│   │   │
│   │   ├── map/                             # 🗺️ CAMADA 5: MAPAS (OPCIONAL)
│   │   │   ├── presentation/
│   │   │   │   ├── screens/
│   │   │   │   │   └── map_screen.dart
│   │   │   │   └── widgets/
│   │   │   │       ├── map_widget.dart
│   │   │   │       ├── track_layer.dart
│   │   │   │       └── waypoint_layer.dart
│   │   │   └── controllers/
│   │   │       └── map_controller.dart
│   │   │
│   │   ├── waypoints/                       # 📍 CAMADA 3: REGISTRO
│   │   │   ├── presentation/
│   │   │   │   ├── screens/
│   │   │   │   │   ├── waypoints_list_screen.dart
│   │   │   │   │   └── waypoint_detail_screen.dart
│   │   │   │   └── widgets/
│   │   │   │       ├── waypoint_card.dart
│   │   │   │       └── incident_quick_dialog.dart
│   │   │   ├── controllers/
│   │   │   │   └── waypoint_controller.dart
│   │   │   └── camera/
│   │   │       └── camera_service.dart
│   │   │
│   │   ├── gpx/
│   │   │   ├── import/
│   │   │   │   └── gpx_parser.dart
│   │   │   ├── export/
│   │   │   │   └── gpx_generator.dart
│   │   │   └── editor/
│   │   │       └── route_editor.dart
│   │   │
│   │   ├── jet_management/                  # 🔧 CAMADA 4: GESTÃO
│   │   │   ├── presentation/
│   │   │   │   ├── screens/
│   │   │   │   │   ├── jets_list_screen.dart
│   │   │   │   │   ├── jet_detail_screen.dart
│   │   │   │   │   ├── fuel_log_screen.dart
│   │   │   │   │   └── maintenance_screen.dart
│   │   │   │   └── widgets/
│   │   │   │       ├── jet_card.dart
│   │   │   │       ├── fuel_chart.dart
│   │   │   │       └── maintenance_timeline.dart
│   │   │   └── controllers/
│   │   │       ├── jet_controller.dart
│   │   │       └── fuel_estimator.dart
│   │   │
│   │   ├── wearable/                        # ⌚ CAMADA 6: SMARTWATCH
│   │   │   ├── wear_service.dart
│   │   │   ├── biometric_service.dart
│   │   │   └── wear_communication.dart
│   │   │
│   │   ├── offline_maps/
│   │   │   ├── downloader/
│   │   │   │   └── tile_downloader.dart
│   │   │   └── storage/
│   │   │       └── mbtiles_storage.dart
│   │   │
│   │   └── settings/
│   │       ├── presentation/
│   │       │   ├── screens/
│   │       │   │   └── settings_screen.dart
│   │       │   └── widgets/
│   │       │       └── setting_tile.dart
│   │       └── controllers/
│   │           └── settings_controller.dart
│   │
│   ├── shared/
│   │   ├── widgets/
│   │   │   ├── custom_button.dart
│   │   │   ├── loading_indicator.dart
│   │   │   ├── error_widget.dart
│   │   │   └── alert_dialog.dart
│   │   └── extensions/
│   │       ├── string_extensions.dart
│   │       ├── datetime_extensions.dart
│   │       └── double_extensions.dart
│   │
│   └── main.dart
│
├── assets/
│   ├── icons/                              # Ícones de waypoints (SVG)
│   │   ├── anchor.svg
│   │   ├── fuel.svg
│   │   ├── danger.svg
│   │   └── photo.svg
│   ├── sounds/
│   │   ├── alert_critical.mp3             # Alerta de bateria/desvio
│   │   └── alert_normal.mp3
│   ├── images/
│   │   └── splash_logo.png
│   └── fonts/
│       ├── Roboto-Regular.ttf
│       └── Roboto-Bold.ttf
│
├── test/
│   ├── unit/
│   │   ├── services/
│   │   │   ├── sensor_fusion_test.dart
│   │   │   └── navigation_engine_test.dart
│   │   └── repositories/
│   │       └── track_repository_test.dart
│   ├── widget/
│   │   └── compass_widget_test.dart
│   └── integration/
│       └── navigation_flow_test.dart
│
├── android/
│   └── app/
│       └── src/main/
│           ├── AndroidManifest.xml
│           └── res/
│               └── raw/
│                   └── anchor_alarm.mp3
│
├── web/
│   └── index.html
│
├── pubspec.yaml
├── analysis_options.yaml
└── README.md
```

---

## 🔧 ANDROID MANIFEST (PERMISSÕES CRÍTICAS)

### android/app/src/main/AndroidManifest.xml

```xml
<manifest xmlns:android="http://schemas.android.com/apk/res/android">
    
    <!-- ============================================ -->
    <!-- PERMISSÕES OBRIGATÓRIAS (CAMADA 1)         -->
    <!-- ============================================ -->
    
    <!-- GPS -->
    <uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" />
    <uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION" />
    <uses-permission android:name="android.permission.ACCESS_BACKGROUND_LOCATION" />
    
    <!-- Sensores (bússola funciona sem permissão explícita) -->
    
    <!-- Bateria -->
    <uses-permission android:name="android.permission.BATTERY_STATS" />
    
    <!-- ============================================ -->
    <!-- PERMISSÕES OPCIONAIS                        -->
    <!-- ============================================ -->
    
    <!-- Câmera (Camada 3) -->
    <uses-permission android:name="android.permission.CAMERA" />
    
    <!-- Armazenamento (fotos, GPX) -->
    <uses-permission android:name="android.permission.WRITE_EXTERNAL_STORAGE" 
                     android:maxSdkVersion="32" />
    <uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE"
                     android:maxSdkVersion="32" />
    
    <!-- Android 13+ -->
    <uses-permission android:name="android.permission.READ_MEDIA_IMAGES" />
    
    <!-- Internet (sincronização, mapas) -->
    <uses-permission android:name="android.permission.INTERNET" />
    <uses-permission android:name="android.permission.ACCESS_NETWORK_STATE" />
    
    <!-- Foreground Service (navegação em background) -->
    <uses-permission android:name="android.permission.FOREGROUND_SERVICE" />
    <uses-permission android:name="android.permission.FOREGROUND_SERVICE_LOCATION" />
    
    <!-- Vibração (alertas) -->
    <uses-permission android:name="android.permission.VIBRATE" />
    
    <!-- Wakelock (tela ligada durante navegação) -->
    <uses-permission android:name="android.permission.WAKE_LOCK" />
    
    <!-- ============================================ -->
    <!-- BLUETOOTH (SMARTWATCH - CAMADA 6)          -->
    <!-- ============================================ -->
    
    <uses-permission android:name="android.permission.BLUETOOTH" />
    <uses-permission android:name="android.permission.BLUETOOTH_ADMIN" />
    <uses-permission android:name="android.permission.BLUETOOTH_CONNECT" />
    <uses-permission android:name="android.permission.BLUETOOTH_SCAN" />
    
    <application
        android:label="NavigatorJet"
        android:name="${applicationName}"
        android:icon="@mipmap/ic_launcher">
        
        <activity
            android:name=".MainActivity"
            android:exported="true"
            android:launchMode="singleTop"
            android:theme="@style/LaunchTheme"
            android:configChanges="orientation|keyboardHidden|keyboard|screenSize|smallestScreenSize|locale|layoutDirection|fontScale|screenLayout|density|uiMode"
            android:hardwareAccelerated="true"
            android:windowSoftInputMode="adjustResize"
            android:screenOrientation="portrait">
            
            <intent-filter>
                <action android:name="android.intent.action.MAIN"/>
                <category android:name="android.intent.category.LAUNCHER"/>
            </intent-filter>
        </activity>
        
        <!-- Foreground Service para navegação em background -->
        <service
            android:name="com.navigatorjet.app.NavigationForegroundService"
            android:exported="false"
            android:foregroundServiceType="location">
        </service>
        
    </application>
</manifest>
```

---

## 🌐 BACKEND (SUPABASE)

### Tabelas PostgreSQL + PostGIS

```sql
-- Habilitar extensão espacial
CREATE EXTENSION IF NOT EXISTS postgis;

-- ============================================
-- USUÁRIOS (gerenciado pelo Supabase Auth)
-- ============================================
-- auth.users já existe

-- ============================================
-- JETS
-- ============================================
CREATE TABLE jets (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
  name TEXT NOT NULL,
  model TEXT,
  year INT,
  total_hours FLOAT DEFAULT 0.0,
  last_maintenance_hours FLOAT DEFAULT 0.0,
  fuel_tank_capacity FLOAT DEFAULT 60.0,  -- Litros
  fuel_type TEXT DEFAULT 'Gasolina Comum',
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- ============================================
-- TRILHAS
-- ============================================
CREATE TABLE tracks (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
  jet_id UUID REFERENCES jets(id) ON DELETE SET NULL,
  name TEXT NOT NULL,
  start_time TIMESTAMPTZ NOT NULL,
  end_time TIMESTAMPTZ,
  total_distance FLOAT,           -- metros
  avg_speed FLOAT,                -- km/h
  max_speed FLOAT,                -- km/h
  line_color TEXT DEFAULT '#FF5722',
  is_visible BOOLEAN DEFAULT TRUE,
  gpx_file_path TEXT,             -- Caminho no Storage
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- ============================================
-- PONTOS DA TRILHA
-- ============================================
CREATE TABLE track_points (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  track_id UUID REFERENCES tracks(id) ON DELETE CASCADE,
  location GEOGRAPHY(POINT, 4326) NOT NULL,  -- PostGIS
  altitude FLOAT,
  speed FLOAT,                    -- km/h
  heading FLOAT,                  -- 0-360°
  timestamp TIMESTAMPTZ NOT NULL,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX track_points_location_idx ON track_points USING GIST(location);

-- ============================================
-- WAYPOINTS
-- ============================================
CREATE TABLE waypoints (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
  track_id UUID REFERENCES tracks(id) ON DELETE SET NULL,
  location GEOGRAPHY(POINT, 4326) NOT NULL,
  name TEXT NOT NULL,
  notes TEXT,
  icon_type TEXT DEFAULT 'marker',
  photo_path TEXT,                -- Caminho no Storage
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX waypoints_location_idx ON waypoints USING GIST(location);

-- ============================================
-- INCIDENTES
-- ============================================
CREATE TABLE incidents (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
  track_id UUID REFERENCES tracks(id) ON DELETE SET NULL,
  location GEOGRAPHY(POINT, 4326) NOT NULL,
  type TEXT NOT NULL,             -- 'enrosco', 'pedra_submersa', etc.
  description TEXT,
  photo_path TEXT,
  speed FLOAT,                    -- Velocidade no momento
  created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX incidents_location_idx ON incidents USING GIST(location);

-- ============================================
-- COMBUSTÍVEL
-- ============================================
CREATE TABLE fuel_records (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  jet_id UUID REFERENCES jets(id) ON DELETE CASCADE,
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
  liters FLOAT NOT NULL,
  price_per_liter FLOAT NOT NULL,
  total_cost FLOAT GENERATED ALWAYS AS (liters * price_per_liter) STORED,
  location TEXT,
  timestamp TIMESTAMPTZ DEFAULT NOW()
);

-- ============================================
-- MANUTENÇÃO
-- ============================================
CREATE TABLE maintenance_records (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  jet_id UUID REFERENCES jets(id) ON DELETE CASCADE,
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
  type TEXT NOT NULL,             -- 'oil_change', 'spark_plugs', etc.
  hours_at_maintenance FLOAT,
  description TEXT,
  cost FLOAT,
  mechanic TEXT,
  date TIMESTAMPTZ DEFAULT NOW()
);

-- ============================================
-- COMPARTILHAMENTO AO VIVO (CAMADA 6 - FUTURO)
-- ============================================
CREATE TABLE live_sessions (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
  share_token TEXT UNIQUE NOT NULL,
  is_active BOOLEAN DEFAULT TRUE,
  expires_at TIMESTAMPTZ NOT NULL,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE live_positions (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  session_id UUID REFERENCES live_sessions(id) ON DELETE CASCADE,
  location GEOGRAPHY(POINT, 4326) NOT NULL,
  speed FLOAT,
  heading FLOAT,
  timestamp TIMESTAMPTZ NOT NULL
);

-- Limpar posições antigas (manter apenas últimas 100)
CREATE OR REPLACE FUNCTION cleanup_old_positions()
RETURNS TRIGGER AS $$
BEGIN
  DELETE FROM live_positions
  WHERE session_id = NEW.session_id
    AND id NOT IN (
      SELECT id FROM live_positions
      WHERE session_id = NEW.session_id
      ORDER BY timestamp DESC
      LIMIT 100
    );
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER cleanup_positions_trigger
AFTER INSERT ON live_positions
FOR EACH ROW EXECUTE FUNCTION cleanup_old_positions();
```

---

## 📊 AMBIENTE DE DESENVOLVIMENTO

### Variáveis de Ambiente (.env)

```env
# Supabase
SUPABASE_URL=https://your-project.supabase.co
SUPABASE_ANON_KEY=your_anon_key

# OpenWeatherMap
OPENWEATHER_API_KEY=your_key

# Firebase (opcional)
FIREBASE_API_KEY=your_key
```

### Carregar no Flutter

```dart
import 'package:flutter_dotenv/flutter_dotenv.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  await dotenv.load(fileName: ".env");
  
  runApp(const MyApp());
}
```

---

## 🧪 TESTES

### Coverage Mínima

- **Unitários**: 80% (foco em `navigation_engine`, `sensor_fusion`)
- **Integração**: 50%
- **Widget**: 60%

### Comandos

```bash
# Rodar todos os testes
flutter test

# Coverage
flutter test --coverage
genhtml coverage/lcov.info -o coverage/html

# Testes de integração
flutter test integration_test/
```

---

## 🚀 BUILD E DEPLOY

### Android (APK)

```bash
# Debug
flutter build apk --debug

# Release
flutter build apk --release --split-per-abi

# App Bundle (Google Play)
flutter build appbundle --release
```

### Web

```bash
flutter build web --release
```

---

## 📈 MONITORAMENTO

### Firebase Crashlytics

```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  await Firebase.initializeApp();
  FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterError;
  
  runApp(const MyApp());
}
```

### Analytics (Eventos Críticos)

```dart
FirebaseAnalytics.instance.logEvent(
  name: 'navigation_started',
  parameters: {
    'route_length_km': 15.3,
    'jet_model': 'GTI 90'
  }
);
```

---

## 🔒 SEGURANÇA

### Ofuscação de Código (Release)

```bash
flutter build apk --release --obfuscate --split-debug-info=./debug-info
```

### Criptografia de Assets

Usar `flutter_secure_storage` para chaves sensíveis.

---

## 📚 REFERÊNCIAS

- [Flutter Docs](https://docs.flutter.dev/)
- [sensors_plus](https://pub.dev/packages/sensors_plus)
- [flutter_compass](https://pub.dev/packages/flutter_compass)
- [Supabase Flutter](https://supabase.com/docs/guides/getting-started/quickstarts/flutter)
- [PostGIS](https://postgis.net/)
