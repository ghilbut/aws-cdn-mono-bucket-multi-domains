##--------------------------------------------------------------
##  provider

provider aws {
  profile = var.profile
  region  = local.region

  default_tags {
    tags = merge(
      var.default_tags,
      {
        managed_by                = "terraform"
        "terraform/module/author" = "ghilbut@gmail.com"
        "terraform/module/path"   = "terraform/module/"
        "terraform/module/repo"   = "https://github.com/ghilbut/aws-cdn-mono-bucket-multi-domains"
      },
    )
  }
}

##--------------------------------------------------------------
##  local variable

locals {
  region = "us-east-1"

  domain_names = data.template_file.domain_names.*.rendered
  route53_zone_ids = data.aws_route53_zone.main.*.id
  domain_name_to_route53_zone_id_map = zipmap(local.domain_names, local.route53_zone_ids)
}

data template_file domain_names {
  count = length(var.domain_names)

  template = "${trimsuffix(var.domain_names[count.index], ".")}."
}
