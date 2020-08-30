 output "loadBalancerIP" {
   value = google_compute_address.ip_address.address
 }