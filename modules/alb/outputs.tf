output "alb_dns_name" {
  value = aws_lb.internal.dns_name
}

output "alb_zone_id" {
  value = aws_lb.internal.zone_id
}

output "app_tg_arn" {
  value = aws_lb_target_group.app_tg.arn
}