# NavigatorJet 🚤

**Instrumento digital de navegação para Jet Ski e embarcações leves**

[![Flutter](https://img.shields.io/badge/Flutter-3.24+-02569B?logo=flutter)](https://flutter.dev/)
[![Dart](https://img.shields.io/badge/Dart-3.5+-0175C2?logo=dart)](https://dart.dev/)
[![License](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)

---

## 📖 O que é NavigatorJet?

NavigatorJet é um aplicativo de navegação náutica projetado para funcionar **mesmo em condições adversas**:
- ❌ **Sem sinal de internet**
- 🔋 **Bateria baixa**
- ☀️ **Sol forte**
- 🌊 **Correntes e ondulação**

### Diferenciais

| Feature | Fishing Points | Navionics | NavigatorJet |
|---------|----------------|-----------|--------------|
| Navegação por rumo | ❌ | ✅ | ✅ |
| Modo instrumentos (sem mapa) | ❌ | ❌ | ✅ |
| Buffer de desvio configurável | ❌ | ❌ | ✅ |
| Alertas de bateria inteligentes | ❌ | ❌ | ✅ |
| Gestão de jet (horas, combustível) | ❌ | ❌ | ✅ |
| Mapas offline | ⚠️ Limitado | ✅ Pago | ✅ Gratuito |
| Smartwatch | ❌ | ❌ | ✅ (V3) |

---

## 🎯 Para Quem é Este App?

### Persona Principal: **Ricardo, Operador Sério de Jet Ski**
- 45-55 anos, engenheiro aposentado
- Sea-Doo GTI 90, Galaxy S24 FE, Huawei Watch GT 4
- Navega em represas do interior de SP (Rifaina, Capitólio)
- Sem sinal de celular 80% do tempo
- Preocupado com consumo, manutenção e segurança

### Casos de Uso
1. **Planejamento**: Planeja rota no Google Earth → Importa GPX → Define direção (Ida/Volta)
2. **Navegação**: Segue tracking route no mapa + bússola compacta sempre visível
3. **Registro**: Tira fotos (waypoints automáticos) + marca perigos com 1 toque
4. **Gestão**: Registra combustível, horas de uso, manutenções

---

## 🚀 Instalação

### Pré-requisitos
- **Flutter SDK**: 3.24+
- **Dart SDK**: 3.5+
- **Android Studio**: Para emulador e SDK tools
- **VS Code**: Editor recomendado

### Passos

1. **Clone o repositório**:
   ```bash
   git clone https://github.com/seu-usuario/navigatorjet.git
   cd navigatorjet
   ```

2. **Instale as dependências**:
   ```bash
   flutter pub get
   ```

3. **Configure variáveis de ambiente**:
   Crie o arquivo `.env` na raiz:
   ```env
   SUPABASE_URL=https://your-project.supabase.co
   SUPABASE_ANON_KEY=your_anon_key
   OPENWEATHER_API_KEY=your_key
   ```

4. **Gere os adapters Hive**:
   ```bash
   dart run build_runner build --delete-conflicting-outputs
   ```

5. **Execute o app**:
   ```bash
   # Emulador Android
   flutter run

   # Web
   flutter run -d chrome

   # Dispositivo físico (USB Debug ativado)
   flutter run -d <device_id>
   ```

---

## 📱 Funcionalidades

### ✅ V1.0 - "Núcleo Navegacional" (Atual)

#### 1. Navegação por Rumo
- Bússola magnética com sensor fusion (magnetômetro + giroscópio)
- Cálculo contínuo: Rumo atual vs. Rumo alvo
- Indicação visual de correção (⬅️ esquerda / ➡️ direita)

#### 2. Modo Instrumentos (Fallback)
- Funciona **sem mapa** (apenas sensores)
- Alto contraste (preto + branco/verde/vermelho)
- Legível sob sol forte

#### 3. Buffer de Desvio
- Tolerância lateral configurável (10-500m)
- Alertas progressivos: 🟢 Centro → 🟡 Próximo da borda → 🔴 Fora
- Cálculo de cross-track distance (distância perpendicular ao eixo da rota)

#### 4. Alertas de Bateria
- Monitoramento contínuo
- Estimativa de tempo de navegação restante
- Redução automática de brilho + FPS
- Modo instrumentos forçado quando bateria < 10%

#### 5. Fotos Geolocalizadas
- Botão "📷" cria waypoint automático
- EXIF com GPS + timestamp
- Armazenamento local (Hive)

#### 6. Importação de GPX/KML
- Google Earth, Wikiloc, etc.
- Seleção de direção (Ida / Volta)
- Inversão de rota com 1 toque

### 🚧 V2.0 - "Gestão Operacional" (Planejado)
- Gestão de múltiplos jets
- Registro de combustível (litros, preço, custo)
- Estatísticas pós-navegação (consumo, custo)
- Incidentes com 1 toque (Enrosco, Pedra, Perigo)
- Mapas offline (.mbtiles)

### 🔮 V3.0 - "Ecossistema Integrado" (Futuro)
- Smartwatch (Huawei Watch GT 4)
- Biometria (batimentos, stress)
- Sincronização multi-dispositivo (Supabase)
- Preparação para rádios satelitais (Spot, inReach)

---

## 🗺️ Mapas

### Fontes de Tiles
- **OpenStreetMap**: Mapa base (gratuito)
- **OpenSeaMap**: Camada náutica (boias, faróis)
- **Cartas RENC**: Marinha do Brasil (apenas referência visual)

### Offline
- Download por região (ex: "Rifaina 50km²")
- Formato: `.mbtiles` (SQLite com tiles compactados)
- Gerenciamento de espaço (deletar regiões antigas)

**⚠️ Importante**: Mapas offline são **opcionais**. O app funciona sem eles via modo instrumentos.

---

## 🧭 Sensores

### GPS
- Posição, velocidade, altitude
- Taxa de atualização: 10 Hz (normal) / 1 Hz (eco)
- Fallback heading (quando bússola falha)

### Bússola Magnética
- Magnetômetro + giroscópio (sensor fusion)
- Calibração obrigatória antes da navegação
- Qualidade do sinal (0-100%)

### Bateria
- Monitoramento contínuo
- FPS adaptativo (10 Hz → 5 Hz → 1 Hz)
- Desligamento progressivo de features (câmera, mapa)

---

## 🎨 Design

### Princípios
1. **Safety-First**: Alertas nunca são suprimidos
2. **Alto Contraste**: Legível sob sol forte
3. **Leveza**: Baixo consumo de bateria
4. **UX Moderna**: Bonita E funcional

### Paleta de Cores (Modo Instrumentos)
```dart
background:   #000000  // Preto puro
textPrimary:  #FFFFFF  // Branco puro
success:      #00FF00  // Verde saturado
warning:      #FFFF00  // Amarelo saturado
danger:       #FF0000  // Vermelho saturado
```

### Tipografia
- **Rumo**: Roboto Bold, 72px
- **Velocidade**: Roboto Bold, 64px
- **Métricas**: Roboto Regular, 24px

---

## 🔒 Segurança e Privacidade

### Armazenamento Local
- **Hive**: Trilhas, waypoints, fotos (criptografia AES-256)
- **SQLite**: Gestão de jet, manutenção, combustível

### Backend (Supabase)
- Autenticação: Email/senha + OAuth Google
- PostgreSQL + PostGIS (dados geoespaciais)
- Storage: Fotos de waypoints
- Realtime: Sincronização multi-dispositivo

### Compartilhamento Ao Vivo
- Token temporário (validade: 24h)
- Link: `https://navjet.app/live/{token}`
- Usuário pode revogar a qualquer momento

---

## 🧪 Testes

### Rodar Testes
```bash
# Unitários
flutter test

# Coverage
flutter test --coverage
genhtml coverage/lcov.info -o coverage/html

# Integração
flutter test integration_test/
```

### Testes de Campo (V1)
- [x] Navegação sem internet (Rifaina)
- [x] Corrente forte (Rio Paraná)
- [x] Bateria crítica (< 10%)
- [ ] Interferência magnética (motor ligado)

---

## 📊 Performance

### Targets (V1)

| Métrica | Alvo | Crítico |
|---------|------|---------|
| Consumo de bateria | < 12%/hora | < 15%/hora |
| Tempo de abertura | < 2s | < 3s |
| Precisão de rumo | ± 5° | ± 10° |
| Tamanho APK | < 30 MB | < 50 MB |
| Crashes | 0 em 10h | < 1 em 10h |

---

## 🤝 Contribuindo

### Processo
1. Fork o projeto
2. Crie uma branch: `git checkout -b feature/nova-feature`
3. Commit: `git commit -m 'Add nova feature'`
4. Push: `git push origin feature/nova-feature`
5. Abra um Pull Request

### Code Style
- **Flutter Lints**: `very_good_analysis`
- **Comentários**: Em inglês
- **Variáveis**: Descritivas (`currentHeading`, não `x`)
- **Testes**: Cobertura > 80%

---

## 📄 Licença

MIT License - veja [LICENSE](LICENSE) para detalhes.

---

## 📞 Contato

- **Email**: contato@navigatorjet.app
- **GitHub**: [@navigatorjet](https://github.com/navigatorjet)
- **Discord**: [Comunidade NavigatorJet](https://discord.gg/navigatorjet)

---

## 🙏 Agradecimentos

- **Fishing Points**: Inspiração para UX de navegação náutica
- **Wikiloc**: Referência de importação de GPX
- **Nautide**: Inspiração para dados meteorológicos
- **Comunidade Flutter Brasil**: Suporte técnico

---

## 🗺️ Roadmap

### ✅ V1.0 - Núcleo (Concluído)
- Sensores (GPS + Bússola + Fusion)
- Modo instrumentos
- Navegação por rumo
- Buffer de desvio
- Alertas de bateria
- Fotos geolocalizadas

### 🚧 V2.0 - Gestão (Em Progresso)
- Gestão de jet
- Registro de combustível
- Incidentes com 1 toque
- Mapas offline

### 🔮 V3.0 - Integração (Planejado)
- Smartwatch
- Biometria
- Sincronização

### 💭 V4+ - Futuro
- Batimetria
- Comunidade
- IA preditiva

---

## ⚠️ Disclaimer

**NavigatorJet não substitui instrumentos oficiais de navegação.**

- Não use cartas náuticas deste app como base ativa
- Sempre tenha um plano B (mapa físico, rádio VHF)
- Navegação é de responsabilidade do operador
- App é fornecido "como está", sem garantias

---

## 📸 Screenshots

### Modo Navegação
![Navegação](screenshots/navigation.png)

### Modo Instrumentos
![Instrumentos](screenshots/instruments.png)

### Gestão de Jet
![Jet](screenshots/jet.png)

---

**Desenvolvido com ❤️ por Ricardo e a comunidade Flutter Brasil**

🚤 **Navegue Seguro. Navegue com NavigatorJet.**
