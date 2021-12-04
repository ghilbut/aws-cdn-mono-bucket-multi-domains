variable profile {
  type = string
}

variable default_tags {
  type = map(string)
  default = {}
}

variable bucket_name {
  type = string
}

variable domain_names {
  type = list(string)
}

variable fqdns {
  type = list(string)
}

variable cf_caches_ttl {
  type = object({ min = number, default = number, max = number })
  default = {
    min     = 0  # 0
    default = 0  # 3600
    max     = 0  # 86400
  }
}
