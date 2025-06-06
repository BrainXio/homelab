variable "tailnet" {
  type        = string
  description = "Tailnet name"
}

variable "tags" {
  type        = list(string)
  default     = ["client"]
  description = "list of tags"
}

