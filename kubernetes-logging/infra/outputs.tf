output "IP-adress-for-nginx" {
  value = google_compute_address.ip_address.address
}