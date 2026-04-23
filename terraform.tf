# terraform.tf

terraform {
    required_providers {
      aws = {
        source = "hashicorp/aws"
        version = "~>6.0"   # 6.0~<7.0
      }
    }


    # required_providers {
    #   google = {
    #     source = "hashicorp/google"
    #     version = "~>6.0"   # 6.0~<7.0
    #   }
    # }

}