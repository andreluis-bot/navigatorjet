# NavigatorJet - Definição do Produto

## 1️⃣ SÍNTESE ABSOLUTA

### O que este app É (em uma frase)
**Um instrumento digital de navegação, segurança e registro operacional para Jet Ski e embarcações leves, projetado para funcionar mesmo quando tudo falha, com UX moderna e foco absoluto em retorno seguro.**

### O que ele NÃO é
- ❌ Não é app social
- ❌ Não é app de pesca
- ❌ Não é app de trilha terrestre
- ❌ Não é carta náutica oficial
- ❌ Não é "mapa bonito com pins"
- ❌ Não é substituto de plotter profissional

👉 **É instrumento de navegação pessoal, pensado por quem realmente navega.**

---

## 2️⃣ DIFERENCIAIS CRÍTICOS

### vs. Fishing Points
| Aspecto | Fishing Points | NavigatorJet |
|---------|----------------|--------------|
| Foco | Pesca + trilhas | **Navegação por rumo** |
| Sem Mapa | App inútil | **Modo instrumentos funciona** |
| Bússola | Secundária | **Sempre visível, ativa** |
| Alertas | Básicos | **Progressivos, configuráveis** |
| Bateria | Não gerencia | **Redução inteligente automática** |

### vs. Navionics
| Aspecto | Navionics | NavigatorJet |
|---------|-----------|--------------|
| Cartas | Vetoriais profissionais | **OSM/satélite de referência** |
| Preço | US$ 15/ano | **Gratuito** |
| Offline | Limitado | **100% offline** |
| Sensores | Básicos | **Fusion avançado** |
| Smartwatch | Não | **Preparado desde V1** |

### vs. Garmin inReach
| Aspecto | Garmin inReach | NavigatorJet |
|---------|----------------|--------------|
| Hardware | Dedicado (caro) | **Qualquer smartphone** |
| Satélite | SOS nativo | **Preparado para integração** |
| Gestão de Jet | Não | **Manutenção, consumo, horas** |
| Customização | Fechado | **Open-source (futuro)** |

---

## 3️⃣ PERSONA PRINCIPAL

### Ricardo - Operador Sério de Jet Ski
- **Idade**: 45-55 anos
- **Perfil**: Engenheiro aposentado, navega há 15+ anos
- **Equipamento**: Sea-Doo GTI 90, Galaxy S24 FE, Huawei Watch GT 4
- **Locais**: Represas do interior de SP (Rifaina, Capitólio, Furnas)
- **Cenário**: 
  - Saídas de 4-8 horas
  - Sem sinal de celular 80% do tempo
  - Navega com rotas GPX planejadas no Google Earth
  - Preocupação com consumo de combustível
  - Registra manutenções do jet

### Dores Atuais
1. **Wikiloc não foi feito para água**:
   - Sem bússola ativa
   - Sem buffer de desvio (correntes)
   - Bateria acaba rápido
   - Não registra combustível

2. **Fishing Points é para pesca**:
   - Foco em marcação de locais
   - Navegação secundária
   - Sem gestão de jet

3. **Navionics é caro e limitado**:
   - Cartas só para oceano/rios grandes
   - Represas não têm batimetria
   - Não registra histórico operacional

### Comportamento Típico
**Antes da Navegação:**
1. Planeja rota no Google Earth (desktop)
2. Exporta GPX
3. Transfere para o celular
4. Abre NavigatorJet
5. Importa GPX
6. Define direção (ida ou volta)
7. Configura buffer de desvio (50m)
8. Baixa mapas da região (se houver Wi-Fi)

**Durante a Navegação:**
1. Coloca celular em suporte à prova d'água
2. Inicia navegação
3. Olha para bússola a cada 30s
4. Corrige rumo conforme indicação
5. Tira foto de pontos de interesse (1 toque)
6. Marca perigos (1 toque) se encontrar algo

**Ao Parar:**
1. Registra litros de combustível abastecidos
2. Revisa fotos/incidentes
3. Verifica horas de uso do jet
4. Sincroniza com tablet (se houver internet)

**Em Casa:**
1. Revisa estatísticas de consumo
2. Planeja próxima manutenção
3. Exporta GPX da trilha para backup

---

## 4️⃣ CASOS DE USO CRÍTICOS

### Caso 1: Navegação Sem Mapa (Bateria Crítica)
**Contexto**: Bateria em 15%, ainda faltam 30 min de navegação.

**Comportamento do App:**
1. Detecta bateria < 20%
2. Exibe alerta: "Bateria crítica. Ativando modo economia."
3. Automaticamente:
   - Desliga mapa
   - Reduz brilho para 50%
   - Ativa modo instrumentos
   - Reduz FPS de sensores (10 Hz → 1 Hz)
4. Mostra estimativa: "15 min de navegação restantes"
5. Sugere: "Retornar agora ou ativar modo avião?"

**Resultado**: Usuário navega por bússola + GPS até retornar seguro.

---

### Caso 2: Desvio da Rota (Corrente Forte)
**Contexto**: Navegando rio acima, corrente puxa para a direita.

**Comportamento do App:**
1. Detecta que usuário está 30m à direita do eixo do GPX
2. Buffer configurado é 50m → **Não alerta ainda**
3. Exibe: "🟡 Desvio: +30m (direita)"
4. Mostra ângulo de correção: "⬅️ Corrigir 12° esquerda"
5. Se desvio > 50m:
   - Alerta sonoro
   - Vibração
   - Texto vermelho: "⚠️ FORA DA ROTA"

**Resultado**: Usuário corrige antes de se perder.

---

### Caso 3: Registro de Incidente (Enrosco)
**Contexto**: Jet enrosca galho no propulsor.

**Comportamento do App:**
1. Usuário toca botão "⚠️ PERIGO" (1 toque)
2. App registra:
   - GPS exato
   - Timestamp
   - Foto automática (se câmera disponível)
   - Velocidade antes do incidente
3. Pergunta: "Tipo de perigo?"
   - Enrosco
   - Pedra submersa
   - Tronco flutuante
   - Baixa profundidade
4. Permite nota de voz (opcional)
5. Marca no mapa (pin vermelho)

**Resultado**: Usuário e outros evitam o local no futuro.

---

### Caso 4: Smartwatch como Alerta Primário
**Contexto**: Celular no suporte, difícil de ver com sol forte.

**Comportamento do App:**
1. Smartwatch mostra:
   - Velocidade
   - Rumo atual vs. alvo
   - Desvio do buffer
2. Se saída do buffer:
   - Vibração forte no pulso
   - Alerta visual: "⬅️ 15°"
3. Se bateria crítica:
   - Vibração contínua
   - "🔋 15%"

**Resultado**: Usuário navega sem olhar para o celular.

---

## 5️⃣ PRINCÍPIOS DE DESIGN

### Safety-First
- **Nunca sacrificar segurança por estética**
- Alertas críticos têm prioridade sobre tudo
- Modo instrumentos sempre disponível

### Sensor-First
- **Sensores são mais confiáveis que mapas**
- Bússola sempre ativa, nunca escondida
- GPS heading como fallback

### Offline-First
- **Nada crítico depende de internet**
- Mapas são opcionais, não obrigatórios
- Sincronização posterior, nunca bloqueante

### UX Moderna e Atrativa
- **Alto contraste sob sol forte**
- Animações suaves (não distrativas)
- Cores saturadas (verde/amarelo/vermelho)
- Tipografia grande e legível

### Baixo Consumo
- **Otimização agressiva de bateria**
- Redução inteligente de FPS
- Modo avião sugerido automaticamente
- Desligamento de features não-críticas

---

## 6️⃣ FEATURES NÃO PRIORITÁRIAS (V4+)

### ❌ Não incluir no V1/V2/V3:
- Carta vetorial estilo Navionics
- Batimetria fina (curvas de nível)
- Comunidade social (compartilhar trilhas)
- Gamificação (conquistas, badges)
- Marketplace (venda de rotas)
- Integração profunda com ECU do jet
- IA preditiva de consumo
- Smartwatch para todos os modelos (apenas Huawei no V3)
- Radar avançado (apenas alertas básicos)

👉 **Tudo isso pode vir depois se o núcleo for perfeito.**

---

## 7️⃣ MÉTRICAS DE SUCESSO

### KPIs de Produto (V1)
- **Navegação sem mapa**: > 30% dos usuários usam modo instrumentos
- **Precisão de rumo**: Desvio < 5° em 90% do tempo
- **Bateria**: App consome < 15%/hora em navegação ativa
- **Incidentes registrados**: > 5/mês por usuário ativo

### KPIs de Produto (V2)
- **Gestão de jet**: > 80% dos usuários registram combustível
- **Fotos geolocalizadas**: > 10/mês por usuário
- **Estatísticas**: > 60% revisam consumo pós-navegação

### KPIs de Produto (V3)
- **Smartwatch**: > 40% dos usuários conectam relógio
- **Biometria**: > 20% ativam registro de batimentos
- **Sincronização**: < 5s para sync entre dispositivos

---

## 8️⃣ COMPARAÇÃO COMPETITIVA (Matriz de Posicionamento)

```
        Alto Custo
             │
   Navionics │  Garmin
             │  inReach
             │
─────────────┼─────────────── Profissional
             │
  Wikiloc    │ NavigatorJet ⭐
Fishing      │
 Points      │
             │
        Gratuito
```

**Posicionamento**: 
- Profissionalismo do Garmin
- Custo do Wikiloc
- Usabilidade moderna

---

## 9️⃣ RISCOS E MITIGAÇÕES

### Risco Legal
**Problema**: Uso de cartas náuticas oficiais como base ativa.

**Mitigação**: 
- Cartas apenas como referência visual
- Disclaimer obrigatório: "Não substituir instrumentos oficiais"
- Termos de uso claros

### Risco Técnico
**Problema**: Sensor fusion falha em ambientes com interferência eletromagnética.

**Mitigação**:
- Calibração obrigatória antes da navegação
- Fallback para GPS heading
- Alerta ao usuário se magnetômetro não confiável

### Risco de UX
**Problema**: Interface poluída com excesso de informações.

**Mitigação**:
- Modo instrumentos com zero distrações
- Configuração de visibilidade de widgets
- Foco em 3-5 métricas críticas por tela

### Risco de Bateria
**Problema**: App drena bateria rapidamente.

**Mitigação**:
- Testes de consumo contínuos
- Modo eco automático
- Redução de FPS progressiva
- Sugestão de power bank

---

## 🔟 ROADMAP DE VALOR

### V1 - "Navegue Seguro" (45 dias)
**Valor entregue**: Navegação confiável sem internet.

### V2 - "Gerencie seu Jet" (75 dias)
**Valor entregue**: Histórico operacional completo.

### V3 - "Ecossistema Integrado" (105 dias)
**Valor entregue**: Smartwatch + biometria + sincronização.

### V4+ - "Comunidade e IA" (Futuro)
**Valor entregue**: Compartilhamento de perigos + previsão de consumo.
