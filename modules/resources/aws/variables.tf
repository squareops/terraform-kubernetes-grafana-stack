
variable "cluster_name" {
  type        = string
  description = "Specifies the name of the EKS cluster."
  default = ""
}

variable "s3_versioning" {
  type        = bool
}
