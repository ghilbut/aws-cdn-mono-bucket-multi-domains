################################################################
##
##  AWS Route53
##

data aws_route53_zone main {
  count = length(local.domain_names)

  name         = local.domain_names[count.index]
  private_zone = false
}

resource aws_route53_record cloudfront {
  for_each = toset(var.fqdns)

  zone_id = local.domain_name_to_route53_zone_id_map["${regex("[a-z0-9-]+\\.[a-z0-9-]+$", each.key)}."]
  name    = each.key
  type    = "A"

  alias {
    name    = aws_cloudfront_distribution.main.domain_name
    zone_id = aws_cloudfront_distribution.main.hosted_zone_id
    evaluate_target_health = true
  }
}
