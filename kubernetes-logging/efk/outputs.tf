output "kibana-url" {
  value = "http://kibana.${data.google_compute_address.ip_address.address}.xip.io"
}
output "grafana-url" {
  value = "http://grafana.${data.google_compute_address.ip_address.address}.xip.io"
}
output "prometheus-url" {
  value = "http://prometheus.${data.google_compute_address.ip_address.address}.xip.io"
}