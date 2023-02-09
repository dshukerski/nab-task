output "lb_endpoint" {
  value = "http://${aws_lb.nab_lb.dns_name}"
}