terraform {
  required_version = "~> 1.0.0"

  ## https://www.terraform.io/docs/language/settings/backends/s3.html
  backend s3 {
    region  = "ap-northeast-2"
    profile = "terraform"

    bucket  = "ghilbut-terraform-states"
    key     = "aws-cdn-mono-bucket-multi-domains/ghilbut.com/terraform.tfstate"
    encrypt = true

    dynamodb_table = "ghilbut-terraform-lock"
  }
}


##--------------------------------------------------------------
##  module

module cdn-for-preview {
  # source = "github.com/ghilbut/aws-cdn-mono-bucket-multi-domains//terraform/module?ref=v1.0"
  source = "../module"

  # aws provider
  profile      = "ghilbut"
  default_tags = {
    managed_by       = "terraform"
    owner            = "ghilbut@gmail.com"
    purpose          = "Preview CDN for multiple subdomains"
    "terraform/path" = "terraform/ghilbut.com/"
    "terraform/repo" = "https://github.com/ghilbut/aws-cdn-mono-bucket-multi-domains"
  }

  # aws resources'
  bucket_name  = "ghilbut-cdn-for-preview-virginia"
  domain_names = [
    "ghilbut.com",
    "ghilbut.net",
  ]
  fqdns        = [
    "*.c.ghilbut.com",  ## CBT(Close Beta Test) stage - main branch
    "*.s.ghilbut.com",  ## SandBox stage - develop branch
    "*.p.ghilbut.com",  ## Preview stage - feature branch
    "*.c.ghilbut.net",  ## CBT
    "*.s.ghilbut.net",  ## SandBox
    "*.p.ghilbut.net",  ## Preview
  ]
}
