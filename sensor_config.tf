module "sensor_config" {
  source = "github.com/corelight/terraform-config-sensor"

  sensor_license                   = var.license_key
  fleet_community_string           = var.community_string
  sensor_management_interface_name = "eth0"
  sensor_monitoring_interface_name = "eth1"
  base64_encode_config             = true
  enrichment_enabled               = var.enrichment_bucket_name != "" && var.enrichment_bucket_region != ""
  enrichment_bucket_name           = var.enrichment_bucket_name
  enrichment_bucket_region         = var.enrichment_bucket_region
  enrichment_cloud_provider_name   = "aws"
}