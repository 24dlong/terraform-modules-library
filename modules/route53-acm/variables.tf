variable "domain_name" {
  description = <<-EOT
    Apex domain name of an existing public Route 53 hosted zone (e.g.
    "example.com"). The zone is looked up via data source and never created
    or destroyed by this module. The ACM certificate covers this name plus
    a wildcard SAN (`*.<domain_name>`).
  EOT
  type        = string
}

variable "tags" {
  description = "Common tags merged into every resource created by this module."
  type        = map(string)
  default     = {}
}
