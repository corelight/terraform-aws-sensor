module "sensor_config" {
  source = "github.com/corelight/terraform-config-sensor?ref=v0.3.0"

  sensor_license                   = var.license_key
  fleet_community_string           = var.community_string
  fleet_token                      = var.fleet_token
  fleet_url                        = var.fleet_url
  fleet_server_sslname             = var.fleet_server_sslname
  fleet_http_proxy                 = var.fleet_http_proxy
  fleet_https_proxy                = var.fleet_https_proxy
  fleet_no_proxy                   = var.fleet_no_proxy
  sensor_management_interface_name = "eth1"
  sensor_monitoring_interface_name = "eth0"
  base64_encode_config             = true
  sensor_health_check_http_port    = "41080"

  enrichment_enabled             = var.enrichment_bucket_name != "" && var.enrichment_bucket_region != ""
  enrichment_bucket_name         = var.enrichment_bucket_name
  enrichment_bucket_region       = var.enrichment_bucket_region
  enrichment_cloud_provider_name = "aws"
}
