variable "region" {
  type    = string
  default = "eu-central-1"
}

variable "state_bucket_name" {
  type    = string
  default = "tf-master-worker"
}

variable "ec2_spot_price" {
  type    = string
  default = "0.035"
}

variable "lfd259_username" {
  description = "LFD259 course materials username"
  type        = string
  sensitive   = true
}

variable "lfd259_password" {
  description = "LFD259 course materials password"
  type        = string
  sensitive   = true
}
