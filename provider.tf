# provider.tf

provider "aws" {
    region = "ap-south-2" # AWS CLI 환경설정값이 우선함.

    # 기본 태그 설정: 테라폼으로 생성한 리소스들에 추가
    default_tags {
        tags = {
          Project = "MSP06-Solution-Architect"
          Owner = "st7"
          Class = "msp06"
          ManageBy = "Terraform"
        }
    }
}