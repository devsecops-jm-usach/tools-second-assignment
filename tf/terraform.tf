terraform {
  #required_version = ">= 1.0.0"
  required_providers {
    aws = {
      source = "hashicorp/aws"
    }


    local = {
      source  = "hashicorp/local"
      version = "~> 2.5.0"
    }

  }
}

provider "aws" {
  region  = "us-west-2"
  profile = "admin"

}