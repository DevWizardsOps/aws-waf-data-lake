# 📊 Integração Grafana com AWS Athena

Este guia descreve como conectar o Grafana ao AWS Athena para visualizar os logs do WAF armazenados no Data Lake.

## 🔧 Pré-requisitos

- Grafana instalado (versão 8.0+)
- Plugin Athena para Grafana instalado
- Credenciais AWS com permissões para:
  - Athena (executar queries)
  - S3 (ler dados e gravar resultados)
  - Glue (acessar catálogo)

## 📦 1. Instalação do Plugin Athena

### Via CLI do Grafana:
```bash
grafana-cli plugins install grafana-athena-datasource
```

### Via Docker:
```dockerfile
GF_INSTALL_PLUGINS=grafana-athena-datasource
```

Reinicie o Grafana após a instalação.

## 🔐 2. Configurar Credenciais AWS

### Opção A: IAM User (Access Key)
Crie um usuário IAM com a seguinte policy:

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "athena:GetQueryExecution",
        "athena:GetQueryResults",
        "athena:StartQueryExecution",
        "athena:StopQueryExecution",
        "athena:GetWorkGroup"
      ],
      "Resource": "*"
    },
    {
      "Effect": "Allow",
      "Action": [
        "glue:GetDatabase",
        "glue:GetTable",
        "glue:GetPartitions"
      ],
      "Resource": "*"
    },
    {
      "Effect": "Allow",
      "Action": [
        "s3:GetBucketLocation",
        "s3:GetObject",
        "s3:ListBucket",
        "s3:PutObject"
      ],
      "Resource": [
        "arn:aws:s3:::waf-data-lake-logs-*",
        "arn:aws:s3:::waf-data-lake-logs-*/*",
        "arn:aws:s3:::waf-data-lake-athena-results-*",
        "arn:aws:s3:::waf-data-lake-athena-results-*/*"
      ]
    }
  ]
}
```

### Opção B: IAM Role (Recomendado para ECS/EKS)
Anexe a policy acima à role do pod/container do Grafana.

## 🔌 3. Adicionar Data Source no Grafana

1. Acesse **Configuration** → **Data Sources** → **Add data source**
2. Procure por **Amazon Athena**
3. Configure:

| Campo | Valor |
|-------|-------|
| **Name** | `WAF Data Lake` |
| **Authentication Provider** | `Access & secret key` ou `Credentials file` |
| **Access Key ID** | `<SUA_ACCESS_KEY>` |
| **Secret Access Key** | `<SUA_SECRET_KEY>` |
| **Default Region** | `sa-east-1` |
| **Data source** | `waf_data_lake` (database) |
| **Workgroup** | `waf-data-lake` |
| **Output Location** | `s3://waf-data-lake-athena-results-<ACCOUNT_ID>-sa-east-1/` |

4. Clique em **Save & Test**

## 📊 4. Dashboards de Exemplo

### 🔍 Dashboard 1: Logs em Tempo Real (Table)

**Nome:** WAF Logs Explorer

**Query:**
```sql
SELECT
  from_unixtime("timestamp"/1000) AS event_time,
  action,
  httprequest.clientip AS client_ip,
  httprequest.country AS country,
  httprequest.httpmethod AS method,
  httprequest.host AS origin,
  httprequest.uri AS uri,
  terminatingruleid,
  terminatingruletype,
  httprequest.requestid AS request_id,
  json_format(CAST(labels AS JSON)) AS labels_json
FROM waf_data_lake.logs
WHERE 
  $__timeFilter(from_unixtime("timestamp"/1000))
  
  -- Filtros dinâmicos (variáveis do Grafana)
  AND ('${ip:raw}' = '' OR httprequest.clientip = '${ip:raw}')
  AND ('${uri:raw}' = '' OR httprequest.uri LIKE '%${uri:raw}%')
  AND ('${rule:raw}' = '' OR terminatingruleid = '${rule:raw}')
  AND ('${action:raw}' = '' OR action = '${action:raw}')
  AND ('${country:raw}' = '' OR httprequest.country = '${country:raw}')
  AND ('${method:raw}' = '' OR httprequest.httpmethod = '${method:raw}')
  AND ('${origin:raw}' = '' OR httprequest.host = '${origin:raw}')

ORDER BY event_time DESC
LIMIT ${row_limit:raw}
```

**Variáveis do Dashboard:**
| Nome | Tipo | Default |
|------|------|---------|
| `ip` | Text box | `` |
| `uri` | Text box | `` |
| `rule` | Text box | `` |
| `action` | Custom | `ALLOW,BLOCK,COUNT` |
| `country` | Text box | `` |
| `method` | Custom | `GET,POST,PUT,DELETE,OPTIONS` |
| `origin` | Text box | `` |
| `row_limit` | Custom | `100,500,1000,5000` |

**Configuração do Painel:**
- **Tipo:** Table
- **Transform:** Nenhum necessário
- **Override:**
  - `event_time`: Data format → `YYYY-MM-DD HH:mm:ss`
  - `client_ip`: Link → `https://ipinfo.io/${__value.raw}`

---

### 📈 Dashboard 2: Requisições por Ação (Time Series)

**Query:**
```sql
SELECT
  from_unixtime("timestamp"/1000) AS time,
  action,
  COUNT(*) AS requests
FROM waf_data_lake.logs
WHERE $__timeFilter(from_unixtime("timestamp"/1000))
GROUP BY 
  from_unixtime("timestamp"/1000),
  action
ORDER BY time
```

**Configuração:**
- **Tipo:** Time series
- **Format:** Time series
- **Legend:** `{{action}}`
- **Color scheme:** By series name

---

### 🌍 Dashboard 3: Top 10 Países (Bar Chart)

**Query:**
```sql
SELECT
  httprequest.country AS country,
  COUNT(*) AS requests,
  SUM(CASE WHEN action = 'BLOCK' THEN 1 ELSE 0 END) AS blocked
FROM waf_data_lake.logs
WHERE $__timeFilter(from_unixtime("timestamp"/1000))
GROUP BY httprequest.country
ORDER BY requests DESC
LIMIT 10
```

**Configuração:**
- **Tipo:** Bar chart
- **Orientation:** Horizontal
- **Color by:** Value

---

### 🛡️ Dashboard 4: Regras Mais Ativadas (Pie Chart)

**Query:**
```sql
SELECT
  COALESCE(terminatingruleid, 'Default Action') AS rule,
  COUNT(*) AS hits
FROM waf_data_lake.logs
WHERE 
  $__timeFilter(from_unixtime("timestamp"/1000))
  AND action = 'BLOCK'
GROUP BY terminatingruleid
ORDER BY hits DESC
LIMIT 10
```

**Configuração:**
- **Tipo:** Pie chart
- **Legend:** Values + Percent
- **Display labels:** Name and percent

---

### 📊 Dashboard 5: Métricas Gerais (Stats)

**Query 1 - Total Requests:**
```sql
SELECT COUNT(*) AS total_requests
FROM waf_data_lake.logs
WHERE $__timeFilter(from_unixtime("timestamp"/1000))
```

**Query 2 - Blocked Requests:**
```sql
SELECT COUNT(*) AS blocked
FROM waf_data_lake.logs
WHERE 
  $__timeFilter(from_unixtime("timestamp"/1000))
  AND action = 'BLOCK'
```

**Query 3 - Block Rate:**
```sql
SELECT 
  ROUND(
    100.0 * SUM(CASE WHEN action = 'BLOCK' THEN 1 ELSE 0 END) / COUNT(*),
    2
  ) AS block_rate_percent
FROM waf_data_lake.logs
WHERE $__timeFilter(from_unixtime("timestamp"/1000))
```

**Query 4 - Unique IPs:**
```sql
SELECT COUNT(DISTINCT httprequest.clientip) AS unique_ips
FROM waf_data_lake.logs
WHERE $__timeFilter(from_unixtime("timestamp"/1000))
```

**Configuração:**
- **Tipo:** Stat (para cada query)
- **Layout:** Grid com 4 painéis lado a lado
- **Color mode:** Value
- **Graph mode:** None

---

### 🔥 Dashboard 6: Top IPs Bloqueados (Table)

**Query:**
```sql
SELECT
  httprequest.clientip AS ip,
  httprequest.country AS country,
  COUNT(*) AS total_blocks,
  array_join(array_agg(DISTINCT terminatingruleid), ', ') AS triggered_rules
FROM waf_data_lake.logs
WHERE 
  $__timeFilter(from_unixtime("timestamp"/1000))
  AND action = 'BLOCK'
GROUP BY 
  httprequest.clientip,
  httprequest.country
ORDER BY total_blocks DESC
LIMIT 20
```

**Configuração:**
- **Tipo:** Table
- **Override:**
  - `ip`: Link → `https://ipinfo.io/${__value.raw}`

---

### 📉 Dashboard 7: Métodos HTTP (Donut Chart)

**Query:**
```sql
SELECT
  httprequest.httpmethod AS method,
  COUNT(*) AS requests
FROM waf_data_lake.logs
WHERE $__timeFilter(from_unixtime("timestamp"/1000))
GROUP BY httprequest.httpmethod
ORDER BY requests DESC
```

**Configuração:**
- **Tipo:** Pie chart (Donut)
- **Display labels:** Percent

---

## 🎨 5. JSON dos Dashboards Completos

Os dashboards prontos estão disponíveis no diretório [grafana/](grafana/):

- **[waf-logs-explorer.json](grafana/waf-logs-explorer.json)** - Dashboard de exploração de logs com filtros
- **[waf-overview.json](grafana/waf-overview.json)** - Dashboard executivo com visão geral

Para importar diretamente no Grafana:

Para importar diretamente no Grafana:

1. No Grafana, vá em **Dashboards** → **Import**
2. Clique em **Upload JSON file**
3. Selecione um dos arquivos do diretório [grafana/](grafana/)
4. Escolha o data source **WAF Data Lake**
5. Clique em **Import**

Ou via linha de comando:

```bash
# Importar WAF Logs Explorer
curl -X POST http://localhost:3000/api/dashboards/db \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer YOUR_API_KEY" \
  -d @grafana/waf-logs-explorer.json

# Importar WAF Security Overview
curl -X POST http://localhost:3000/api/dashboards/db \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer YOUR_API_KEY" \
  -d @grafana/waf-overview.json
```

### Dashboards Inclusos:

#### 📋 waf-logs-explorer.json
```json
{
  "dashboard": {
    "title": "WAF Logs Explorer",
    "uid": "waf-logs-explorer",
    "tags": ["waf", "security"],
    "timezone": "America/Sao_Paulo",
    "panels": [
      {
        "id": 1,
        "title": "WAF Logs Table",
        "type": "table",
        "gridPos": {"x": 0, "y": 0, "w": 24, "h": 12},
        "targets": [
          {
            "datasource": "WAF Data Lake",
            "rawSQL": "SELECT from_unixtime(\"timestamp\"/1000) AS event_time, action, httprequest.clientip AS client_ip, httprequest.country AS country, httprequest.httpmethod AS method, httprequest.host AS origin, httprequest.uri AS uri, terminatingruleid, terminatingruletype, httprequest.requestid AS request_id FROM waf_data_lake.logs WHERE $__timeFilter(from_unixtime(\"timestamp\"/1000)) AND ('${ip:raw}' = '' OR httprequest.clientip = '${ip:raw}') AND ('${uri:raw}' = '' OR httprequest.uri LIKE '%${uri:raw}%') AND ('${rule:raw}' = '' OR terminatingruleid = '${rule:raw}') AND ('${action:raw}' = '' OR action = '${action:raw}') AND ('${country:raw}' = '' OR httprequest.country = '${country:raw}') AND ('${method:raw}' = '' OR httprequest.httpmethod = '${method:raw}') AND ('${origin:raw}' = '' OR httprequest.host = '${origin:raw}') ORDER BY event_time DESC LIMIT ${row_limit:raw}"
          }
        ]
      }
    ],
    "templating": {
      "list": [
        {"name": "ip", "type": "textbox", "current": {"value": ""}},
        {"name": "uri", "type": "textbox", "current": {"value": ""}},
        {"name": "rule", "type": "textbox", "current": {"value": ""}},
        {"name": "action", "type": "custom", "options": [{"text": "All", "value": ""}, {"text": "ALLOW", "value": "ALLOW"}, {"text": "BLOCK", "value": "BLOCK"}, {"text": "COUNT", "value": "COUNT"}]},
        {"name": "country", "type": "textbox", "current": {"value": ""}},
        {"name": "method", "type": "custom", "options": [{"text": "All", "value": ""}, {"text": "GET", "value": "GET"}, {"text": "POST", "value": "POST"}, {"text": "PUT", "value": "PUT"}, {"text": "DELETE", "value": "DELETE"}]},
        {"name": "origin", "type": "textbox", "current": {"value": ""}},
        {"name": "row_limit", "type": "custom", "options": [{"text": "100", "value": "100"}, {"text": "500", "value": "500"}, {"text": "1000", "value": "1000"}, {"text": "5000", "value": "5000"}], "current": {"value": "100"}}
      ]
    },
    "time": {"from": "now-24h", "to": "now"},
    "refresh": "30s"
  }
}
```

#### 📊 waf-overview.json

Dashboard executivo com 8 painéis de visão geral de segurança.

<details>
<summary>Ver estrutura do JSON (clique para expandir)</summary>

```json
{
  "dashboard": {
    "title": "WAF Security Overview",
    "uid": "waf-overview",
    "tags": ["waf", "security", "overview"],
    "timezone": "America/Sao_Paulo",
    "panels": [
      {
        "id": 1,
        "title": "Total Requests",
        "type": "stat",
        "gridPos": {"x": 0, "y": 0, "w": 6, "h": 4},
        "targets": [{"datasource": "WAF Data Lake", "rawSQL": "SELECT COUNT(*) FROM waf_data_lake.logs WHERE $__timeFilter(from_unixtime(\"timestamp\"/1000))"}]
      },
      {
        "id": 2,
        "title": "Blocked Requests",
        "type": "stat",
        "gridPos": {"x": 6, "y": 0, "w": 6, "h": 4},
        "targets": [{"datasource": "WAF Data Lake", "rawSQL": "SELECT COUNT(*) FROM waf_data_lake.logs WHERE $__timeFilter(from_unixtime(\"timestamp\"/1000)) AND action = 'BLOCK'"}]
      },
      {
        "id": 3,
        "title": "Block Rate %",
        "type": "stat",
        "gridPos": {"x": 12, "y": 0, "w": 6, "h": 4},
        "targets": [{"datasource": "WAF Data Lake", "rawSQL": "SELECT ROUND(100.0 * SUM(CASE WHEN action = 'BLOCK' THEN 1 ELSE 0 END) / COUNT(*), 2) FROM waf_data_lake.logs WHERE $__timeFilter(from_unixtime(\"timestamp\"/1000))"}]
      },
      {
        "id": 4,
        "title": "Unique IPs",
        "type": "stat",
        "gridPos": {"x": 18, "y": 0, "w": 6, "h": 4},
        "targets": [{"datasource": "WAF Data Lake", "rawSQL": "SELECT COUNT(DISTINCT httprequest.clientip) FROM waf_data_lake.logs WHERE $__timeFilter(from_unixtime(\"timestamp\"/1000))"}]
      },
      {
        "id": 5,
        "title": "Requests by Action",
        "type": "timeseries",
        "gridPos": {"x": 0, "y": 4, "w": 12, "h": 8},
        "targets": [{"datasource": "WAF Data Lake", "rawSQL": "SELECT from_unixtime(\"timestamp\"/1000) AS time, action, COUNT(*) AS requests FROM waf_data_lake.logs WHERE $__timeFilter(from_unixtime(\"timestamp\"/1000)) GROUP BY from_unixtime(\"timestamp\"/1000), action ORDER BY time"}]
      },
      {
        "id": 6,
        "title": "Top Countries",
        "type": "barchart",
        "gridPos": {"x": 12, "y": 4, "w": 12, "h": 8},
        "targets": [{"datasource": "WAF Data Lake", "rawSQL": "SELECT httprequest.country, COUNT(*) AS requests FROM waf_data_lake.logs WHERE $__timeFilter(from_unixtime(\"timestamp\"/1000)) GROUP BY httprequest.country ORDER BY requests DESC LIMIT 10"}]
      },
      {
        "id": 7,
        "title": "Top Blocked IPs",
        "type": "table",
        "gridPos": {"x": 0, "y": 12, "w": 12, "h": 8},
        "targets": [{"datasource": "WAF Data Lake", "rawSQL": "SELECT httprequest.clientip AS ip, httprequest.country, COUNT(*) AS blocks FROM waf_data_lake.logs WHERE $__timeFilter(from_unixtime(\"timestamp\"/1000)) AND action = 'BLOCK' GROUP BY httprequest.clientip, httprequest.country ORDER BY blocks DESC LIMIT 20"}]
      },
      {
        "id": 8,
        "title": "WAF Rules Triggered",
        "type": "piechart",
        "gridPos": {"x": 12, "y": 12, "w": 12, "h": 8},
        "targets": [{"datasource": "WAF Data Lake", "rawSQL": "SELECT COALESCE(terminatingruleid, 'Default') AS rule, COUNT(*) FROM waf_data_lake.logs WHERE $__timeFilter(from_unixtime(\"timestamp\"/1000)) AND action = 'BLOCK' GROUP BY terminatingruleid ORDER BY COUNT(*) DESC LIMIT 10"}]
      }
    ],
    "time": {"from": "now-24h", "to": "now"},
    "refresh": "1m"
  }
}
```

</details>

---

## 📥 6. Importar Dashboards

### Via Grafana UI:

1. No Grafana, vá em **Dashboards** → **Import**
2. Clique em **Upload JSON file**
3. Selecione um arquivo do diretório [grafana/](grafana/):
   - `waf-logs-explorer.json` - Exploração detalhada de logs
   - `waf-overview.json` - Visão geral executiva
4. Selecione o data source **WAF Data Lake**
5. Clique em **Import**

### Via API:

```bash
# WAF Logs Explorer
curl -X POST http://localhost:3000/api/dashboards/db \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer YOUR_API_KEY" \
  -d @grafana/waf-logs-explorer.json

# WAF Security Overview
curl -X POST http://localhost:3000/api/dashboards/db \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer YOUR_API_KEY" \
  -d @grafana/waf-overview.json
```

## 🔄 7. Atualização Automática

Os dashboards são atualizados automaticamente porque:
- As views do Athena são recriadas diariamente pela Lambda
- O Grafana executa as queries em tempo real
- Configure `refresh` nos dashboards (ex: 30s, 1m, 5m)

## 📌 8. Dicas de Performance

1. **Use time range curto** para queries interativas (últimas 24h)
2. **Ative particionamento** nas queries:
   ```sql
   WHERE 
     year = '2026' 
     AND month = '01'
     AND $__timeFilter(from_unixtime("timestamp"/1000))
   ```
3. **Limite os resultados** com `LIMIT`
4. **Use variáveis** para filtros dinâmicos
5. **Configure cache** no Athena workgroup (se disponível)

## 🆘 9. Troubleshooting

### Erro: "Query timeout"
- Aumente o timeout no data source (default: 30s)
- Reduza o time range
- Otimize a query com filtros de partição

### Erro: "Access Denied"
- Verifique permissões IAM (S3, Athena, Glue)
- Confirme o workgroup e output location

### Dados não aparecem
- Verifique se há dados no período selecionado
- Teste a query diretamente no Athena Console
- Valide o timezone (America/Sao_Paulo)

---

**Documentação criada para o projeto WAF Data Lake** 🚀


# Ver Access Key ID
terraform output grafana_access_key_id

# Ver Secret Access Key (sensível, use -raw para copiar)
terraform output -raw grafana_secret_access_key

# Ver configuração completa formatada
terraform output grafana_configuration