
variable "cluster_name" {
  type        = string
  description = "Specifies the name of the EKS cluster."
  default     = ""
}

variable "s3_versioning" {
  type = bool
}

variable "loki_scalable_enabled" {
  default     = false
  type        = bool
  description = "Specify whether or not to deploy the loki scalable"
}

variable "loki_scalable_config" {
  type = any
  default = {
    loki_scalable_version = "5.8.8"
    loki_scalable_values  = ""
    s3_bucket_name        = ""
    versioning_enabled    = ""
    s3_bucket_region      = ""
  }
}
