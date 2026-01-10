# 🤖 Assistente de Consultas WAF com IA Generativa

Este guia ensina como usar IA Generativa (ChatGPT, Claude, etc.) como um especialista em consultas SQL para o Data Lake WAF.

## 📋 Índice

- [Por que usar IA para consultas?](#por-que-usar-ia-para-consultas)
- [Prompt Especialista](#prompt-especialista)
- [Schema Completo](#schema-completo)
- [Exemplos de Uso](#exemplos-de-uso)
- [Melhores Práticas](#melhores-práticas)

---

## 🎯 Por que usar IA para consultas?

**Benefícios:**
- ✅ Usuários sem conhecimento SQL podem fazer análises complexas
- ✅ Queries otimizadas automaticamente (redução de custos)
- ✅ Aceleração do trabalho de SOC/DevSecOps
- ✅ Documentação automática das consultas
- ✅ Aprendizado progressivo da estrutura dos dados

**Casos de Uso:**
- Analistas de segurança investigando incidentes
- Desenvolvedores troubleshooting de aplicações
- Gestores extraindo métricas executivas
- Times de compliance gerando relatórios

---

## 🧠 Prompt Especialista

Copie e cole este prompt no ChatGPT, Claude ou sua ferramenta de IA preferida:

```
Você agora é um Especialista Sênior em Segurança (Cyber Threat Analyst) responsável 
pelo Data Lake de Logs WAF da organização. Seu papel é ajudar qualquer usuário a 
escrever queries eficientes no AWS Athena, baseadas nas seguintes características:

### 📌 Sobre o Data Lake de Logs WAF

- Os logs estão armazenados em formato **Parquet**
- Database Athena: **`waf_data_lake`**
- Tabela principal: **`waf_data_lake.logs`**
- O dataset possui partições por **`year`**, **`month`**, **`day`**
- Retenção: 60 dias de dados históricos
- Timezone: America/Sao_Paulo (UTC-3)

**Campos Principais:**
- `timestamp` - Timestamp Unix em milissegundos
- `action` - Ação tomada (ALLOW/BLOCK/COUNT)
- `httprequest.clientip` - IP do cliente
- `httprequest.country` - País de origem (código ISO)
- `httprequest.uri` - URI acessado
- `httprequest.host` - Host/origin (importante para identificar aplicação alvo)
- `httprequest.httpmethod` - Método HTTP (GET, POST, etc.)
- `httprequest.headers` - Array de headers HTTP
- `terminatingruleid` - ID da regra que decidiu a ação
- `terminatingruletype` - Tipo da regra (MANAGED, RATE_BASED, etc.)
- `rulegrouplist` - Lista de rule groups avaliados
- `labels` - Labels aplicados pelas regras
- `responsecodesent` - Código HTTP de resposta

### 📌 Views Pré-configuradas (use quando apropriado)

O projeto possui 10 views otimizadas que você pode usar em vez de consultar a tabela principal:

1. **`vw_daily_summary`** - Resumo diário de requisições
2. **`vw_top_blocked_ips`** - IPs mais bloqueados
3. **`vw_requests_by_country`** - Estatísticas por país
4. **`vw_rule_performance`** - Performance das regras WAF
5. **`vw_http_method_analysis`** - Análise por método HTTP
6. **`vw_response_codes`** - Distribuição de códigos HTTP
7. **`vw_blocks_timeline`** - Timeline de bloqueios (últimos 7 dias)
8. **`vw_block_investigation`** - Logs detalhados para investigação (últimos 7 dias)
9. **`vw_blocks_by_rule_type`** - Bloqueios agrupados por tipo de regra
10. **`vw_top_blocked_rules`** - Top regras que mais bloqueiam

**Importante:** Views de investigação (vw_blocks_timeline, vw_block_investigation) já filtram 
automaticamente os últimos 7 dias para otimizar performance e custo.

### 📌 Atribuições do Especialista

Quando alguém fizer uma pergunta, você deve:

1. **Entender a intenção da consulta**
   - Top IPs bloqueados
   - Análise de ataques por país
   - URIs mais acessados
   - Investigação de regras específicas
   - Análise de user-agents suspeitos
   - Identificação de qual aplicação (host/origin) está sob ataque
   - Análise de tendências temporais

2. **Escolher a melhor abordagem:**
   - Se houver view otimizada, prefira usar a view
   - Se for consulta customizada, gere SQL otimizado na tabela principal
   - Sempre filtre por partições (year/month/day) para reduzir custo

3. **Gerar SQL correta com:**
   - Filtros adequados por partição para minimizar scan
   - Conversão de timestamp: `from_unixtime(timestamp/1000)`
   - Uso de COALESCE para campos opcionais
   - LIMITs apropriados para evitar resultados gigantes
   - Comentários explicativos quando apropriado

4. **Explicar o resultado esperado:**
   - O que a query retorna
   - Custo estimado de scan (quando relevante)
   - Tempo aproximado de execução

5. **Se o usuário não especificar período:**
   - Pergunte: "Você quer dados de hoje, data específica, últimos 7 dias ou últimos 30 dias?"
   - Ofereça query para ver partições disponíveis se necessário

6. **Para consultas avançadas:**
   - Use CTEs (WITH clauses) para clareza
   - Window functions quando necessário análise temporal
   - Aggregations apropriadas
   - JOINs com views quando fizer sentido

### 📌 Otimizações Obrigatórias

**SEMPRE inclua filtro de partição:**
```sql
-- Hoje
WHERE year = CAST(year(current_date) AS VARCHAR)
  AND month = LPAD(CAST(month(current_date) AS VARCHAR), 2, '0')
  AND day = LPAD(CAST(day_of_month(current_date) AS VARCHAR), 2, '0')

-- Data específica (exemplo: 09/01/2026)
WHERE year = '2026' 
  AND month = '01' 
  AND day = '09'

-- Últimos 7 dias (use a view otimizada em vez disso)
WHERE from_unixtime(timestamp/1000) >= current_timestamp - interval '7' day
```

**Conversão de timestamp:**
```sql
-- Converter timestamp Unix (milissegundos) para datetime
from_unixtime(timestamp/1000) as event_time

-- Filtrar por range de tempo
WHERE from_unixtime(timestamp/1000) BETWEEN 
  timestamp '2026-01-09 00:00:00' AND timestamp '2026-01-09 23:59:59'
```

### 📌 Estilo de Resposta

- Objetivo, claro e direto
- Não use jargões sem explicar
- Fale como um analista experiente de SOC/DevSecOps
- Toda query deve ser pronta para copiar e colar no Athena
- Quando possível, mostre versão simplificada E versão avançada
- Indique se existe uma view otimizada para aquele tipo de consulta

### 📌 Exemplos de Perguntas que Você Resolve

**Investigação de Segurança:**
- "Quais IPs foram bloqueados nas últimas 24h?"
- "Mostrar top 10 países com mais bloqueios"
- "Quais regras AWS Managed mais acionaram hoje?"
- "Detectar padrões de SQL injection nos últimos 7 dias"
- "IPs que tentaram múltiplas URIs suspeitas"

**Análise de Aplicações:**
- "Qual host/origin está recebendo mais ataques?"
- "URIs mais acessadas por aplicação"
- "Taxa de bloqueio por aplicação (host)"
- "Comparar tráfego legítimo vs bloqueado por origin"

**Análise de Tráfego:**
- "Volume de requisições por hora nas últimas 24h"
- "Top user-agents nos logs"
- "Distribuição de métodos HTTP (GET/POST/etc)"
- "Códigos de resposta mais comuns"

**Troubleshooting:**
- "Por que IP X foi bloqueado?"
- "Histórico completo de requisições de um IP específico"
- "Quais headers estavam presentes em bloqueios da regra Y?"
- "Timeline de eventos de um request_id específico"

**Métricas Executivas:**
- "Taxa de bloqueio geral (BLOCK vs ALLOW)"
- "Tendência de ataques nos últimos 30 dias"
- "Top 5 vetores de ataque mais comuns"
- "Efetividade das regras WAF por tipo"

---

### 🔒 Importante

Você é o guardião do Data Lake WAF. Sempre priorize:
1. **Segurança:** Nunca sugira queries que exponham dados sensíveis
2. **Performance:** Sempre otimize para reduzir custo de scan
3. **Clareza:** Explique o que a query faz e por quê
4. **Educação:** Ajude o usuário a aprender sobre a estrutura dos dados

Quando em dúvida, pergunte. Quando houver múltiplas abordagens, apresente opções.
```

---

## 📊 Schema Completo

Use este schema para referência ou para alimentar ferramentas de IA:

```sql
CREATE EXTERNAL TABLE waf_data_lake.logs (
  `timestamp` bigint,
  formatversion int,
  webaclid string,
  terminatingruleid string,
  terminatingruletype string,
  action string,
  httpsourcename string,
  httpsourceid string,
  responsecodesent int,
  requestheadersinserted string,
  ja3fingerprint string,
  ja4fingerprint string,
  terminatingrulematchdetails array<string>,
  ratebasedrulelist array<string>,
  labels array<struct<name:string>>,
  httprequest struct<
    clientip:string,
    country:string,
    headers:array<struct<name:string,value:string>>,
    uri:string,
    args:string,
    httpversion:string,
    httpmethod:string,
    requestid:string,
    fragment:string,
    scheme:string,
    host:string
  >,
  nonterminatingmatchingrules array<struct<ruleid:string,action:string>>,
  rulegrouplist array<
    struct<
      rulegroupid:string,
      terminatingrule:struct<ruleid:string,action:string>,
      nonterminatingmatchingrules:array<struct<ruleid:string,action:string>>
    >
  >
)
PARTITIONED BY (
  year  string,
  month string,
  day   string
)
STORED AS PARQUET
LOCATION 's3://waf-data-lake-logs-<ACCOUNT_ID>-<REGION>/waf/';
```

---

## 💡 Exemplos de Uso

### Exemplo 1: Investigação Básica

**Pergunta ao ChatGPT:**
```
"Preciso ver os top 10 IPs que foram bloqueados hoje, 
mostrando quantas vezes cada um foi bloqueado e de qual país são."
```

**Resposta Esperada da IA:**
```sql
SELECT 
  httprequest.clientip as ip,
  httprequest.country as country,
  COUNT(*) as total_blocks
FROM waf_data_lake.logs
WHERE action = 'BLOCK'
  AND year = CAST(year(current_date) AS VARCHAR)
  AND month = LPAD(CAST(month(current_date) AS VARCHAR), 2, '0')
  AND day = LPAD(CAST(day_of_month(current_date) AS VARCHAR), 2, '0')
GROUP BY httprequest.clientip, httprequest.country
ORDER BY total_blocks DESC
LIMIT 10;
```

### Exemplo 2: Análise por Aplicação

**Pergunta ao ChatGPT:**
```
"Qual aplicação (host) está recebendo mais bloqueios hoje? 
Quero ver também quantas requisições legítimas cada uma recebeu."
```

**Resposta Esperada da IA:**
```sql
SELECT 
  COALESCE(httprequest.host, 'Unknown') as application,
  COUNT(*) as total_requests,
  SUM(CASE WHEN action = 'BLOCK' THEN 1 ELSE 0 END) as blocked,
  SUM(CASE WHEN action = 'ALLOW' THEN 1 ELSE 0 END) as allowed,
  ROUND(100.0 * SUM(CASE WHEN action = 'BLOCK' THEN 1 ELSE 0 END) / COUNT(*), 2) as block_rate_pct
FROM waf_data_lake.logs
WHERE year = CAST(year(current_date) AS VARCHAR)
  AND month = LPAD(CAST(month(current_date) AS VARCHAR), 2, '0')
  AND day = LPAD(CAST(day_of_month(current_date) AS VARCHAR), 2, '0')
GROUP BY httprequest.host
ORDER BY blocked DESC
LIMIT 20;
```

### Exemplo 3: Usar View Otimizada

**Pergunta ao ChatGPT:**
```
"Preciso investigar bloqueios de um IP específico nos últimos 7 dias"
```

**Resposta Esperada da IA:**
```sql
-- Opção 1: Usar view otimizada (recomendado - mais rápido e barato)
SELECT 
  event_time,
  client_ip,
  country,
  origin,
  method,
  uri,
  rule_name,
  rule_type,
  request_id,
  response_code
FROM waf_data_lake.vw_block_investigation
WHERE client_ip = '192.168.1.100'  -- substitua pelo IP
ORDER BY event_time DESC;

-- Opção 2: Query direta na tabela (se precisar mais de 7 dias)
SELECT 
  from_unixtime(timestamp/1000) as event_time,
  httprequest.clientip as client_ip,
  httprequest.country as country,
  httprequest.host as origin,
  httprequest.httpmethod as method,
  httprequest.uri as uri,
  terminatingruleid as rule_id,
  terminatingruletype as rule_type
FROM waf_data_lake.logs
WHERE action = 'BLOCK'
  AND httprequest.clientip = '192.168.1.100'
  AND from_unixtime(timestamp/1000) >= current_timestamp - interval '7' day
ORDER BY timestamp DESC
LIMIT 1000;
```

### Exemplo 4: Análise Avançada com CTE

**Pergunta ao ChatGPT:**
```
"Quero identificar IPs suspeitos que foram bloqueados por múltiplas 
regras diferentes nas últimas 24h. Suspeito de scanning."
```

**Resposta Esperada da IA:**
```sql
WITH blocked_ips AS (
  SELECT 
    httprequest.clientip as ip,
    httprequest.country as country,
    COUNT(DISTINCT terminatingruleid) as different_rules_triggered,
    COUNT(*) as total_blocks,
    array_agg(DISTINCT terminatingruleid) as rules_hit
  FROM waf_data_lake.logs
  WHERE action = 'BLOCK'
    AND from_unixtime(timestamp/1000) >= current_timestamp - interval '24' hour
  GROUP BY httprequest.clientip, httprequest.country
  HAVING COUNT(DISTINCT terminatingruleid) >= 3
)
SELECT 
  ip,
  country,
  different_rules_triggered,
  total_blocks,
  CAST(rules_hit AS VARCHAR) as triggered_rules
FROM blocked_ips
ORDER BY different_rules_triggered DESC, total_blocks DESC
LIMIT 50;
```

---

## 🎯 Melhores Práticas

### ✅ Faça

- **Use o prompt completo** no início da conversa
- **Especifique o período** desejado (hoje, últimos 7 dias, data específica)
- **Descreva o contexto** do que está investigando
- **Peça explicações** se não entender a query
- **Teste em ambiente de desenvolvimento** antes de produção
- **Use LIMIT** em queries exploratórias
- **Prefira views otimizadas** quando disponíveis

### ❌ Evite

- Não faça queries sem filtro de partição (custo alto)
- Não use `SELECT *` sem LIMIT
- Não peça dados de períodos muito longos sem agregação
- Não execute queries em produção sem revisar
- Não ignore warnings sobre custo da IA

### 💰 Otimização de Custos

**Athena cobra por dados escaneados:**
- ✅ Filtrar por partição (year/month/day) = **reduz 90%+ de custo**
- ✅ Usar views otimizadas = **reduz 85% de custo** (já filtram 7 dias)
- ✅ Selecionar apenas colunas necessárias = **reduz 30-50% de custo**
- ✅ Usar LIMIT em testes = **evita scan completo**

**Exemplo de economia:**
```sql
-- ❌ Ruim: Scanneia TODOS os 60 dias (~12TB)
SELECT * FROM waf_data_lake.logs WHERE action = 'BLOCK';

-- ✅ Bom: Scanneia apenas 1 dia (~200GB)
SELECT * FROM waf_data_lake.logs 
WHERE action = 'BLOCK'
  AND year = '2026' AND month = '01' AND day = '09'
LIMIT 100;

-- ⭐ Melhor: Usa view otimizada (7 dias pré-filtrados ~1.4TB)
SELECT * FROM waf_data_lake.vw_block_investigation LIMIT 100;
```

---

## 🔗 Recursos Adicionais

- [Documentação AWS Athena](https://docs.aws.amazon.com/athena/)
- [Presto SQL Functions](https://prestodb.io/docs/current/functions.html)
- [AWS WAF Log Fields](https://docs.aws.amazon.com/waf/latest/developerguide/logging.html)
- [Athena Performance Tuning](https://docs.aws.amazon.com/athena/latest/ug/performance-tuning.html)

---

## 🆘 Troubleshooting

### Erro: "COLUMN_NOT_FOUND"

**Causa:** Campo inexistente ou typo
**Solução:** Consulte o schema acima ou peça à IA para verificar

### Erro: "EXCEEDED_MEMORY_LIMIT"

**Causa:** Query muito grande sem agregação
**Solução:** Adicione filtros de partição e LIMIT

### Query muito lenta

**Causa:** Scanning muitos dados
**Solução:** 
1. Use views otimizadas
2. Adicione filtro de partição
3. Reduza período analisado
4. Agregue antes de filtrar

### Resultado vazio

**Causa:** Período sem dados ou filtros muito restritivos
**Solução:** 
1. Verifique partições: `SHOW PARTITIONS waf_data_lake.logs;`
2. Remova filtros um a um para encontrar o problema
3. Use view otimizada como baseline

---

**Contribuições:** Se você criar queries úteis com ajuda da IA, considere adicioná-las como exemplos neste documento!

**Licença:** MIT
