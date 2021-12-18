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
