# 🤖 Assistente de Consultas WAF com IA Generativa

Este guia ensina como usar IA Generativa (ChatGPT, Claude, etc.) como um especialista em consultas SQL para o Data Lake de Logs do AWS WAF, **alinhado ao schema real exposto no Athena**.

---

## 📋 Índice

- [🤖 Assistente de Consultas WAF com IA Generativa](#-assistente-de-consultas-waf-com-ia-generativa)
  - [📋 Índice](#-índice)
  - [🎯 Por que usar IA para consultas?](#-por-que-usar-ia-para-consultas)
    - [Benefícios](#benefícios)
    - [Casos de Uso](#casos-de-uso)
  - [🧠 Prompt Especialista](#-prompt-especialista)
  - [📌 Sobre o Data Lake de Logs WAF](#-sobre-o-data-lake-de-logs-waf)
  - [📌 Campos Principais](#-campos-principais)
  - [📌 Estratégia de Otimização](#-estratégia-de-otimização)
    - [Regra de Ouro](#regra-de-ouro)
    - [Controle Temporal Correto](#controle-temporal-correto)
  - [📊 Schema Completo](#-schema-completo)
  - [🎯 Melhores Práticas](#-melhores-práticas)
    - [Faça](#faça)
    - [Evite](#evite)
  - [🆘 Troubleshooting](#-troubleshooting)
    - [COLUMN\_NOT\_FOUND: year / month / day](#column_not_found-year--month--day)
  - [🔒 Nota Final de Segurança](#-nota-final-de-segurança)

---

## 🎯 Por que usar IA para consultas?

### Benefícios
- ✅ Usuários sem conhecimento profundo em SQL podem realizar análises complexas
- ✅ Aceleração do trabalho de SOC / DevSecOps
- ✅ Padronização de consultas investigativas
- ✅ Redução de erros humanos
- ✅ Documentação automática das investigações
- ✅ Aprendizado progressivo da estrutura dos dados

### Casos de Uso
- Analistas de segurança investigando incidentes
- Desenvolvedores realizando troubleshooting
- Gestores extraindo métricas executivas
- Times de compliance e auditoria

---

## 🧠 Prompt Especialista

Copie e cole este prompt **no início da conversa** com a IA:

```
Você agora é um Especialista Sênior em Segurança (Cyber Threat Analyst)
responsável pelo Data Lake de Logs WAF da organização.

Seu papel é ajudar usuários a escrever queries SQL corretas,
eficientes e auditáveis no AWS Athena, respeitando as
limitações reais do schema disponível.
```

---

## 📌 Sobre o Data Lake de Logs WAF

- Logs armazenados em formato **Parquet**
- Database Athena: **waf_data_lake**
- Tabela principal: **waf_data_lake.logs**
- Retenção aproximada: **60 dias**
- Timezone padrão de análise: **America/Sao_Paulo (UTC-3)**

⚠️ **IMPORTANTE**  
A tabela **não expõe colunas de partição temporal** (`year`, `month`, `day`).  
Todo controle temporal deve ser feito via o campo **timestamp**.

---

## 📌 Campos Principais

- timestamp – Unix epoch em milissegundos
- action – Ação do WAF (ALLOW, BLOCK, COUNT)
- responsecodesent – Código HTTP retornado
- httprequest.clientip – IP do cliente
- httprequest.country – País de origem
- httprequest.uri – URI acessada
- httprequest.args – Query string
- httprequest.host – Host/origin da aplicação
- httprequest.httpmethod – Método HTTP
- httprequest.headers – Headers HTTP
- terminatingruleid – Regra final
- terminatingruletype – Tipo da regra

---

## 📌 Estratégia de Otimização

### Regra de Ouro
Nunca presuma a existência de colunas `year`, `month` ou `day`.

### Controle Temporal Correto

```sql
WHERE from_unixtime(timestamp/1000) >= current_timestamp - interval '24' hour
```

```sql
WHERE from_unixtime(timestamp/1000)
  BETWEEN timestamp '2026-01-09 00:00:00'
      AND timestamp '2026-01-09 23:59:59'
```

---

## 📊 Schema Completo

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
  >
)
STORED AS PARQUET;
```

---

## 🎯 Melhores Práticas

### Faça
- Use filtros temporais explícitos
- Valide o schema antes
- Use LIMIT
- Documente investigações

### Evite
- Presumir partições
- SELECT *
- Expor dados sensíveis

---

## 🆘 Troubleshooting

### COLUMN_NOT_FOUND: year / month / day
Causa: Presunção incorreta de partições.  
Solução: Utilize exclusivamente `timestamp`.

---

## 🔒 Nota Final de Segurança

Este Data Lake é utilizado para segurança, auditoria e investigação forense.  
Dados devem ser tratados conforme LGPD.

---

Licença: MIT