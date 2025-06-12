
#---------------------------------------------#
# Author: Adam WezvaTechnologies
# Call/Whatsapp: +91-9739110917
#---------------------------------------------#

provider "aws" {
  region = "ap-south-1"
}

module "autoscaling" {
  source = "./autoscaling"
  name = "asg-blue"
  create_launch_template = true
  vpc_zone_identifier       = ["subnet-0ae5072dd00e989b3","subnet-0fa888aa19b5aead7","subnet-0f1fbbdd8d05de7ea"]
  load_balancers            = ["wezvatech"]
  min_size                  = 1
  max_size                  = 2
  desired_capacity          = 1
  health_check_type         = "EC2"
  health_check_grace_period = 30

  launch_template_name        = "lt-blue"
  image_id          = "ami-092830f2395ed0eb6"
  key_name          = "ninja"
  instance_type     = "t3.micro"
  security_groups   = ["sg-0829115cdf633df80"]
}

#---------------------------------------------#
# Author: Adam WezvaTechnologies
# Call/Whatsapp: +91-9739110917
#---------------------------------------------#
