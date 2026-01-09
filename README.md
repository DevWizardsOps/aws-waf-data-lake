# AWS WAF Data Lake com Terraform

[![Terraform](https://img.shields.io/badge/Terraform-1.0+-623CE4?logo=terraform)](https://www.terraform.io/)
[![AWS](https://img.shields.io/badge/AWS-Cloud-FF9900?logo=amazonaws)](https://aws.amazon.com/)
[![License](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)
[![GitHub](https://img.shields.io/github/stars/DevWizardsOps/aws-waf-data-lake?style=social)](https://github.com/DevWizardsOps/aws-waf-data-lake)

Infraestrutura completa para coletar, armazenar e analisar logs do AWS WAF usando **S3 + Glue + Athena + Grafana**, 100% provisionada via Terraform.

**💰 Custo total: ~$450/mês** (vs $4,500 Datadog ou $2,700-4,200 CloudWatch)

**📊 Retenção: 60 dias** | **⚡ Performance: 85% redução no volume escaneado**

🔗 **Repositório**: [github.com/DevWizardsOps/aws-waf-data-lake](https://github.com/DevWizardsOps/aws-waf-data-lake)

## 📋 Arquitetura

```
┌─────────────┐
│   AWS WAF   │
└──────┬──────┘
       │ JSON Logs
       ▼
┌──────────────────┐
│ Kinesis Firehose │ ◄── Converte JSON → Parquet
└────────┬─────────┘
         │
         ▼
┌─────────────────┐      ┌──────────────┐
│   S3 Bucket     │ ◄────┤ Glue Catalog │
│  (Parquet)      │      │  (Schema)    │
└────────┬────────┘      └──────────────┘
         │
         ▼
┌─────────────────┐
│  Amazon Athena  │ ◄── Queries SQL
└─────────────────┘
```

## 🏗️ Estrutura Modular

```
waf-data-lake/
├── main.tf                      # Orquestra todos os módulos
├── variables.tf                 # Variáveis globais
├── outputs.tf                   # Outputs principais
├── providers.tf                 # Configuração AWS
├── backend.tf                   # Backend do Terraform (state)
├── terraform.tfvars.example     # Exemplo de configuração
└── modules/
    ├── storage/                 # Módulo S3
    │   ├── main.tf             # Bucket + Lifecycle
    │   ├── variables.tf
    │   └── outputs.tf
    ├── iam/                     # Módulo IAM
    │   ├── main.tf             # Roles + Policies
    │   ├── variables.tf
    │   └── outputs.tf
    ├── glue/                    # Módulo Glue
    │   ├── main.tf             # Database + Table
    │   ├── variables.tf
    │   └── outputs.tf
    ├── athena/                  # Módulo Athena
    │   ├── main.tf             # Workgroup + Views
    │   ├── variables.tf
    │   └── outputs.tf
    ├── lambda/                  # Módulo Lambda
    │   ├── main.tf             # Function + EventBridge
    │   ├── variables.tf
    │   ├── outputs.tf
    │   └── function/
    │       └── update_views.py
    └── firehose/                # Módulo Firehose
        ├── main.tf             # Delivery Stream
        ├── variables.tf
        └── outputs.tf
```

## 📦 Recursos Criados

### Nomenclatura Padronizada

Todos os recursos seguem o padrão `waf-data-lake-*`:

| Recurso | Nome | Descrição |
|---------|------|-----------|
| **S3 Bucket** | `waf-data-lake-logs-{account_id}-{region}` | Logs em Parquet particionados |
| **Kinesis Firehose** | `waf-data-lake-firehose` | Stream de conversão JSON→Parquet |
| **Glue Database** | `waf_data_lake` | Database do Data Catalog |
| **Glue Table** | `logs` | Schema dos logs WAF |
| **Athena Workgroup** | `waf-data-lake` | Workgroup customizado |
| **Athena Query Results** | `waf-data-lake-athena-results-{account_id}-{region}` | Bucket para resultados |
| **Lambda Function** | `waf-data-lake-update-views` | Função de atualização diária |
| **EventBridge Rule** | `waf-data-lake-update-views-daily` | Agendamento diário |
| **IAM Role** | `waf-data-lake-firehose-role` | Role para o Firehose |
| **IAM Policy** | `waf-data-lake-firehose-policy` | Permissões S3/Glue/CloudWatch |
| **CloudWatch Log Group** | `/aws/kinesisfirehose/waf-data-lake` | Logs do Firehose |

### Configurações

- **Particionamento S3**: `year=YYYY/month=MM/day=DD`
- **Lifecycle S3**: Apaga logs após 30 dias (configurável)
- **Buffering Firehose**: 128 MB ou 5 minutos
- **Formato**: JSON → Parquet (compressão automática)
- **Timezone**: America/Sao_Paulo
- **CloudWatch Retention**: 7 dias
- **Lambda Execution**: Diária às 2h UTC (23h Brasília)

## 🚀 Como Usar

### 1. Pré-requisitos

```bash
# Terraform >= 1.0
terraform --version

# AWS CLI configurado
aws configure list
```

### 2. Inicializar

```bash
cd aws-waf-data-lake
terraform init
```

### 3. Validar

```bash
terraform validate
```

### 4. Planejar (Dry-run)

```bash
terraform plan
```

Isso mostra o que será criado **sem aplicar** nenhuma mudança.

### 5. Aplicar

```bash
terraform apply
```

Digite `yes` para confirmar.

### 6. Ver Outputs

```bash
terraform output
terraform output data_lake_summary
```

### 7. Obter Credenciais do Grafana

Após o `terraform apply`, obtenha as credenciais do usuário IAM para Grafana:

```bash
# Ver Access Key ID
terraform output grafana_access_key_id

# Ver Secret Access Key (use -raw para copiar facilmente)
terraform output -raw grafana_secret_access_key

# Ver configuração completa do datasource
terraform output grafana_configuration
```

**⚠️ Importante:**
- As credenciais são armazenadas no `terraform.tfstate` (arquivo sensível)
- Nunca commite o `terraform.tfstate` no Git
- Para produção, considere usar AWS Secrets Manager

## 📊 Configuração do Grafana

### Adicionar Datasource Athena

1. **Acesse:** Grafana → Configuration → Data Sources → Add data source
2. **Busque:** "Amazon Athena"
3. **Configure:**
   - **Name**: `WAF Data Lake`
   - **Authentication Provider**: `Access & secret key`
   - **Access Key ID**: (do output `grafana_access_key_id`)
   - **Secret Access Key**: (do output `grafana_secret_access_key`)
   - **Default Region**: `sa-east-1`
   - **Workgroup**: `waf-data-lake`
   - **Database**: `waf_data_lake`
   - **Output Location**: `s3://waf-data-lake-athena-results-<ACCOUNT_ID>-sa-east-1/`

4. **Teste a conexão** clicando em "Save & Test"

### Importar Dashboards

Os dashboards prontos estão em [`grafana/`](grafana/):

**Dashboards Disponíveis:**
- **waf-logs-explorer.json** - Exploração interativa de logs com filtros dinâmicos
- **waf-overview.json** - Visão executiva de segurança
- **waf-views-optimized.json** - Dashboard otimizado usando views pré-calculadas (performance superior)
- **waf-block-investigation.json** - Investigação detalhada de bloqueios com filtro por origin/host

**Recursos dos Dashboards:**
- ✅ Filtros por IP, País, Regra, Origin (Host)
- ✅ Timeline de bloqueios em tempo real
- ✅ Top IPs, países e regras bloqueadas
- ✅ Análise por método HTTP e código de resposta
- ✅ Logs detalhados com link para IPInfo
- ✅ Campo "origin" (host) para identificar qual aplicação está sob ataque

**Via Interface (UI):**
```bash
# 1. Acesse: Grafana → Dashboards → Import
# 2. Clique em "Upload JSON file"
# 3. Selecione um dos arquivos da pasta grafana/
```

**Via API (Automático):**
```bash
# WAF Logs Explorer
curl -X POST http://localhost:3000/api/dashboards/db \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer YOUR_GRAFANA_API_KEY" \
  -d @grafana/waf-logs-explorer.json

# WAF Block Investigation (Otimizado)
curl -X POST http://localhost:3000/api/dashboards/db \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer YOUR_GRAFANA_API_KEY" \
  -d @grafana/waf-views-optimized.json
```

Veja documentação completa em [`grafana.md`](grafana.md).

## 🔧 Customização

### Opção 1: Editar variables.tf

Altere os valores padrão em [variables.tf](variables.tf).

### Opção 2: Criar terraform.tfvars

```bash
cp terraform.tfvars.example terraform.tfvars
```

Edite `terraform.tfvars`:

```hcl
project_name       = "waf-data-lake"
aws_region         = "sa-east-1"
aws_profile        = "default"  # ou seu profile AWS CLI
log_retention_days = 60

tags = {
  Environment = "production"
  Team        = "Security"
}
```

## 📊 Consultar Logs com Athena

### Views Pré-configuradas

O módulo Athena cria automaticamente 10 views otimizadas para análise:

1. **vw_daily_summary** - Resumo diário de requisições
2. **vw_top_blocked_ips** - IPs mais bloqueados
3. **vw_requests_by_country** - Estatísticas por país
4. **vw_rule_performance** - Performance das regras WAF
5. **vw_http_method_analysis** - Análise por método HTTP
6. **vw_response_codes** - Distribuição de códigos HTTP
7. **vw_blocks_timeline** - Timeline de bloqueios por regra (otimizada com filtro de 7 dias)
8. **vw_block_investigation** - Logs detalhados para investigação com campo origin
9. **vw_blocks_by_rule_type** - Bloqueios agrupados por tipo de regra
10. **vw_top_blocked_rules** - Top regras que mais bloqueiam

**⚡ Otimização de Performance**: Views de investigação filtram automaticamente últimos 7 dias, reduzindo volume escaneado de ~12TB para ~1.4TB (85% de redução).

**🤖 Atualização Automática**: Uma função Lambda executa diariamente às 2h UTC (23h Brasília) para recriar todas as views com os dados mais recentes.

### Usar as Views

```sql
-- Ver resumo diário
SELECT * FROM waf_data_lake.vw_daily_summary
WHERE year = '2026' AND month = '01'
LIMIT 100;

-- Top 20 IPs bloqueados
SELECT * FROM waf_data_lake.vw_top_blocked_ips
LIMIT 20;

-- Análise por país
SELECT * FROM waf_data_lake.vw_requests_by_country
ORDER BY blocked DESC;
```

### Query básica na tabela principal

```sql
SELECT 
  FROM_UNIXTIME(timestamp/1000) as request_time,
  httprequest.clientip as client_ip,
  httprequest.country as country,
  httprequest.uri as uri,
  httprequest.httpmethod as method,
  action,
  responsecodesent
FROM waf_data_lake.logs
WHERE year = '2026'
  AND month = '01'
  AND day = '09'
LIMIT 100;
```

### Top IPs bloqueados

```sql
SELECT 
  httprequest.clientip as ip,
  httprequest.country as country,
  COUNT(*) as total_blocks
FROM waf_data_lake.logs
WHERE action = 'BLOCK'
  AND year = '2026'
  AND month = '01'
GROUP BY httprequest.clientip, httprequest.country
ORDER BY total_blocks DESC
LIMIT 20;
```

### Análise por regra

```sql
SELECT 
  terminatingruleid,
  action,
  COUNT(*) as total
FROM waf_data_lake.logs
WHERE year = '2026'
  AND month = '01'
GROUP BY terminatingruleid, action
ORDER BY total DESC;
```

## 🔄 Importar Recursos Existentes

Se você já tem recursos criados manualmente e quer gerenciá-los com Terraform:

```bash
# S3 Bucket
terraform import module.storage.aws_s3_bucket.logs waf-logs-parquet-<ACCOUNT_ID>-<REGION>

# Glue Database
terraform import module.glue.aws_glue_catalog_database.this waf_logs

# Glue Table
terraform import module.glue.aws_glue_catalog_table.waf_logs waf_logs:waf_logs_schema

# IAM Role
terraform import module.iam.aws_iam_role.firehose KinesisFirehoseServiceRole-aws-waf-logs--sa-east-1-1763344426520

# Kinesis Firehose
terraform import module.firehose.aws_kinesis_firehose_delivery_stream.this aws-waf-logs-to-s3-parquet

# CloudWatch Log Group
terraform import aws_cloudwatch_log_group.firehose /aws/kinesisfirehose/aws-waf-logs-to-s3-parquet
```

⚠️ **Nota**: Após importar, ajuste as variáveis para corresponder aos recursos existentes.

## 🗂️ Módulos

### Storage (S3)

- Bucket com nomenclatura padronizada
- Lifecycle policy configurável
- Public access bloqueado por padrão
- Tags customizáveis

**Localização**: [modules/storage/](modules/storage/)

### IAM

- Role para Firehose com assume policy
- Policy com permissões mínimas (S3, Glue, CloudWatch)
- Attachment automático

**Localização**: [modules/iam/](modules/iam/)

### Glue

- Database do Data Catalog
- Tabela com schema completo dos logs WAF
- Suporte a location customizado

**Localização**: [modules/glue/](modules/glue/)

### Athena

- Workgroup customizado com configurações
- Bucket S3 para query results com lifecycle
- 6 views pré-configuradas para análise
- Named queries para facilitar consultas

**Localização**: [modules/athena/](modules/athena/)

### Lambda

- Função Python 3.12 para atualizar views
- Execução automática diária via EventBridge
- Logs detalhados no CloudWatch
- Permissões IAM para Athena, Glue e S3

**Localização**: [modules/lambda/](modules/lambda/)

### Firehose

- Delivery stream com conversão JSON→Parquet
- Buffering configurável
- Particionamento por data
- Logging no CloudWatch

**Localização**: [modules/firehose/](modules/firehose/)

## 🔐 Backend Remoto (Opcional)

Para trabalho em equipe, configure o backend S3 em [backend.tf](backend.tf):

```hcl
terraform {
  backend "s3" {
    bucket         = "your-terraform-state-bucket"
    key            = "waf-data-lake/terraform.tfstate"
    region         = "sa-east-1"
    profile        = "default"  # ou seu profile AWS CLI
    encrypt        = true
    dynamodb_table = "terraform-state-lock"
  }
}
```

## 🧹 Limpeza

Para destruir todos os recursos:

```bash
terraform destroy
```

⚠️ **CUIDADO**: Isso apagará:
- Bucket S3 (incluindo logs)
- Firehose stream
- Glue database e table
- IAM roles e policies
- CloudWatch log groups

## 📝 Variáveis Disponíveis

| Variável | Descrição | Padrão |
|----------|-----------|--------|
| `project_name` | Nome do projeto | `waf-data-lake` |
| `aws_region` | Região AWS | `sa-east-1` |
| `aws_profile` | Profile AWS CLI | `default` |
| `account_id` | ID da conta AWS | `<ACCOUNT_ID>` |
| `log_retention_days` | Retenção logs S3 | `60` |
| `glue_database_name` | Nome database Glue | `waf_data_lake` |
| `glue_table_name` | Nome tabela Glue | `logs` |
| `cloudwatch_log_retention_days` | Retenção CloudWatch | `7` |
| `athena_query_results_retention_days` | Retenção resultados Athena | `7` |
| `lambda_schedule_expression` | Agendamento Lambda | `cron(0 2 * * ? *)` |

Veja todas em [variables.tf](variables.tf).

## 🆘 Troubleshooting

### Erro: Bucket já existe
```
Error: creating Amazon S3 Bucket (waf-data-lake-logs-...)
```
**Solução**: Use `terraform import` ou mude o nome do bucket em `variables.tf`.

### Erro: Glue table já existe
```
Error: creating Glue Catalog Table
```
**Solução**: Importe a tabela existente ou use outro nome.

### Erro: IAM role já existe
```
Error: creating IAM Role
```
**Solução**: Importe a role ou ajuste o nome em `modules/iam/main.tf`.

## 📚 Documentação

- [AWS Kinesis Firehose](https://docs.aws.amazon.com/firehose/)
- [AWS Glue Data Catalog](https://docs.aws.amazon.com/glue/)
- [Amazon Athena](https://docs.aws.amazon.com/athena/)
- [Terraform AWS Provider](https://registry.terraform.io/providers/hashicorp/aws/)

## 💡 Artigos e Documentação

- 📝 [Artigo Completo no LinkedIn](docs/ARTIGO_LINKEDIN.md) - História completa da jornada de otimização
- 📝 [Artigo Conciso](docs/ARTIGO_LINKEDIN_CONCISO.md) - Versão resumida para compartilhamento

## 🤝 Contribuindo

1. Fork o projeto
2. Crie uma branch para sua feature (`git checkout -b feature/AmazingFeature`)
3. Commit suas mudanças (`git commit -m 'Add some AmazingFeature'`)
4. Push para a branch (`git push origin feature/AmazingFeature`)
5. Abra um Pull Request

## 📄 Licença

Distribuído sob a licença MIT. Veja `LICENSE` para mais informações.

## 📞 Contato

DevWizardsOps - [@DevWizardsOps](https://github.com/DevWizardsOps)

Link do Projeto: [https://github.com/DevWizardsOps/aws-waf-data-lake](https://github.com/DevWizardsOps/aws-waf-data-lake)

---

⭐ Se este projeto foi útil, considere dar uma estrela no GitHub!
