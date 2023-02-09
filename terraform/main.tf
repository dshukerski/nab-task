# Get all available zones in the region
data "aws_availability_zones" "available" {
  state = "available"
}

# Get an image with a preinstalled nginx
data "aws_ami" "nginx_debian_linux" {
  most_recent = true
  owners      = ["979382823631"]

  filter {
    name   = "name"
    values = ["bitnami-nginx-*-linux-debian-11-x86_64-hvm-ebs-nami"]
  }
}

# Create a custom VPC to create all resources in
module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "2.77.0"

  name = var.name
  cidr = var.cidr

  azs                          = data.aws_availability_zones.available.names
  public_subnets               = var.public_subnets
  database_subnets             = var.database_subnets
  enable_dns_hostnames         = true
  enable_dns_support           = true
  create_database_subnet_group = true
}

# Create auto-scaling group and load balancer
resource "aws_launch_configuration" "nab_instances" {
  name_prefix     = var.launch_configuration_name_prefix
  image_id        = data.aws_ami.nginx_debian_linux.id
  instance_type   = var.launch_configuration_instance_type
  security_groups = [aws_security_group.nab_instance.id]

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_autoscaling_group" "nab_asg" {
  name                 = var.asg_config.name
  min_size             = var.asg_config.min_size
  max_size             = var.asg_config.max_size
  desired_capacity     = var.asg_config.desired_capacity
  launch_configuration = aws_launch_configuration.nab_instances.name
  vpc_zone_identifier  = module.vpc.public_subnets

  tag {
    key                 = var.asg_config.tag_key
    value               = var.asg_config.tag_value
    propagate_at_launch = var.asg_config.tag_propagate
  }
}

resource "aws_lb" "nab_lb" {
  name               = var.lb_config.lb_name
  internal           = var.lb_config.internal
  load_balancer_type = var.lb_config.load_balancer_type
  security_groups    = [aws_security_group.nab_lb.id]
  subnets            = module.vpc.public_subnets
}

resource "aws_lb_listener" "nab_lb_listener" {
  load_balancer_arn = aws_lb.nab_lb.arn
  port              = var.lb_config.lb_listener_port
  protocol          = var.lb_config.lb_listener_protocol

  default_action {
    type             = var.lb_config.lb_listener_default_action_type
    target_group_arn = aws_lb_target_group.nab_lb_tg.arn
  }
}

resource "aws_lb_target_group" "nab_lb_tg" {
  name     = var.lb_config.lb_target_group_name
  port     = var.lb_config.lb_target_group_port
  protocol = var.lb_config.lb_target_group_protocol
  vpc_id   = module.vpc.vpc_id
}


resource "aws_autoscaling_attachment" "nab_aa" {
  autoscaling_group_name = aws_autoscaling_group.nab_asg.id
  alb_target_group_arn   = aws_lb_target_group.nab_lb_tg.arn
}

resource "aws_security_group" "nab_instance" {
  name = var.sg_config.instances.name
  ingress {
    from_port       = var.sg_config.instances.ingress.from_port
    to_port         = var.sg_config.instances.ingress.to_port
    protocol        = var.sg_config.instances.ingress.protocol
    security_groups = [aws_security_group.nab_lb.id]
  }

  egress {
    from_port       = var.sg_config.instances.egress.from_port
    to_port         = var.sg_config.instances.egress.to_port
    protocol        = var.sg_config.instances.egress.protocol
    security_groups = [aws_security_group.nab_lb.id]
  }

  vpc_id = module.vpc.vpc_id
}

# Allow only NABs IP change the value in the default.auto.tfvards file
resource "aws_security_group" "nab_lb" {
  name = var.sg_config.lb.name
  ingress {
    from_port   = var.sg_config.lb.ingress.from_port
    to_port     = var.sg_config.lb.ingress.to_port
    protocol    = var.sg_config.lb.ingress.protocol
    cidr_blocks = var.sg_config.lb.ingress.cidr_blocks
  }

  egress {
    from_port   = var.sg_config.lb.egress.from_port
    to_port     = var.sg_config.lb.egress.to_port
    protocol    = var.sg_config.lb.egress.protocol
    cidr_blocks = var.sg_config.lb.egress.cidr_blocks
  }

  vpc_id = module.vpc.vpc_id
}

# Scale down if CPU utilization is <= 40%
resource "aws_autoscaling_policy" "scale_down" {
  name                   = var.asp_config.scale_down.policy_name
  autoscaling_group_name = aws_autoscaling_group.nab_asg.name
  adjustment_type        = var.asp_config.scale_down.adjustment_type
  scaling_adjustment     = var.asp_config.scale_down.scaling_adjustment
  cooldown               = var.asp_config.scale_down.cooldown
}

resource "aws_cloudwatch_metric_alarm" "scale_down" {
  alarm_description   = var.asp_config.scale_down.alarm_description
  alarm_actions       = [aws_autoscaling_policy.scale_down.arn]
  alarm_name          = var.asp_config.scale_down.alarm_name
  comparison_operator = var.asp_config.scale_down.comparison_operator
  namespace           = var.asp_config.scale_down.namespace
  metric_name         = var.asp_config.scale_down.metric_name
  threshold           = var.asp_config.scale_down.threshold
  evaluation_periods  = var.asp_config.scale_down.evaluation_periods
  period              = var.asp_config.scale_down.period
  statistic           = var.asp_config.scale_down.statistic

  dimensions = {
    AutoScalingGroupName = aws_autoscaling_group.nab_asg.name
  }
}

# Scale up if CPU utilization is >= 65%
resource "aws_autoscaling_policy" "scale_up" {
  name                   = var.asp_config.scale_up.policy_name
  autoscaling_group_name = aws_autoscaling_group.nab_asg.name
  adjustment_type        = var.asp_config.scale_up.adjustment_type
  scaling_adjustment     = var.asp_config.scale_up.scaling_adjustment
  cooldown               = var.asp_config.scale_up.cooldown
}

resource "aws_cloudwatch_metric_alarm" "scale_up" {
  alarm_description   = var.asp_config.scale_up.alarm_description
  alarm_actions       = [aws_autoscaling_policy.scale_up.arn]
  alarm_name          = var.asp_config.scale_up.alarm_name
  comparison_operator = var.asp_config.scale_up.comparison_operator
  namespace           = var.asp_config.scale_up.namespace
  metric_name         = var.asp_config.scale_up.metric_name
  threshold           = var.asp_config.scale_up.threshold
  evaluation_periods  = var.asp_config.scale_up.evaluation_periods
  period              = var.asp_config.scale_up.period
  statistic           = var.asp_config.scale_up.statistic

  dimensions = {
    AutoScalingGroupName = aws_autoscaling_group.nab_asg.name
  }
}

# Create database
module "db" {
  source = "terraform-aws-modules/rds/aws"

  identifier = var.rds_identifier

  engine               = var.engine
  engine_version       = var.engine_version
  family               = var.family
  major_engine_version = var.major_engine_version
  instance_class       = var.instance_class

  allocated_storage     = var.allocated_storage
  max_allocated_storage = var.max_allocated_storage

  db_name  = var.db_name
  username = var.db_username
  port     = var.db_port

  multi_az               = var.multi_az
  db_subnet_group_name   = module.vpc.database_subnet_group
  vpc_security_group_ids = [aws_security_group.rds.id]

  maintenance_window = var.maintenance_window
  backup_window      = var.backup_window

  skip_final_snapshot = var.skip_final_snapshot
  deletion_protection = var.deletion_protection

  parameters = var.db_parameters

}

resource "aws_security_group" "rds" {
  name   = var.sg_config.rds.name
  vpc_id = module.vpc.vpc_id

  ingress {
    from_port   = var.sg_config.rds.ingress.from_port
    to_port     = var.sg_config.rds.ingress.to_port
    protocol    = var.sg_config.rds.ingress.protocol
    cidr_blocks = module.vpc.public_subnets_cidr_blocks
  }

  egress {
    from_port   = var.sg_config.rds.egress.from_port
    to_port     = var.sg_config.rds.egress.to_port
    protocol    = var.sg_config.rds.egress.protocol
    cidr_blocks = module.vpc.public_subnets_cidr_blocks
  }

  tags = var.sg_config.rds.tags
}