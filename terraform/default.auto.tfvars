aws_region = "us-west-1"

# VPC vars
name             = "nab-vpc"
cidr             = "10.0.0.0/16"
public_subnets   = ["10.0.4.0/24", "10.0.5.0/24"]
database_subnets = ["10.0.104.0/24", "10.0.105.0/24"]

# Autoscaling vars
launch_configuration_name_prefix   = "nab-"
launch_configuration_instance_type = "t2.micro"

asg_config = {
  name             = "nab",
  min_size         = 2,
  max_size         = 4,
  desired_capacity = 2,
  tag_key          = "Name",
  tag_value        = "NAB",
  tag_propagate    = true
}

asp_config = {
  scale_down = {
    policy_name         = "nab_scale_down",
    adjustment_type     = "ChangeInCapacity",
    scaling_adjustment  = -1,
    cooldown            = 120,
    alarm_description   = "Monitors CPU utilization for nab ASG",
    alarm_name          = "nab_scale_down",
    comparison_operator = "LessThanOrEqualToThreshold",
    namespace           = "AWS/EC2",
    metric_name         = "CPUUtilization",
    threshold           = "40",
    evaluation_periods  = "2",
    period              = "120",
    statistic           = "Average"
  },

  scale_up = {
    policy_name         = "nab_scale_up",
    adjustment_type     = "ChangeInCapacity",
    scaling_adjustment  = 1,
    cooldown            = 120,
    alarm_description   = "Monitors CPU utilization for nab ASG",
    alarm_name          = "nab_scale_up",
    comparison_operator = "GreaterThanOrEqualToThreshold",
    namespace           = "AWS/EC2",
    metric_name         = "CPUUtilization",
    threshold           = "65",
    evaluation_periods  = "2",
    period              = "120",
    statistic           = "Average"
  }
}

# Load-balancing vars
lb_config = {
  lb_name            = "nab",
  internal           = false,
  load_balancer_type = "application",

  lb_listener_port                = "80",
  lb_listener_protocol            = "HTTP",
  lb_listener_default_action_type = "forward",

  lb_target_group_name     = "nab-asg",
  lb_target_group_port     = "80",
  lb_target_group_protocol = "HTTP",
}

# Security groups vards
sg_config = {
  instances = {
    name = "nab-sg",
    ingress = {
      from_port = 80,
      to_port   = 80,
      protocol  = "tcp"
    },
    egress = {
      from_port = 0,
      to_port   = 0,
      protocol  = "-1"
    }
  },
  lb = {
    name = "nab-lb",
    ingress = {
      from_port   = 80,
      to_port     = 80,
      protocol    = "tcp",
      cidr_blocks = ["31.13.216.45/32"] # Change here the IPs from which you want to be able to access the nginx service
    },
    egress = {
      from_port   = 0,
      to_port     = 0,
      protocol    = "-1",
      cidr_blocks = ["0.0.0.0/0"]
    }
  },
  rds = {
    name = "nab-rds",
    ingress = {
      from_port = 3306,
      to_port   = 3306,
      protocol  = "tcp"
    },
    egress = {
      from_port = 3306,
      to_port   = 3306,
      protocol  = "tcp"
    },
    tags = {
      Name = "nab_rds"
    }
  }
}

# RDS vards
rds_identifier       = "nabrds"
engine               = "mysql"
engine_version       = "8.0"
family               = "mysql8.0"
major_engine_version = "8.0"
instance_class       = "db.t4g.large"

allocated_storage     = 20
max_allocated_storage = 100

db_name     = "nabsql"
db_username = "nab"
db_port     = 3306

multi_az           = true
maintenance_window = "Mon:00:00-Mon:03:00"
backup_window      = "03:00-06:00"

skip_final_snapshot = true
deletion_protection = false

db_parameters = [
  {
    name  = "character_set_client"
    value = "utf8mb4"
  },
  {
    name  = "character_set_server"
    value = "utf8mb4"
  }
]