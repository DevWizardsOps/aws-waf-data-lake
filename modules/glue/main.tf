resource "aws_glue_catalog_database" "this" {
  name = var.database_name

  tags = merge(
    var.tags,
    {
      Name = var.database_name
    }
  )
}

resource "aws_glue_catalog_table" "waf_logs" {
  name          = var.table_name
  database_name = aws_glue_catalog_database.this.name
  table_type    = "EXTERNAL_TABLE"

  parameters = {
    "projection.enabled"  = "true"
    "projection.year.type" = "integer"
    "projection.year.range" = "2020,2030"
    "projection.month.type" = "integer"
    "projection.month.range" = "1,12"
    "projection.month.digits" = "2"
    "projection.day.type" = "integer"
    "projection.day.range" = "1,31"
    "projection.day.digits" = "2"
    "storage.location.template" = "${var.schema_location}year=$${year}/month=$${month}/day=$${day}/"
  }

  storage_descriptor {
    location      = var.schema_location
    input_format  = "org.apache.hadoop.hive.ql.io.parquet.MapredParquetInputFormat"
    output_format = "org.apache.hadoop.hive.ql.io.parquet.MapredParquetOutputFormat"

    ser_de_info {
      serialization_library = "org.apache.hadoop.hive.ql.io.parquet.serde.ParquetHiveSerDe"
    }

    columns {
      name = "timestamp"
      type = "bigint"
    }

    columns {
      name = "formatversion"
      type = "int"
    }

    columns {
      name = "webaclid"
      type = "string"
    }

    columns {
      name = "terminatingruleid"
      type = "string"
    }

    columns {
      name = "terminatingruletype"
      type = "string"
    }

    columns {
      name = "action"
      type = "string"
    }

    columns {
      name = "httpsourcename"
      type = "string"
    }

    columns {
      name = "httpsourceid"
      type = "string"
    }

    columns {
      name = "responsecodesent"
      type = "int"
    }

    columns {
      name = "requestheadersinserted"
      type = "string"
    }

    columns {
      name = "ja3fingerprint"
      type = "string"
    }

    columns {
      name = "ja4fingerprint"
      type = "string"
    }

    columns {
      name = "terminatingrulematchdetails"
      type = "array<string>"
    }

    columns {
      name = "ratebasedrulelist"
      type = "array<string>"
    }

    columns {
      name = "labels"
      type = "array<struct<name:string>>"
    }

    columns {
      name = "httprequest"
      type = "struct<clientIp:string,country:string,headers:array<struct<name:string,value:string>>,uri:string,args:string,httpVersion:string,httpMethod:string,requestId:string,fragment:string,scheme:string,host:string>"
    }

    columns {
      name = "nonterminatingmatchingrules"
      type = "array<struct<ruleId:string,action:string>>"
    }

    columns {
      name = "rulegrouplist"
      type = "array<struct<ruleGroupId:string,terminatingRule:struct<ruleId:string,action:string>,nonTerminatingMatchingRules:array<struct<ruleId:string,action:string>>>>"
    }
  }
}
