terraform {
  backend "s3" {
    bucket = "tf-state-master-worker"
    key    = "state.tfstate"
    region = "eu-central-1"
  }
}
