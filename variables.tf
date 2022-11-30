#------------------------------------------------------------------------------
# Variables
#------------------------------------------------------------------------------
variable "region" {
  description = "The AWS region."
  type        = string
  default     = "us-east-1"
}

variable "tags" {
  description = "A map of tags to add to all resources."
  type        = map(string)
  default     = {}
}
