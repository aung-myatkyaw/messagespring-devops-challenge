variable "name" {
  description = "Repository name (e.g. messagespring/web)."
  type        = string
}

variable "keep_image_count" {
  description = "Number of newest images kept; older ones expire. This is the rollback window."
  type        = number
  default     = 50
}

variable "force_delete" {
  description = "Allow destroying the repository while it still holds images. Only for throwaway setups."
  type        = bool
  default     = false
}

variable "tags" {
  description = "Extra tags for every resource in the module."
  type        = map(string)
  default     = {}
}
