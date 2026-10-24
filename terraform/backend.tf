terraform {
  backend "s3" {
    bucket       = "ec2-ecs-migration-tf-state-445567089145"
    key          = "dev/terraform.tfstate"
    region       = "eu-west-2"
    use_lockfile = true
    encrypt      = true
  }
}