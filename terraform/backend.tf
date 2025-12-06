# Remote state backend
terraform {
  backend "s3" {
    bucket         = "frexida-terraform-state"
    key            = "envs/homepage/terraform.tfstate"
    region         = "ap-northeast-1"
    dynamodb_table = "terraform-lock"
    encrypt        = true
  }
}
