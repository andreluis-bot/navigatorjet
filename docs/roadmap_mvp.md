# NavigatorJet - Roadmap MVP

## 🎯 FILOSOFIA DE RELEASES

### Princípio "Core-First"
Cada release adiciona valor sem quebrar funcionalidades anteriores.

### Princípio "Field-Tested"
Toda feature crítica deve ser testada em navegação real antes da próxima release.

### Princípio "No-Blocker"
Funcionalidades opcionais (mapas, smartwatch) nunca podem bloquear navegação básica.

---

## 📅 V1.0 - "NÚCLEO NAVEGACIONAL" (45 dias)

### 🎯 Objetivo
Entregar instrumento de navegação funcional sem internet.

### ✅ Features Obrigatórias

#### 1. Sensores Funcionando
- [x] GPS (posição, velocidade, altitude)
- [x] Bússola magnética (heading)
- [x] Sensor fusion (magnetômetro + giroscópio)
- [x] Calibração obrigatória antes da navegação

**Critérios de Sucesso:**
- Precisão de rumo: ± 5° em 90% do tempo
- Latência < 100ms

---

#### 2. Modo Instrumentos (Sem Mapa)
- [x] Bússola grande (300x300px)
- [x] Velocímetro digital (fonte 72px)
- [x] Cronômetro
- [x] Coordenadas GPS (lat/lng)
- [x] Tema de alto contraste (preto + branco/verde/vermelho)

**Critérios de Sucesso:**
- Legível sob sol forte (teste em campo)
- Consumo < 10%/hora de bateria

---

#### 3. Importação de GPX
- [x] Suporte a .gpx e .kml
- [x] Seletor de direção (Ida / Volta)
- [x] Preview da rota no mapa (se disponível)
- [x] Inversão de rota com 1 toque

**Critérios de Sucesso:**
- Importa GPX do Wikiloc/Google Earth sem erros
- Suporta rotas com 1000+ pontos

---

#### 4. Navegação por Rumo
- [x] Cálculo contínuo de rumo atual vs. rumo alvo
- [x] Indicação visual de correção (⬅️ esquerda / ➡️ direita)
- [x] Atualização do próximo waypoint automaticamente
- [x] Indicador de distância ao próximo ponto

**Critérios de Sucesso:**
- Cálculo de bearing preciso (< 1° de erro)
- Avança para próximo waypoint quando < 50m

---

#### 5. Buffer de Desvio
- [x] Configuração de raio (10-500m)
- [x] Cálculo de cross-track distance
- [x] Estados visuais: 🟢 Centro, 🟡 Próximo da borda, 🔴 Fora
- [x] Métrica de desvio em metros

**Critérios de Sucesso:**
- Cálculo correto de distância perpendicular ao eixo
- Sem falsos positivos em curvas acentuadas

---

#### 6. Alertas de Bateria
- [x] Monitoramento contínuo do nível
- [x] Alerta em 20%, 10%, 5%
- [x] Estimativa de tempo restante de navegação
- [x] Redução automática de brilho (bateria < 20%)
- [x] Modo instrumentos forçado (bateria < 10%)

**Critérios de Sucesso:**
- Estimativa de tempo com ± 5 min de precisão
- App continua funcionando até 0% (sem crash)

---

#### 7. Registro de Fotos como Waypoints
- [x] Botão "📷" na tela de navegação (1 toque)
- [x] Foto capturada automaticamente
- [x] Waypoint criado com GPS + timestamp
- [x] EXIF com lat/lng adicionado à foto
- [x] Armazenamento local (Hive)

**Critérios de Sucesso:**
- Foto capturada em < 1 segundo
- EXIF correto (validar no Google Photos)

---

### 🚫 Features NÃO Incluídas no V1
- ❌ Mapas offline (apenas se houver internet ativa)
- ❌ Sincronização com backend
- ❌ Gestão de jet
- ❌ Smartwatch
- ❌ Incidentes com 1 toque (apenas waypoints manuais)

---

### 📊 KPIs de Sucesso (V1)

| Métrica | Alvo | Crítico |
|---------|------|---------|
| Consumo de bateria | < 12%/hora | < 15%/hora |
| Tempo de abertura | < 2s | < 3s |
| Precisão de rumo | ± 5° | ± 10° |
| Tamanho APK | < 30 MB | < 50 MB |
| Crashes | 0 em 10h de navegação | < 1 em 10h |

---

### 🧪 Plano de Testes de Campo (V1)

#### Teste 1: Navegação Sem Internet
- **Local**: Represa de Rifaina
- **Cenário**: Jet Ski, rota de 15 km, sem sinal 4G
- **Validar**:
  - Modo instrumentos funciona
  - Bússola precisa
  - Bateria dura > 2h

#### Teste 2: Corrente Forte
- **Local**: Rio Paraná (trecho com correnteza)
- **Cenário**: Buffer de 50m, vento lateral
- **Validar**:
  - Buffer detecta desvio corretamente
  - Alertas progressivos funcionam
  - Sem falsos positivos

#### Teste 3: Bateria Crítica
- **Local**: Navegação controlada (porto)
- **Cenário**: Iniciar com bateria em 25%
- **Validar**:
  - Alerta em 20%
  - Modo economia ativa
  - App continua funcionando até 0%

---

### 📦 Entregáveis (V1)

1. **APK instalável** (Android 8.0+)
2. **Manual de uso** (PDF, 5 páginas)
3. **Vídeo de demonstração** (YouTube, 3 min)
4. **Relatório de testes de campo** (Google Docs)

---

## 📅 V2.0 - "GESTÃO OPERACIONAL" (75 dias)

### 🎯 Objetivo
Transformar o app em ferramenta completa de gestão de jet.

### ✅ Features Obrigatórias

#### 1. Gestão de Múltiplos Jets
- [x] Cadastro de jets (nome, modelo, ano)
- [x] Horas de uso (automático via tempo de navegação)
- [x] Inserção manual de horas (caso esqueça de gravar)
- [x] Seleção de jet ativo antes de navegar

---

#### 2. Registro de Combustível
- [x] Tela de abastecimento (litros, R$/L, total)
- [x] GPS do posto (opcional)
- [x] Histórico de abastecimentos
- [x] Gráfico de preço ao longo do tempo

---

#### 3. Estatísticas Pós-Navegação
- [x] Consumo estimado (baseado em horas)
- [x] Custo estimado
- [x] Comparação: Navegação atual vs. histórico
- [x] Exportação de relatório (PDF)

---

#### 4. Incidentes com 1 Toque
- [x] Botões rápidos: Enrosco, Pedra, Tronco, Perigo
- [x] Registro instantâneo (GPS + foto opcional)
- [x] Marcação no mapa (pin vermelho)
- [x] Compartilhamento com outros usuários (futuro)

---

#### 5. Mapas Offline (Opcional)
- [x] Download de tiles por região (seleção no mapa)
- [x] Formato .mbtiles
- [x] Camadas: OSM + OpenSeaMap
- [x] Gerenciamento de espaço (deletar regiões antigas)

---

### 🚫 Features NÃO Incluídas no V2
- ❌ Smartwatch
- ❌ Biometria
- ❌ Sincronização multi-dispositivo

---

### 📊 KPIs de Sucesso (V2)

| Métrica | Alvo | Crítico |
|---------|------|---------|
| Usuários que registram combustível | > 70% | > 50% |
| Incidentes marcados | > 3/mês por usuário | > 1/mês |
| Mapas baixados | > 50% dos usuários | > 30% |
| Estatísticas revisadas | > 60% pós-navegação | > 40% |

---

### 🧪 Plano de Testes de Campo (V2)

#### Teste 1: Gestão de Jet
- **Cenário**: Usuário cadastra 2 jets, navega com cada um
- **Validar**:
  - Horas acumulam corretamente
  - Consumo estimado é realista (± 2L de erro)
  - Estatísticas corretas

#### Teste 2: Incidentes
- **Cenário**: Marcar 5 perigos diferentes durante navegação
- **Validar**:
  - Registro em < 3 segundos
  - GPS preciso
  - Foto opcional funciona

---

## 📅 V3.0 - "ECOSSISTEMA INTEGRADO" (105 dias)

### 🎯 Objetivo
Transformar o app em ecossistema completo com smartwatch e biometria.

### ✅ Features Obrigatórias

#### 1. Smartwatch (Huawei Watch GT 4)
- [x] Conexão Bluetooth Low Energy
- [x] Exibição de velocidade, rumo, desvio
- [x] Vibração em alertas críticos
- [x] Botão de waypoint rápido
- [x] Bateria do relógio visível no celular

---

#### 2. Biometria
- [x] Registro de batimentos cardíacos
- [x] Associação com posição GPS
- [x] Gráfico de stress ao longo da navegação
- [x] Alerta se BPM > 150

---

#### 3. Sincronização Multi-Dispositivo
- [x] Login com email/senha ou Google
- [x] Sync automático de trilhas/waypoints
- [x] Indicador de "pendente de sync"
- [x] Resolução de conflitos (last-write-wins)

---

#### 4. Preparação para Satélite
- [x] Arquitetura pronta para Spot/inReach
- [x] Botão de "SOS" conceitual (não envia ainda)
- [x] Registro de posição enviada

---

### 🚫 Features NÃO Incluídas no V3
- ❌ Batimetria
- ❌ Comunidade (compartilhamento público de trilhas)
- ❌ IA preditiva de consumo

---

### 📊 KPIs de Sucesso (V3)

| Métrica | Alvo | Crítico |
|---------|------|---------|
| Smartwatch conectado | > 40% dos usuários | > 25% |
| Biometria ativa | > 20% | > 10% |
| Sincronização bem-sucedida | > 95% | > 90% |
| Tempo de sync | < 5s | < 10s |

---

## 🚀 V4+ - "FUTURO" (Sem Data Definida)

### Features Planejadas (Não Comprometidas)
- Carta vetorial estilo Navionics
- Batimetria fina (curvas de nível)
- Comunidade (compartilhar trilhas/perigos)
- IA preditiva de consumo
- Suporte a todos os smartwatches (Garmin, Apple Watch)
- Radar meteorológico avançado
- Integração com ECU do jet (RPM, temperatura)
- Marketplace de rotas

---

## 📈 CRONOGRAMA CONSOLIDADO

```
Mês 1-2:    [████████████████████████████████████████] V1 - Núcleo
             Semanas 1-8

Mês 2-3:    [████████████████████                    ] V2 - Gestão
             Semanas 9-12

Mês 3-4:    [████████████                            ] V3 - Integração
             Semanas 13-16

Mês 4+:     [············                            ] V4+ - Futuro
```

---

## 🎯 PRIORIZAÇÃO (MoSCoW)

### Must Have (V1)
- Sensores
- Modo instrumentos
- Navegação por rumo
- Buffer de desvio
- Alertas de bateria
- Fotos como waypoints

### Should Have (V2)
- Gestão de jet
- Registro de combustível
- Incidentes com 1 toque
- Mapas offline

### Could Have (V3)
- Smartwatch
- Biometria
- Sincronização

### Won't Have Now (V4+)
- Batimetria
- Comunidade
- IA preditiva

---

## 🧭 DEFINIÇÃO DE "PRONTO" (Definition of Done)

### Para cada Feature
- [x] Código completo e testado (unitários + integração)
- [x] UI/UX revisada (design bonito E funcional)
- [x] Testado em campo (navegação real)
- [x] Documentação atualizada
- [x] Zero crashes conhecidos

### Para cada Release
- [x] Todas as features "Pronto"
- [x] APK buildado com sucesso
- [x] Testes de campo completos (relatório)
- [x] Manual de uso atualizado
- [x] Vídeo de demonstração
- [x] Publicado no Google Play (beta)

---

## 🚨 RISCOS E MITIGAÇÕES

### Risco 1: Sensor Fusion Impreciso
**Probabilidade**: Alta  
**Impacto**: Crítico  
**Mitigação**:
- Testes de campo extensivos (motor do jet ligado)
- Fallback para GPS heading
- Calibração obrigatória

### Risco 2: Consumo de Bateria Excessivo
**Probabilidade**: Média  
**Impacto**: Alto  
**Mitigação**:
- Testes de bateria contínuos
- Modo eco agressivo
- FPS adaptativo

### Risco 3: Smartwatch Incompatível
**Probabilidade**: Média  
**Impacto**: Médio  
**Mitigação**:
- V3 suporta apenas Huawei (piloto)
- Expandir para outros modelos no V4+

### Risco 4: Atraso no Cronograma
**Probabilidade**: Média  
**Impacto**: Médio  
**Mitigação**:
- Sprints de 2 semanas (flexíveis)
- Features podem ser movidas entre releases
- V1 é o mínimo viável (não pode atrasar)

---

## 📞 COMUNICAÇÃO COM STAKEHOLDERS

### Releases Públicas
- **V1**: Beta fechado (apenas desenvolvedor + 5 testadores)
- **V2**: Beta aberto (Google Play Beta)
- **V3**: Lançamento oficial

### Feedback Loop
- Formulário Google Forms após cada navegação (beta)
- Reunião quinzenal com testadores
- GitHub Issues para bugs

---

## 🎓 LIÇÕES APRENDIDAS (Atualizado pós-releases)

### V1
- [ ] (A preencher após testes de campo)

### V2
- [ ] (A preencher após lançamento)

### V3
- [ ] (A preencher após lançamento)
