# Remote state backend for app-foobar project
terraform {
  backend "s3" {
    bucket         = "frexida-terraform-state"
    key            = "projects/app-foobar/terraform.tfstate"
    region         = "ap-northeast-1"
    dynamodb_table = "terraform-lock"
    encrypt        = true
  }
}