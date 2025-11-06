# Cross-variable validation checks
# Variable validations can only reference themselves, so cross-variable checks are done here

resource "terraform_data" "validate_license_or_fleet" {
  lifecycle {
    precondition {
      condition     = var.license_key != "" || var.fleet_url != ""
      error_message = "Either license_key must be provided or fleet_url must be configured."
    }
  }
}

resource "terraform_data" "validate_cpu_thresholds" {
  lifecycle {
    precondition {
      condition     = var.asg_cpu_scale_in_threshold < var.asg_cpu_scale_out_threshold
      error_message = "CPU scale-in threshold (${var.asg_cpu_scale_in_threshold}) must be lower than scale-out threshold (${var.asg_cpu_scale_out_threshold}) to prevent scaling thrashing."
    }
  }
}
