variable "zone_name" {
  description = "Existing Cloudflare zone, i.e. the domain (e.g. example.com)."
  type        = string
}

variable "domain_name" {
  description = "Hostname the certificate is for, inside the zone (e.g. app.example.com or app-dev.example.com)."
  type        = string

  validation {
    condition     = var.domain_name == var.zone_name || endswith(var.domain_name, ".${var.zone_name}")
    error_message = "domain_name must be inside zone_name."
  }
}

variable "subject_alternative_names" {
  description = "Extra hostnames on the same certificate (all inside the zone)."
  type        = list(string)
  default     = []

  # *.x and x share one validation record name, which Cloudflare would reject
  # as a duplicate. No wildcard is needed for a single service.
  validation {
    condition     = alltrue([for name in var.subject_alternative_names : !startswith(name, "*.")])
    error_message = "Wildcard names are not supported."
  }
}

variable "tags" {
  description = "Extra tags for every AWS resource in the module."
  type        = map(string)
  default     = {}
}
