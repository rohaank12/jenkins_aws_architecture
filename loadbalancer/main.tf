
#---------------------------------------------#
# Author: Adam WezvaTechnologies
# Call/Whatsapp: +91-9739110917
#---------------------------------------------#
provider "aws" {
  region = "ap-south-1"
}

module "elb" {
  source = "./loadbalancer"
  vpc_id = "vpc-01cb1bc7e3d81f545"
  internal        = false

  sg_public_ingress = [
    {
      description = "Allows HTTP traffic"
      port        = 80
      protocol    = "tcp"
    },
  ]

  sg_public_egress  =  [443,8080]

  subnets         = ["subnet-0213e27a9c4333d5c", "subnet-0aa98230ab963bdc8","subnet-03042d2319cd3310c"]

  listener = [
    {
      instance_port     = 8080
      instance_protocol = "http"
      lb_port           = 80
      lb_protocol       = "http"
      #ssl_certificate_id = "arn:aws:acm:eu-west-1:235367859451:certificate/6c270328-2cd5-4b2d-8dfd-ae8d0004ad31"
    },
  ]

  health_check = {
     target              = "TCP:8080"
     interval            = 30
     healthy_threshold   = 2
     unhealthy_threshold = 2
     timeout             = 5
  }
}

#---------------------------------------------#
# Author: Adam WezvaTechnologies
# Call/Whatsapp: +91-9739110917
#---------------------------------------------#

