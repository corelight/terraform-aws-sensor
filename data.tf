data "aws_vpc" "provided" {
  id = var.vpc_id
}

data "aws_subnet" "monitoring_subnet" {
  id = var.monitoring_subnet_id
}

data "aws_subnet" "management_subnet" {
  id = var.management_subnet_id
}

data "aws_subnet" "fleet_subnet" {
  count = var.fleet_subnet_id == "" ? 0 : 1
  id    = var.fleet_subnet_id
}

data "cloudinit_config" "config" {
  gzip          = false
  base64_encode = true

  part {
    content_type = "text/cloud-config"
    content = templatefile("${path.module}/templates/sensor_init.tpl",
      {
        api_password   = var.sensor_api_password
        sensor_license = var.license_key
        mon_int        = "eth0"
        mgmt_int       = "eth1"
      }
    )
    filename = "sensor-build.yaml"
  }
}

data "cloudinit_config" "config_with_enrichment" {
  gzip          = false
  base64_encode = true

  part {
    content_type = "text/cloud-config"
    content = templatefile("${path.module}/templates/sensor_init_with_enrichment.tpl",
      {
        api_password   = var.sensor_api_password
        sensor_license = var.license_key
        mon_int        = "eth0"
        mgmt_int       = "eth1"
        bucket_name    = var.enrichment_bucket_name
        bucket_region  = var.enrichment_bucket_region
      }
    )
    filename = "sensor-build.yaml"
  }
}