# NavigatorJet - Arquitetura do Núcleo

## 🎯 PRINCÍPIOS ARQUITETURAIS

### 1. Camadas Independentes
Cada camada funciona isoladamente. Falha em uma não afeta as outras.

### 2. Sensor-First
Sensores físicos têm prioridade sobre dados derivados (mapas, internet).

### 3. Offline-First
Tudo crítico funciona sem internet. Sincronização é bônus, não requisito.

### 4. Safety-First
Alertas críticos nunca são suprimidos. Bateria/segurança > UX bonita.

### 5. Leveza
Cada feature é questionada: "Isso vale o custo em bateria?"

---

## 📐 ARQUITETURA EM CAMADAS

```
┌─────────────────────────────────────────────────────────┐
│  CAMADA 1: NÚCLEO DE NAVEGAÇÃO (SEMPRE ATIVO)          │
│  ├── Sensores (GPS + Bússola + Fusion)                 │
│  ├── Cálculo de Rumo (atual vs. alvo)                  │
│  ├── Buffer de Desvio                                  │
│  └── Alertas Críticos (bateria, desvio)                │
│                                                         │
│  Dependências: ZERO (exceto hardware)                  │
│  Consumo: Otimizado agressivamente                     │
│  Taxa de atualização: 1 Hz (eco) / 10 Hz (normal)      │
└─────────────────────────────────────────────────────────┘
                          ↓
┌─────────────────────────────────────────────────────────┐
│  CAMADA 2: MODO INSTRUMENTOS (FALLBACK)                │
│  ├── Bússola Grande (300x300px)                        │
│  ├── Velocímetro Digital                               │
│  ├── Cronômetro                                        │
│  └── Coordenadas GPS                                   │
│                                                         │
│  Ativa quando: Mapa indisponível OU bateria < 20%     │
│  Fundo: Preto sólido (#000000)                         │
│  Texto: Branco/verde/amarelo saturados                 │
└─────────────────────────────────────────────────────────┘
                          ↓
┌─────────────────────────────────────────────────────────┐
│  CAMADA 3: REGISTRO CONTEXTUAL                         │
│  ├── Fotos Automáticas (waypoint gerado)              │
│  ├── Incidentes (1 toque: Enrosco, Perigo, etc.)      │
│  ├── Waypoints Manuais                                 │
│  └── Tracks (trilha GPS completa)                      │
│                                                         │
│  Armazenamento: Hive (local, criptografado)            │
│  Sincronização: Posterior, não bloqueante              │
└─────────────────────────────────────────────────────────┘
                          ↓
┌─────────────────────────────────────────────────────────┐
│  CAMADA 4: GESTÃO DE JET                               │
│  ├── Cadastro de Jets (múltiplos)                     │
│  ├── Horas de Uso (automático + manual)               │
│  ├── Registro de Combustível                          │
│  ├── Estatísticas de Consumo                          │
│  └── Histórico de Manutenção                          │
│                                                         │
│  Uso: APENAS pós-navegação                             │
│  Banco: SQLite (relacional)                            │
└─────────────────────────────────────────────────────────┘
                          ↓
┌─────────────────────────────────────────────────────────┐
│  CAMADA 5: MAPAS (OPCIONAL)                            │
│  ├── Tiles Offline (.mbtiles)                         │
│  ├── Camadas (vento, clima, satélite)                 │
│  ├── Track Overlay (linha colorida)                   │
│  └── Waypoints/Perigos                                │
│                                                         │
│  Ativa quando: Internet OU tiles baixados             │
│  Desliga quando: Bateria < 20% OU modo instrumentos   │
└─────────────────────────────────────────────────────────┘
                          ↓
┌─────────────────────────────────────────────────────────┐
│  CAMADA 6: INTEGRAÇÕES EXTERNAS                        │
│  ├── Smartwatch (Huawei Watch GT 4)                   │
│  ├── Biometria (batimentos, stress)                   │
│  ├── Satélite (Spot/inReach - preparado)              │
│  └── Backup Cloud (Supabase)                          │
│                                                         │
│  Uso: Complementar, nunca obrigatório                  │
│  Falha: Nunca afeta navegação                         │
└─────────────────────────────────────────────────────────┘
```

---

## 🧭 CAMADA 1: NÚCLEO DE NAVEGAÇÃO (DETALHADO)

### 1.1 Subsistema de Sensores

#### **GPS (Geolocalização)**
```dart
class GPSService {
  Stream<Position> get positionStream;  // 1 Hz (eco) ou 10 Hz (normal)
  
  Position? currentPosition;
  double? currentSpeed;     // km/h
  double? currentHeading;   // 0-360° (GPS heading, menos preciso)
  double? altitude;         // metros
  
  // Fallback se bússola falhar
  double getGPSHeading() {
    // Calcula direção baseado nos últimos 2 pontos
    // Preciso apenas se velocidade > 5 km/h
  }
}
```

#### **Bússola Magnética**
```dart
class CompassService {
  Stream<double> get headingStream;  // 10 Hz
  
  double? magneticHeading;  // 0-360° (norte magnético)
  double? trueHeading;      // 0-360° (norte verdadeiro, com declinação)
  
  bool isCalibrated;
  double calibrationQuality;  // 0-100%
  
  // Sensor fusion com giroscópio
  void applyGyroCorrection(double gyroX, double gyroY, double gyroZ);
}
```

#### **Sensor Fusion (Magnetômetro + Giroscópio)**
```dart
class SensorFusion {
  // Complementary filter: Magnetômetro (lento, preciso) + Giroscópio (rápido, drift)
  double getFusedHeading() {
    // 90% magnetômetro + 10% giroscópio integrado
    return 0.9 * compassHeading + 0.1 * integratedGyro;
  }
  
  // Detecção de interferência magnética (motor do jet)
  bool isInterferenceDetected();
}
```

---

### 1.2 Subsistema de Navegação por Rumo

#### **Estrutura de Dados: Rota GPX**
```dart
class Route {
  String id;
  String name;
  List<RoutePoint> points;
  
  RouteDirection direction;  // Ida ou Volta
  
  double totalDistance;      // km
  Duration estimatedTime;
  
  // Inverte a rota (útil para retorno)
  void reverse();
}

class RoutePoint {
  double latitude;
  double longitude;
  double? elevation;
  int segmentIndex;  // Qual segmento da rota (0, 1, 2...)
}

enum RouteDirection {
  forward,   // Início → Fim
  reverse    // Fim → Início
}
```

#### **Cálculo de Rumo**
```dart
class NavigationEngine {
  Route? activeRoute;
  RoutePoint? targetPoint;  // Próximo ponto do GPX
  
  // Calcula bearing (rumo) entre posição atual e próximo ponto
  double getDesiredHeading() {
    if (activeRoute == null) return 0.0;
    
    final currentPos = gpsService.currentPosition;
    final target = getNextTargetPoint();
    
    return calculateBearing(
      currentPos.latitude, 
      currentPos.longitude,
      target.latitude, 
      target.longitude
    );
  }
  
  // Diferença angular entre rumo atual e desejado
  double getHeadingError() {
    double current = compassService.trueHeading ?? 0.0;
    double desired = getDesiredHeading();
    
    double error = desired - current;
    
    // Normalizar para -180 a +180
    if (error > 180) error -= 360;
    if (error < -180) error += 360;
    
    return error;  // Negativo = virar esquerda, Positivo = virar direita
  }
  
  // Avança para próximo waypoint quando próximo o suficiente
  void updateTargetPoint() {
    if (distanceToTarget() < 50) {  // 50 metros
      targetPoint = getNextWaypoint();
    }
  }
}
```

---

### 1.3 Buffer de Desvio (Inovação Crítica)

#### **Conceito**
Ao invés de alerta binário (dentro/fora da rota), criamos um **buffer lateral** configurável.

```
       Buffer: 50m

   ════════════════════════════  ← Limite superior do buffer
        ════════════════        ← Eixo da rota (GPX)
   ════════════════════════════  ← Limite inferior do buffer

   Se usuário estiver DENTRO do buffer:
     - Nenhum alerta
     - Exibe apenas distância ao eixo ("Desvio: +12m")
   
   Se usuário estiver FORA do buffer:
     - Alerta sonoro
     - Vibração
     - Texto vermelho
```

#### **Implementação**
```dart
class RouteBuffer {
  double bufferRadius = 50.0;  // metros (configurável: 10-500m)
  
  // Calcula distância perpendicular ao eixo da rota
  double getPerpendicularDistance(Position currentPos) {
    // Algoritmo: Cross-Track Distance
    // https://www.movable-type.co.uk/scripts/latlong.html
    
    final lineStart = targetPoint;
    final lineEnd = getNextTargetPoint();
    
    return calculateCrossTrackDistance(
      currentPos,
      lineStart,
      lineEnd
    );
  }
  
  // Estado do buffer
  BufferStatus getStatus() {
    double distance = getPerpendicularDistance(currentPosition);
    
    if (distance.abs() < bufferRadius * 0.5) {
      return BufferStatus.center;  // Verde
    } else if (distance.abs() < bufferRadius) {
      return BufferStatus.nearEdge;  // Amarelo
    } else {
      return BufferStatus.outside;  // Vermelho - ALERTA
    }
  }
}

enum BufferStatus {
  center,     // 🟢 Dentro, perto do eixo
  nearEdge,   // 🟡 Dentro, mas próximo da borda
  outside     // 🔴 FORA - Alerta!
}
```

---

### 1.4 Sistema de Alertas

#### **Hierarquia de Alertas**
```dart
enum AlertPriority {
  critical,   // Bateria < 10%, fora do buffer 2x
  high,       // Bateria < 20%, fora do buffer
  medium,     // Desvio próximo ao limite
  low         // Informações gerais
}

class Alert {
  AlertPriority priority;
  String message;
  AlertType type;
  
  bool vibrate;
  bool sound;
  Duration? duration;  // null = infinito até usuário descartar
}

enum AlertType {
  routeDeviation,
  batteryCritical,
  dangerAhead,
  compassCalibration,
  gpsLost
}
```

#### **Alerta de Bateria (Fluxo Completo)**
```dart
class BatteryManager {
  int currentLevel = 100;  // %
  
  void checkBattery() {
    if (currentLevel < 20) {
      _triggerBatteryAlert();
    }
    
    if (currentLevel < 10) {
      _triggerCriticalMode();
    }
  }
  
  void _triggerBatteryAlert() {
    // Estima tempo restante baseado em consumo médio
    Duration timeRemaining = estimateRemainingTime();
    
    Alert alert = Alert(
      priority: AlertPriority.high,
      message: "Bateria: $currentLevel%. Tempo estimado: ${timeRemaining.inMinutes} min",
      type: AlertType.batteryCritical,
      vibrate: true,
      sound: true
    );
    
    // Oferece ações
    showAlertDialog(
      alert,
      actions: [
        "Ativar Modo Economia",
        "Retornar Agora",
        "Continuar"
      ]
    );
  }
  
  void _triggerCriticalMode() {
    // Redução automática agressiva
    mapService.disable();           // Desliga mapa
    screenBrightness.set(0.5);      // 50% brilho
    sensorFPS.set(1);               // 1 Hz ao invés de 10 Hz
    cameraService.disable();        // Sem fotos
    
    // UI mínima
    switchToInstrumentMode();
  }
  
  Duration estimateRemainingTime() {
    // Baseado em histórico de consumo
    double avgConsumptionPerHour = 15.0;  // % por hora (média)
    double remainingHours = currentLevel / avgConsumptionPerHour;
    return Duration(minutes: (remainingHours * 60).toInt());
  }
}
```

---

## 🎨 CAMADA 2: MODO INSTRUMENTOS (DETALHADO)

### 2.1 Layout (Especificação Pixel-Perfect)

```
┌─────────────────────────────────────┐
│  ☀️ MODO SOL FORTE                  │  ← Header (60px)
├─────────────────────────────────────┤
│                                     │
│     ┌───────────────────┐          │
│     │                   │          │
│     │      340°         │ ← Rumo atual (48px, bold)
│     │    ↑  ⬆️  ↑       │          │
│     │  Alvo: 320°      │ ← Rumo alvo (32px)
│     │  ⬅️ CORRIGIR 20° │ ← Correção (40px, cor dinâmica)
│     │                   │          │
│     └───────────────────┘          │  Bússola (300x300px)
│                                     │
├─────────────────────────────────────┤
│  ⚡ 45 km/h  📏 12.3 km  ⏱️ 0:34  │  ← Métricas (80px)
├─────────────────────────────────────┤
│  🔋 23% (⚠️ 15 min restantes)      │  ← Bateria (60px)
├─────────────────────────────────────┤
│  🟢 Dentro do buffer (+5m)         │  ← Status buffer (60px)
├─────────────────────────────────────┤
│  [📸] [⚠️ PERIGO] [⛽ PARAR]      │  ← Ações (100px)
└─────────────────────────────────────┘
```

### 2.2 Cores (Paleta de Alto Contraste)

```dart
class InstrumentColors {
  // Background
  static const background = Color(0xFF000000);  // Preto puro
  
  // Texto principal
  static const textPrimary = Color(0xFFFFFFFF);  // Branco puro
  
  // Alertas
  static const success = Color(0xFF00FF00);      // Verde saturado
  static const warning = Color(0xFFFFFF00);      // Amarelo saturado
  static const danger = Color(0xFFFF0000);       // Vermelho saturado
  
  // Bússola
  static const compassNeedle = Color(0xFF00FFFF);  // Ciano
  static const compassTarget = Color(0xFFFF00FF);  // Magenta
  
  // Métricas
  static const speed = Color(0xFF00FF00);          // Verde
  static const distance = Color(0xFFFFFFFF);       // Branco
  static const time = Color(0xFF00FFFF);           // Ciano
}
```

---

## 💾 CAMADA 3: REGISTRO CONTEXTUAL (DETALHADO)

### 3.1 Fotos Automáticas

#### **Fluxo de Captura**
```dart
class PhotoService {
  Future<void> captureAutoWaypoint() async {
    // 1. Tirar foto
    final XFile photo = await cameraController.takePicture();
    
    // 2. Obter contexto
    final context = NavigationContext(
      position: gpsService.currentPosition!,
      speed: gpsService.currentSpeed!,
      heading: compassService.trueHeading!,
      timestamp: DateTime.now(),
      weather: await weatherService.getCurrentWeather()  // Se online
    );
    
    // 3. Adicionar EXIF
    await addExifData(photo, context);
    
    // 4. Criar waypoint
    final waypoint = Waypoint(
      id: uuid.v4(),
      name: "Foto ${DateTime.now().toIso8601String()}",
      latitude: context.position.latitude,
      longitude: context.position.longitude,
      photoPath: photo.path,
      createdAt: context.timestamp,
      metadata: context
    );
    
    // 5. Salvar localmente
    await waypointRepository.save(waypoint);
    
    // 6. Sincronizar depois (não bloqueia)
    syncService.enqueue(waypoint);
  }
}
```

---

### 3.2 Incidentes (1 Toque)

#### **Interface de Registro Rápido**
```dart
enum IncidentType {
  enrosco,        // Galho/rede no propulsor
  pedraSubmersa,  // Bateu em pedra
  troncoFlutuante,
  baixaProfundidade,
  outro
}

class IncidentService {
  Future<void> registerIncident(IncidentType type) async {
    // Registro instantâneo (< 500ms)
    final incident = Incident(
      id: uuid.v4(),
      type: type,
      position: gpsService.currentPosition!,
      speed: gpsService.currentSpeed!,
      timestamp: DateTime.now()
    );
    
    // Salva localmente
    await incidentRepository.save(incident);
    
    // Mostra confirmação visual
    showToast("⚠️ Perigo registrado");
    
    // Permite detalhamento posterior (opcional)
    _showDetailDialog(incident);
  }
  
  void _showDetailDialog(Incident incident) {
    // Usuário pode adicionar:
    // - Nota de voz
    // - Foto
    // - Descrição textual
    // Mas não é obrigatório (navegação continua)
  }
}
```

---

## 🔧 CAMADA 4: GESTÃO DE JET (DETALHADO)

### 4.1 Modelo de Dados

```dart
class Jet {
  String id;
  String name;              // "Sea-Doo GTI 90"
  String model;
  int year;
  
  double totalHours;        // Horas de uso acumuladas
  double lastMaintenanceHours;
  
  double fuelTankCapacity;  // Litros (ex: 60L)
  String fuelType;          // "Gasolina Comum", "Premium"
  
  List<MaintenanceRecord> maintenanceHistory;
  List<FuelRecord> fuelHistory;
}

class FuelRecord {
  String id;
  DateTime timestamp;
  
  double liters;            // Quantidade abastecida
  double pricePerLiter;     // R$/L
  double totalCost;         // R$
  
  String? location;         // Opcional (GPS ou texto)
  String jetId;
}

class MaintenanceRecord {
  String id;
  DateTime date;
  
  double hoursAtMaintenance;
  MaintenanceType type;
  
  String description;
  double? cost;
  String? mechanic;
}

enum MaintenanceType {
  oilChange,
  sparkPlugs,
  impellerReplacement,
  engineOverhaul,
  other
}
```

### 4.2 Cálculo de Consumo

```dart
class FuelEstimator {
  // Estimativa baseada em horas e perfil do jet
  double estimateConsumption(Jet jet, Duration navigationTime) {
    // Consumo médio: ~10-15 L/h (depende do modelo)
    double avgConsumptionPerHour = jet.model == "GTI 90" ? 12.0 : 15.0;
    
    double hours = navigationTime.inMinutes / 60.0;
    return avgConsumptionPerHour * hours;
  }
  
  // Custo estimado
  double estimateCost(Jet jet, Duration navigationTime) {
    double liters = estimateConsumption(jet, navigationTime);
    double avgPricePerLiter = _getAverageFuelPrice(jet);
    
    return liters * avgPricePerLiter;
  }
  
  double _getAverageFuelPrice(Jet jet) {
    // Calcula média dos últimos 5 abastecimentos
    final recentRecords = jet.fuelHistory.take(5);
    if (recentRecords.isEmpty) return 6.50;  // Valor padrão
    
    return recentRecords
      .map((r) => r.pricePerLiter)
      .reduce((a, b) => a + b) / recentRecords.length;
  }
}
```

---

## ⌚ CAMADA 6: SMARTWATCH (PREPARAÇÃO ARQUITETURAL)

### 6.1 Protocolo de Comunicação

```dart
class WearableService {
  // Conexão Bluetooth Low Energy (BLE)
  BluetoothDevice? connectedWatch;
  
  // Envia dados mínimos (economiza bateria)
  void sendNavigationUpdate() {
    if (connectedWatch == null) return;
    
    final payload = {
      'speed': gpsService.currentSpeed?.toInt() ?? 0,
      'heading': compassService.trueHeading?.toInt() ?? 0,
      'headingError': navigationEngine.getHeadingError().toInt(),
      'bufferStatus': routeBuffer.getStatus().index,
      'batteryLevel': batteryManager.currentLevel
    };
    
    // Envio compacto (< 100 bytes)
    wearChannel.send(jsonEncode(payload));
  }
  
  // Recebe comandos do relógio
  void handleWearCommand(String command) {
    switch (command) {
      case 'WAYPOINT':
        photoService.captureAutoWaypoint();
        break;
      case 'INCIDENT':
        showIncidentQuickDialog();
        break;
      case 'PAUSE':
        navigationEngine.pauseTracking();
        break;
    }
  }
}
```

### 6.2 Biometria

```dart
class BiometricService {
  Stream<int>? heartRateStream;  // BPM
  
  void startMonitoring() {
    heartRateStream = wearableService.getHeartRateStream();
    
    heartRateStream!.listen((bpm) {
      // Associa batimentos à posição GPS
      biometricRepository.save(BiometricData(
        timestamp: DateTime.now(),
        position: gpsService.currentPosition!,
        heartRate: bpm
      ));
      
      // Alerta se stress excessivo
      if (bpm > 150) {
        showAlert("⚠️ Batimentos elevados: $bpm BPM. Reduza velocidade.");
      }
    });
  }
}
```

---

## 🔋 OTIMIZAÇÃO DE BATERIA (ESTRATÉGIAS)

### 1. FPS Adaptativo de Sensores

```dart
class AdaptiveSensorManager {
  int currentFPS = 10;  // Hz (atualizações por segundo)
  
  void adjustFPS(int batteryLevel) {
    if (batteryLevel > 50) {
      currentFPS = 10;  // Normal
    } else if (batteryLevel > 20) {
      currentFPS = 5;   // Reduzido
    } else {
      currentFPS = 1;   // Mínimo
    }
    
    sensorController.setUpdateInterval(
      Duration(milliseconds: 1000 ~/ currentFPS)
    );
  }
}
```

### 2. Desligamento Progressivo de Features

```
Bateria 100-50%:  Tudo ativo
Bateria 50-30%:   Reduzir FPS do mapa (60 → 30)
Bateria 30-20%:   Desligar câmera, reduzir FPS sensores (10 → 5)
Bateria 20-10%:   Modo instrumentos forçado
Bateria < 10%:    FPS mínimo (1 Hz), brilho 30%
```

---

## 🛡️ SEGURANÇA E PRIVACIDADE

### 1. Armazenamento Local Criptografado

```dart
class SecureStorage {
  // Hive com AES-256
  late Box<Track> tracksBox;
  late Box<Waypoint> waypointsBox;
  
  Future<void> init() async {
    final encryptionKey = await _getEncryptionKey();
    
    tracksBox = await Hive.openBox<Track>(
      'tracks',
      encryptionCipher: HiveAesCipher(encryptionKey)
    );
  }
  
  Future<List<int>> _getEncryptionKey() async {
    // Derivada do device ID (não requer PIN do usuário)
    final deviceId = await deviceInfo.getDeviceId();
    return sha256.convert(utf8.encode(deviceId)).bytes;
  }
}
```

### 2. Compartilhamento Ao Vivo (Token Temporário)

```dart
class LiveSharingService {
  Future<String> createLiveSession(Duration validity) async {
    final token = uuid.v4();
    
    await supabase.from('live_sessions').insert({
      'token': token,
      'user_id': auth.currentUser!.id,
      'expires_at': DateTime.now().add(validity).toIso8601String()
    });
    
    return 'https://navjet.app/live/$token';
  }
  
  // Backend valida token antes de retornar coordenadas
}
```

---

## 📊 MÉTRICAS DE PERFORMANCE

### Targets (V1)

| Métrica | Valor Alvo | Crítico |
|---------|-----------|---------|
| Consumo de bateria (navegação ativa) | < 15%/hora | < 20%/hora |
| Tempo de abertura do app | < 2s | < 5s |
| Latência de sensores | < 100ms | < 200ms |
| Precisão de rumo | ± 5° | ± 10° |
| Tamanho do APK | < 50 MB | < 100 MB |
| FPS em modo normal | 60 FPS | 30 FPS |

---

## 🧪 ESTRATÉGIA DE TESTES

### 1. Testes de Sensores (Unitários)

```dart
test('Sensor fusion corrige interferência magnética', () {
  final fusion = SensorFusion();
  
  // Simula interferência (motor do jet)
  fusion.updateMagnetometer(heading: 45.0, quality: 30);  // Baixa qualidade
  fusion.updateGyroscope(angularVelocity: 2.0);
  
  final fusedHeading = fusion.getFusedHeading();
  
  // Deve usar mais giroscópio quando magnetômetro não confiável
  expect(fusedHeading, closeTo(47.0, 2.0));
});
```

### 2. Testes de Campo (Manuais)

- [ ] Navegação em rio com corrente forte (testar buffer de desvio)
- [ ] Bateria crítica (< 10%) durante navegação (testar modo economia)
- [ ] Perda de sinal GPS (túnel/ponte) (testar fallback)
- [ ] Interferência magnética (próximo a motor) (testar sensor fusion)
- [ ] Smartwatch desconectado (testar graceful degradation)

---

## 🚀 ROADMAP DE IMPLEMENTAÇÃO (Por Camada)

### Sprint 1-2 (Semanas 1-4): Camada 1
- GPS + Bússola + Sensor Fusion
- Cálculo de rumo
- Buffer de desvio

### Sprint 3 (Semanas 5-6): Camada 2
- Modo instrumentos
- UI de alto contraste

### Sprint 4-5 (Semanas 7-10): Camada 3
- Fotos automáticas
- Registro de incidentes
- Waypoints

### Sprint 6 (Semanas 11-12): Camada 4
- Gestão de jet
- Registro de combustível

### Sprint 7-8 (Semanas 13-16): Camada 5
- Mapas offline
- Camadas opcionais

### Sprint 9+ (Semanas 17+): Camada 6
- Smartwatch
- Biometria
