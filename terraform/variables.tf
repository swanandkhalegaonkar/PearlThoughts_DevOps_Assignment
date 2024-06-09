variable "region" {
  default = "us-east-1"
}
variable "vpc_id" {
  description = "VPC ID"
  type        = string
  default = "vpc-feda6e83"
}
variable "subnet_ids" {
  description = "List of subnet IDs"
  type        = list(string)
  default = ["subnet-d6daf29b","subnet-5cab333a"]
}

