#cloud-config

write_files:
  - content: |
      sensor:
        api:
          password: ${api_password}
        license_key: ${sensor_license}
        management_interface:
          name: ${mgmt_int}
          wait: true
        monitoring_interface:
          name: ${mon_int}
          wait: true
        kubernetes:
          allow_ports:
            - protocol: tcp
              port: 80
              net: 0.0.0.0/0
            - protocol: tcp
              port: 443
              net: 0.0.0.0/0
    owner: root:root
    path: /etc/corelight/corelightctl.yaml
    permissions: '0644'

runcmd:
  - [ corelightctl, sensor, bootstrap, -v ]
  - [ corelightctl, sensor, deploy, -v ]
  - |
    echo '{"cloud_enrichment.enable": "true", "cloud_enrichment.cloud_provider": "aws", "cloud_enrichment.bucket_name": "${bucket_name}, "cloud_enrichment.bucket_region": "${bucket_region}"}' | corelightctl sensor cfg put


