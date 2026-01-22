# NavigatorJet - Arquitetura de Mapas

## 🎯 PRINCÍPIO FUNDAMENTAL

**Mapas são PRIMÁRIOS, mas não OBRIGATÓRIOS.**

### Fluxo de Navegação

```
PLANEJAMENTO (Desktop/Casa)
    ↓
Google Earth → Exporta GPX → Transfere para celular
    ↓
NAVEGAÇÃO (No Jet)
    ↓
┌─────────────────────────────────────────┐
│ CENÁRIO A: MAPA DISPONÍVEL (NORMAL)    │
│ ├─ Mapa mostra tracking route          │
│ ├─ Posição atual + rastro              │
│ ├─ Bússola compacta no topo (sempre)   │
│ └─ Waypoints/perigos visíveis          │
└─────────────────────────────────────────┘
    ↓ Se mapa falha (sem tiles OU bateria < 10%)
┌─────────────────────────────────────────┐
│ CENÁRIO B: MODO INSTRUMENTOS (FALLBACK) │
│ ├─ Bússola grande (300x300px)          │
│ ├─ Rumo atual vs. alvo                 │
│ ├─ Correção visual (⬅️/➡️)              │
│ └─ Velocímetro + coordenadas           │
└─────────────────────────────────────────┘
```

---

## 🗺️ CAMADAS DE MAPA (Prioridade)

### 1. Mapa Base (OBRIGATÓRIO para navegação visual)
- **Online**: OpenStreetMap via tiles CDN
- **Offline**: Tiles baixados (.mbtiles)
- **Fallback**: Se nenhum disponível → Modo instrumentos

### 2. Tracking Route (Rota GPX)
- Linha colorida customizável
- Direção: Ida (⬆️ verde) ou Volta (⬇️ laranja)
- Waypoints numerados (1, 2, 3...)
- Setas de direção a cada 500m

### 3. Posição Atual
- Pin de barco/jet (orientado conforme heading)
- Rastro (últimos 100 pontos, linha tracejada)
- Buffer de desvio (círculo semitransparente)

### 4. Camadas Opcionais
- Vento (setas animadas)
- Clima (overlay de nuvens)
- Perigos marcados (pins vermelhos)
- OpenSeaMap (boias, faróis)

---

## 📍 ESTADOS DO MAPA

### Estado 1: Online + Conectado
```dart
class MapState {
  bool hasInternet = true;
  bool offlineTilesLoaded = false;
  
  TileProvider getCurrentTileProvider() {
    return NetworkTileProvider(url: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png');
  }
}
```

### Estado 2: Offline + Tiles Baixados
```dart
class MapState {
  bool hasInternet = false;
  bool offlineTilesLoaded = true;
  
  TileProvider getCurrentTileProvider() {
    return MBTilesTileProvider(filepath: '/data/.../rifaina.mbtiles');
  }
}
```

### Estado 3: Sem Mapa (Fallback)
```dart
class MapState {
  bool hasInternet = false;
  bool offlineTilesLoaded = false;
  
  Widget getFallbackWidget() {
    return InstrumentModeScreen(); // Apenas sensores
  }
}
```

---

## 🧭 BÚSSOLA COMPACTA (Sempre Visível)

### Características
- **Posição**: Tarja no topo do mapa (80px altura)
- **Visibilidade**: SEMPRE ativa (mesmo com mapa funcionando)
- **Inclinação**: Segue sensor de orientação do celular
- **Cores**:
  - COG (rumo atual): Branco
  - Rumo alvo: Magenta (#FF00FF)
  - Correção: Verde/Amarelo/Vermelho (conforme erro)

### Elementos
```
┌────────────────────────────────────────┐
│ COG      Rota a navegar     [Ida: 203°]│
│ 235° SW      < 5°            SW        │
│  ↑  ⬆️  ↑                              │
└────────────────────────────────────────┘
```

1. **COG (Course Over Ground)**: Rumo atual (GPS + bússola)
2. **Correção Angular**: `< 5°` = virar 5° esquerda
3. **Rumo Alvo**: Para onde você DEVE ir (bearing do GPX)
4. **Indicador Ida/Volta**: Toggle visual (seta ⬆️ ou ⬇️)

---

## 🎨 UX: Transição Mapa ↔ Instrumentos

### Trigger 1: Bateria Baixa
```dart
class BatteryManager {
  void checkBattery(int level) {
    if (level < 10) {
      _showCriticalDialog();
    }
  }
  
  void _showCriticalDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text('🔋 Bateria Crítica'),
        content: Text(
          'Mapa será desligado para economizar bateria.\n'
          'Modo instrumentos ativado.'
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _switchToInstrumentMode();
            },
            child: Text('OK'),
          ),
        ],
      ),
    );
  }
}
```

### Trigger 2: Mapa Não Disponível
```dart
class MapController {
  Future<void> loadMap() async {
    try {
      // Tenta carregar tiles online
      await _loadOnlineTiles();
    } catch (e) {
      try {
        // Fallback para tiles offline
        await _loadOfflineTiles();
      } catch (e) {
        // Fallback final: Modo instrumentos
        _switchToInstrumentMode();
        _showToast('Mapa indisponível. Navegando por instrumentos.');
      }
    }
  }
}
```

---

## 📦 DOWNLOAD DE MAPAS OFFLINE

### Interface de Download
```
+----------------------------------+
| 🗺️ Mapas Offline                |
+----------------------------------+
| 🔍 Pesquisar região...           |
|                                  |
| [Mapa com seleção de área]       |
|                                  |
| Região selecionada:              |
| • Rifaina, SP                    |
| • Área: 50 km²                   |
| • Zoom: 10-14                    |
| • Tamanho estimado: 180 MB       |
|                                  |
| [⬇️ Baixar Agora]                |
+----------------------------------+
```

### Estratégia de Armazenamento
```
/data/com.navigatorjet.app/files/maps/
├── osm_base_brazil.mbtiles       # Brasil inteiro (zoom 1-10, ~500 MB)
└── regions/
    ├── rifaina.mbtiles            # Zoom 11-14 (~180 MB)
    ├── capitolio.mbtiles          # Zoom 11-14 (~220 MB)
    └── furnas.mbtiles             # Zoom 11-14 (~300 MB)
```

---

## 🚀 PERFORMANCE DE MAPAS

### Otimizações

#### 1. Tile Caching
```dart
class TileCacheManager {
  final int maxCacheSize = 500; // MB
  
  Future<void> pruneCacheIfNeeded() async {
    final cacheSize = await _getCacheSize();
    if (cacheSize > maxCacheSize) {
      await _deleteOldestTiles();
    }
  }
}
```

#### 2. FPS Adaptativo do Mapa
```dart
class MapFPSController {
  int currentFPS = 60;
  
  void adjustFPS(int batteryLevel) {
    if (batteryLevel > 50) {
      currentFPS = 60;
    } else if (batteryLevel > 20) {
      currentFPS = 30;
    } else {
      currentFPS = 15; // Ou desligar mapa
    }
  }
}
```

#### 3. Renderização Progressiva
```dart
class MapRenderer {
  Future<void> renderMap() async {
    // Renderiza em ordem de prioridade:
    // 1. Tracking route (linha GPX)
    // 2. Posição atual
    // 3. Tiles do mapa
    // 4. Waypoints/perigos
    // 5. Camadas opcionais (vento, clima)
  }
}
```

---

## 🧪 TESTES DE CAMPO (Mapas)

### Checklist

#### Teste 1: Mapa Online
- [ ] Tiles carregam em < 2s
- [ ] Zoom suave (60 FPS)
- [ ] Pan sem lag
- [ ] Tracking route visível

#### Teste 2: Mapa Offline
- [ ] Tiles offline carregam em < 1s
- [ ] Sem diferença visual vs. online
- [ ] Funciona sem internet (modo avião)
- [ ] Área baixada suficiente (50 km²)

#### Teste 3: Transição para Modo Instrumentos
- [ ] Alerta de bateria em 10%
- [ ] Mapa desliga automaticamente
- [ ] Modo instrumentos carrega em < 1s
- [ ] Navegação continua sem interrupção

#### Teste 4: Correntes (Buffer de Desvio)
- [ ] Buffer calcula distância corretamente
- [ ] Alertas progressivos funcionam
- [ ] Sem falsos positivos em curvas
- [ ] Visual claro (🟢🟡🔴)

---

## 📊 COMPARAÇÃO: Mapa vs. Modo Instrumentos

| Aspecto | Mapa (Normal) | Modo Instrumentos (Fallback) |
|---------|---------------|------------------------------|
| **Consumo Bateria** | 15%/hora | 8%/hora |
| **Dados Móveis** | ~10 MB/hora (online) | 0 MB |
| **Precisão Navegação** | Visual + sensores | Apenas sensores |
| **Usabilidade** | Fácil (ver rota) | Requer atenção (rumo) |
| **Quando usar** | Sempre que possível | Emergência ou bateria baixa |

---

## 🔒 LEGAL: Cartas Náuticas

### ⚠️ IMPORTANTE
**Cartas náuticas oficiais (RENC) são APENAS REFERÊNCIA VISUAL.**

### Disclaimer Obrigatório
```dart
class MapScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          FlutterMap(...),
          
          // Disclaimer (exibido na primeira vez)
          if (_isFirstTime) 
            _buildDisclaimerOverlay(),
        ],
      ),
    );
  }
  
  Widget _buildDisclaimerOverlay() {
    return Container(
      color: Colors.black.withOpacity(0.9),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.warning_amber, color: Colors.orange, size: 64),
              SizedBox(height: 16),
              Text(
                'AVISO LEGAL',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 16),
              Text(
                'NavigatorJet NÃO substitui instrumentos oficiais de navegação.\n\n'
                'Cartas náuticas exibidas são apenas para referência visual.\n\n'
                'Sempre tenha um plano B (mapa físico, rádio VHF).\n\n'
                'Navegação é de responsabilidade do operador.',
                style: TextStyle(color: Colors.white, fontSize: 16),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => _acceptDisclaimer(),
                child: Text('LI E ACEITO'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
```

---

## 🎯 ROADMAP DE MAPAS

### V1.0 (Atual)
- [x] Mapa online (OSM)
- [x] Tracking route (linha GPX)
- [x] Posição atual + rastro
- [x] Bússola compacta sempre visível
- [ ] Fallback para modo instrumentos

### V2.0 (Próximo)
- [ ] Download de mapas offline (.mbtiles)
- [ ] Camada OpenSeaMap (boias, faróis)
- [ ] Gerenciamento de espaço (deletar regiões antigas)
- [ ] Buffer de desvio visual (círculo semitransparente)

### V3.0 (Futuro)
- [ ] Camadas de vento (animadas)
- [ ] Radar meteorológico
- [ ] Perigos compartilhados (comunidade)
- [ ] Integração com cartas RENC (apenas visualização)

---

## 🚦 DECISÃO EXECUTIVA

**Mapas são a interface primária, mas o app NUNCA depende deles para navegação básica.**

Se tudo falhar:
1. Mapa offline indisponível
2. Internet caiu
3. Bateria em 5%

**Você ainda navega por rumo e bússola.**

Isso é o diferencial do NavigatorJet.
