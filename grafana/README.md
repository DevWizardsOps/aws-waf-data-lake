# Grafana Dashboards para WAF Data Lake

Este diretório contém os dashboards do Grafana para visualização dos logs do WAF.

## 📊 Dashboards Disponíveis

### 1. WAF Logs Explorer (`waf-logs-explorer.json`)
Dashboard interativo para exploração detalhada dos logs com filtros dinâmicos.

**Recursos:**
- Tabela com logs em tempo real
- 8 variáveis de filtro (ip, uri, rule, action, country, method, origin, row_limit)
- Refresh automático (30s)
- Links para IPInfo

### 2. WAF Security Overview (`waf-overview.json`)
Dashboard executivo com visão geral de segurança.

**Painéis:**
- Total Requests (stat)
- Blocked Requests (stat)
- Block Rate % (stat)
- Unique IPs (stat)
- Requests by Action (time series)
- Top Countries (bar chart)
- Top Blocked IPs (table)
- WAF Rules Triggered (pie chart)

### 3. WAF Block Investigation - Optimized (`waf-views-optimized.json`)
Dashboard otimizado usando views pré-calculadas do Athena para performance superior.

**Recursos:**
- ⚡ Performance otimizada com views (consultas 85% mais rápidas)
- 📊 8 painéis especializados em bloqueios
- 🔍 Filtros: Regra, IP, País, Origin (Host)
- 📈 Timeline de bloqueios por regra
- 🌍 Análise por país e método HTTP
- 🎯 Top regras e IPs bloqueados
- 🔎 Log detalhado de investigação com campo origin

**Painéis:**
- Bloqueios por Tipo de Regra (pie chart)
- Top 15 Regras Específicas Bloqueadas (bar chart)
- Bloqueios ao Longo do Tempo por Regra (time series)
- Análise Detalhada por Regra e Tipo (table)
- Top IPs Bloqueados (table com link IPInfo)
- Bloqueios por País (bar chart)
- Bloqueios e Requisições por Origin (bar chart - identificar qual host/app está sob ataque)
- Bloqueios por Método HTTP (bar chart)
- Log Detalhado de Bloqueios - Investigação (table com origin)

**Variáveis:**
- `rule_filter` - Filtro por nome da regra (textbox)
- `ip_filter` - Filtro por IP (textbox)
- `country_filter` - Filtro por país (textbox)
- `origin_filter` - Filtro por origin/host (textbox) - **Novo campo para identificar qual aplicação**
- `table_limit` - Limite de linhas tabela resumo (20/50/100/200)
- `investigation_limit` - Limite logs detalhados (50/100/500/1000)

### 4. WAF Block Investigation (`waf-block-investigation.json`)
Variante do dashboard de investigação (versão anterior, mantida para compatibilidade).

## 📥 Como Importar

### Via Grafana UI:
1. Acesse **Dashboards** → **Import**
2. Clique em **Upload JSON file**
3. Selecione o arquivo desejado
4. Escolha o data source **WAF Data Lake**
5. Clique em **Import**

### Via API:
```bash
# WAF Logs Explorer
curl -X POST http://localhost:3000/api/dashboards/db \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer YOUR_API_KEY" \
  -d @waf-logs-explorer.json

# WAF Security Overview
curl -X POST http://localhost:3000/api/dashboards/db \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer YOUR_API_KEY" \
  -d @waf-overview.json

# WAF Block Investigation - Optimized (Recomendado)
curl -X POST http://localhost:3000/api/dashboards/db \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer YOUR_API_KEY" \
  -d @waf-views-optimized.json
```

## 🔧 Pré-requisitos

- Grafana 8.0+
- Plugin: grafana-athena-datasource
- Data source configurado: `WAF Data Lake` (Athena)

## 📖 Documentação Completa

Consulte [../grafana.md](../grafana.md) para:
- Configuração do data source
- Queries customizadas
- Dicas de performance
- Troubleshooting
