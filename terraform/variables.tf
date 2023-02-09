# General vars
variable "aws_region" {
  description = "AWS Region"
  type        = string
}

# VPC vars
variable "name" {
  description = "Name to be used on all the resources in the VPC as identifier"
  type        = string
  default     = ""
}

variable "cidr" {
  description = "(Optional) The IPv4 CIDR block for the VPC. CIDR can be explicitly set or it can be derived from IPAM using `ipv4_netmask_length` & `ipv4_ipam_pool_id`"
  type        = string
  default     = "0.0.0.0/0"
}

variable "public_subnets" {
  description = "A list of public subnets inside the VPC"
  type        = list(string)
  default     = []
}

variable "private_subnets" {
  description = "A list of private subnets inside the VPC"
  type        = list(string)
  default     = []
}

variable "database_subnets" {
  description = "A list of database subnets"
  type        = list(string)
  default     = []
}

# Autoscaling vars
variable "launch_configuration_name_prefix" {
  description = "Creates a unique name beginning with the specified prefix"
  type        = string
}

variable "launch_configuration_instance_type" {
  description = "The size of instance to launch"
  type        = string
}

variable "asg_config" {
  description = "Map of various configuration options for the autoscaling group"
  type        = map(any)
}

variable "asp_config" {
  description = "Map of various configuration options for the autoscaling policy and alarms"
  type        = map(any)
}

# Load-balancing vars
variable "lb_config" {
  description = "Map of various configuration options for the load balancer"
  type        = map(any)
}

variable "sg_config" {
  description = "Map of various configuration options for the security groups"
  type        = any
}

# DB variables
variable "rds_identifier" {
  description = "The name of the RDS instance"
  type        = string
}

variable "engine" {
  description = "The database engine to use"
  type        = string
  default     = null
}

variable "engine_version" {
  description = "The engine version to use"
  type        = string
  default     = null
}

variable "family" {
  description = "The family of the DB parameter group"
  type        = string
  default     = null
}

variable "major_engine_version" {
  description = "Specifies the major version of the engine that this option group should be associated with"
  type        = string
  default     = null
}

variable "instance_class" {
  description = "The instance type of the RDS instance"
  type        = string
  default     = null
}

variable "allocated_storage" {
  description = "The allocated storage in gigabytes"
  type        = string
  default     = null
}

variable "max_allocated_storage" {
  description = "Specifies the value for Storage Autoscaling"
  type        = number
  default     = 0
}

variable "db_name" {
  description = "The DB name to create. If omitted, no database is created initially"
  type        = string
  default     = null
}

variable "db_username" {
  description = "Username for the master DB user"
  type        = string
  default     = null
}

variable "db_port" {
  description = "The port on which the DB accepts connections"
  type        = string
  default     = null
}

variable "maintenance_window" {
  description = "The window to perform maintenance in. Syntax: 'ddd:hh24:mi-ddd:hh24:mi'. Eg: 'Mon:00:00-Mon:03:00'"
  type        = string
  default     = null
}

variable "backup_window" {
  description = "The daily time range (in UTC) during which automated backups are created if they are enabled. Example: '09:46-10:16'. Must not overlap with maintenance_window"
  type        = string
  default     = null
}

variable "multi_az" {
  description = "Specifies if the RDS instance is multi-AZ"
  type        = bool
  default     = false
}

variable "skip_final_snapshot" {
  description = "Determines whether a final DB snapshot is created before the DB instance is deleted. If true is specified, no DBSnapshot is created. If false is specified, a DB snapshot is created before the DB instance is deleted"
  type        = bool
  default     = false
}

variable "deletion_protection" {
  description = "The database can't be deleted when this value is set to true"
  type        = bool
  default     = false
}

variable "db_parameters" {
  description = "A list of DB parameters (map) to apply"
  type        = list(map(string))
  default     = []
}