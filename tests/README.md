# Terraform Tests

This directory contains comprehensive unit and integration tests for the Corelight AWS Sensor Terraform module.

## Test Structure

```
tests/
├── README.md                    # This file
├── unit_validation.tftest.hcl   # Variable validation tests
├── unit_resources.tftest.hcl    # Resource configuration tests
├── unit_outputs.tftest.hcl      # Output tests
├── unit_multi_az.tftest.hcl     # Multi-AZ functionality tests
├── unit_defaults.tftest.hcl     # Default values and optional parameters tests
├── integration.tftest.hcl       # Full stack integration tests
└── fixtures/
    └── mock_providers.tf        # Mock provider configurations for testing
```

## Running Tests

### Prerequisites

- Terraform >= 1.6.0 (native test framework support)
- Go Task (optional, for using Taskfile commands)

### Run All Tests

```bash
# Using terraform directly
terraform test

# Using Task (if available)
task test

# Run specific test file
terraform test -filter=tests/unit_validation.tftest.hcl
```

### Run Individual Test Suites

```bash
# Variable validation tests
terraform test -filter=unit_validation

# Resource configuration tests
terraform test -filter=unit_resources

# Output tests
terraform test -filter=unit_outputs

# Multi-AZ tests
terraform test -filter=unit_multi_az

# Default values tests
terraform test -filter=unit_defaults

# Integration tests
terraform test -filter=integration
```

### Verbose Output

```bash
# Show detailed test output
terraform test -verbose

# Show only failures
terraform test -no-color 2>&1 | grep -A 5 "FAIL"
```

## Test Coverage

### Variable Validation Tests (`unit_validation.tftest.hcl`)

Tests variable validation rules:
- VPC ID format validation
- AMI ID format validation
- Fleet URL format validation
- CPU threshold validations (range and relationship)
- License key or fleet URL requirement

**Example scenarios:**
- Valid VPC ID: `vpc-12345678` ✓
- Invalid VPC ID: `invalid-vpc` ✗
- Valid CPU thresholds: scale_in=40, scale_out=70 ✓
- Invalid CPU thresholds: scale_in=60, scale_out=50 ✗

### Resource Configuration Tests (`unit_resources.tftest.hcl`)

Tests that resources are created with correct configurations:
- Auto Scaling Group configuration
- Scaling policies (scale-out and scale-in)
- CloudWatch alarms (high CPU and low CPU)
- Lambda function configuration
- Security groups
- Load balancer (GWLB)
- Launch template
- EventBridge rules
- CloudWatch log groups
- Lifecycle hooks

**Key assertions:**
- ASG references correct CloudWatch alarm dimensions
- Scaling policies are properly linked to alarms
- Lambda has correct runtime and handler
- Security groups are in correct VPC

### Output Tests (`unit_outputs.tftest.hcl`)

Verifies all module outputs:
- ASG outputs (ARN, name)
- Scaling policy outputs
- CloudWatch alarm outputs
- Launch template output
- Load balancer outputs
- Security group outputs
- CloudWatch log group output

**Key assertions:**
- All outputs are non-empty
- ARN outputs have valid format
- Output values match expected resource attributes

### Multi-AZ Tests (`unit_multi_az.tftest.hcl`)

Tests multi-availability zone functionality:
- Single AZ deployment
- Dual AZ deployment
- Triple AZ deployment
- ASG spans all monitoring subnets
- Data sources for each subnet
- Lambda environment variables for multi-AZ

**Test scenarios:**
- 1 AZ: 1 monitoring subnet, 1 management subnet ✓
- 2 AZs: 2 monitoring subnets, 2 management subnets ✓
- 3 AZs: 3 monitoring subnets, 3 management subnets ✓

### Default Values Tests (`unit_defaults.tftest.hcl`)

Tests default values and optional parameters:
- Default ASG name: `corelight-sensor`
- Default CPU thresholds: scale_out=70, scale_in=40
- Default instance type: `c5.2xlarge`
- Default volume size: 500 GB
- Default CloudWatch retention: 3 days
- Optional KMS key (null by default)
- Optional instance profile (empty by default)
- Optional proxy settings (empty by default)
- Custom value overrides

### Integration Tests (`integration.tftest.hcl`)

End-to-end tests of the complete module:
- Full stack planning with custom values
- Multi-AZ setup integration
- Complete scaling configuration
- Lambda and lifecycle hook integration
- Security groups integration
- Load balancer complete setup
- Launch template configuration
- KMS encryption support
- Tags application
- All outputs present

## Test Patterns

### Testing Variable Validations

```hcl
run "test_invalid_vpc_id" {
  command = plan

  variables {
    vpc_id = "invalid-vpc"
    # ... other required variables
  }

  expect_failures = [
    var.vpc_id,
  ]
}
```

### Testing Resource Attributes

```hcl
run "test_asg_configuration" {
  command = plan

  assert {
    condition     = aws_autoscaling_group.sensor_asg.min_size == 1
    error_message = "ASG min_size should be 1"
  }
}
```

### Testing Resource Relationships

```hcl
run "test_alarm_references_asg" {
  command = plan

  assert {
    condition     = aws_cloudwatch_metric_alarm.sensor_asg_high_cpu_alarm.dimensions["AutoScalingGroupName"] == aws_autoscaling_group.sensor_asg.name
    error_message = "Alarm should reference actual ASG name"
  }
}
```

### Testing Outputs

```hcl
run "test_output_format" {
  command = plan

  assert {
    condition     = can(regex("^arn:aws:", output.autoscaling_group_arn))
    error_message = "Output should be valid ARN format"
  }
}
```

## Continuous Integration

These tests can be integrated into CI/CD pipelines:

```yaml
# GitHub Actions example
- name: Run Terraform Tests
  run: |
    terraform init
    terraform test -no-color
```

```yaml
# GitLab CI example
test:
  script:
    - terraform init
    - terraform test
```

## Test Development Guidelines

1. **Naming Convention**: Use descriptive test names that explain what's being tested
   - Good: `test_cpu_threshold_validation_invalid`
   - Bad: `test_1`

2. **Clear Assertions**: Each assertion should test one thing and have a clear error message
   ```hcl
   assert {
     condition     = var.asg_cpu_scale_in_threshold < var.asg_cpu_scale_out_threshold
     error_message = "Scale-in threshold must be lower than scale-out threshold to prevent scaling thrashing."
   }
   ```

3. **Test Independence**: Each test should be independent and not rely on state from other tests

4. **Variable Completeness**: Provide all required variables for each test run

5. **Edge Cases**: Test boundary conditions and error cases, not just happy paths

## Troubleshooting

### Test Failures

If tests fail, check:
1. Terraform version (>= 1.6.0 required for native testing)
2. All required variables are provided
3. Variable validation rules are correct
4. Resource dependencies are properly configured

### Common Issues

**Issue**: `Error: Invalid variable value`
**Solution**: Ensure all required variables are provided in the test run

**Issue**: `Error: Reference to undeclared resource`
**Solution**: Check that the resource exists in the module and is spelled correctly

**Issue**: `Test assertion failed`
**Solution**: Review the error message and check the actual vs. expected values

## Adding New Tests

When adding new features to the module:

1. Add validation tests for new variables in `unit_validation.tftest.hcl`
2. Add resource tests for new resources in `unit_resources.tftest.hcl`
3. Add output tests for new outputs in `unit_outputs.tftest.hcl`
4. Update integration tests in `integration.tftest.hcl`
5. Document the new tests in this README

## Test Metrics

Current test coverage:
- **Variable Validations**: 10+ test scenarios
- **Resource Configurations**: 15+ resource tests
- **Output Tests**: 13 output validations
- **Multi-AZ Tests**: 7 multi-AZ scenarios
- **Default Values**: 15+ default value tests
- **Integration Tests**: 11 comprehensive integration tests

**Total**: 70+ test assertions across 6 test files

## References

- [Terraform Testing Framework](https://developer.hashicorp.com/terraform/language/tests)
- [Writing Terraform Tests](https://developer.hashicorp.com/terraform/tutorials/configuration-language/test)
- [Terraform Test Command](https://developer.hashicorp.com/terraform/cli/commands/test)
