################################################################
##
##  AWS Certificate Manager
##

resource aws_acm_certificate main {
  domain_name = var.fqdns[0]

  subject_alternative_names = slice(var.fqdns, 1, length(var.fqdns))

  validation_method = "DNS"

  tags = {
    Name = var.bucket_name
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource aws_route53_record aws_acm_certificate {
  for_each = {
    for dvo in aws_acm_certificate.main.domain_validation_options : dvo.domain_name => {
      name   = dvo.resource_record_name
      record = dvo.resource_record_value
      type   = dvo.resource_record_type
    }
  }

  allow_overwrite = true
  name    = each.value.name
  records = [each.value.record]
  ttl     = 60
  type    = each.value.type
  zone_id = local.domain_name_to_route53_zone_id_map[regex("[a-z0-9-]+\\.[a-z0-9-]+\\.$", each.value.name)]
}
