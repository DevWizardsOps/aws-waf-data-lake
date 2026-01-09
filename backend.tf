# Uncomment and configure if you want to use remote state
# terraform {
#   backend "s3" {
#     bucket         = "your-terraform-state-bucket"
#     key            = "waf-data-lake/terraform.tfstate"
#     region         = "sa-east-1"
#     profile        = "aws-prod"
#     encrypt        = true
#     dynamodb_table = "terraform-state-lock"
#   }
# }
