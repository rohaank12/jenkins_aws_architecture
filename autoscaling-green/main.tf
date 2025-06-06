
#---------------------------------------------#
# Author: Adam WezvaTechnologies
# Call/Whatsapp: +91-9739110917
#---------------------------------------------#

provider "aws" {
  region = "ap-south-1"
}

module "autoscaling" {
  source = "./autoscaling"
  name = "asg-green"
  create_launch_template = true
  vpc_zone_identifier       = ["subnet-0213e27a9c4333d5c", "subnet-0aa98230ab963bdc8","subnet-03042d2319cd3310c"]
  load_balancers            = ["wezvatech"]
  min_size                  = 1
  max_size                  = 2
  desired_capacity          = 1
  health_check_type         = "EC2"
  health_check_grace_period = 30

  launch_template_name        = "lt-blue"
  image_id          = "ami-0836ed1f613068bd6"
  key_name          = "wezvatech2025"
  instance_type     = "t3.micro"
  security_groups   = ["sg-0fed46a4bd7b55975"]
}

#---------------------------------------------#
# Author: Adam WezvaTechnologies
# Call/Whatsapp: +91-9739110917
#---------------------------------------------#
