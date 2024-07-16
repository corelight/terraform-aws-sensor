import os
from enum import Enum

import boto3
import botocore
from dataclasses import dataclass
import logging


@dataclass
class EnvironmentConfig:
    subnet_id: str
    security_group_id: str


@dataclass
class Ec2LifecycleHookEvent:
    instance_id: str
    autoscaling_group_name: str
    destination: str
    lifecycle_hook_name: str
    lifecycle_action_token: str


def from_aws_event_bridge_json(event_bridge_json: dict) -> Ec2LifecycleHookEvent:
    return Ec2LifecycleHookEvent(
        instance_id=event_bridge_json['detail']['EC2InstanceId'],
        autoscaling_group_name=event_bridge_json['detail']['AutoScalingGroupName'],
        destination=event_bridge_json['detail']['Destination'],
        lifecycle_hook_name=event_bridge_json['detail']['LifecycleHookName'],
        lifecycle_action_token=event_bridge_json['detail']['LifecycleActionToken']
    )


class LifecycleActionResult(Enum):
    CONTINUE = "CONTINUE"
    ABANDON = "ABANDON"


class EnvironmentVariables(Enum):
    TARGET_SUBNET = "TARGET_SUBNET"
    TARGET_SECURITY_GROUP_ID = "TARGET_SECURITY_GROUP_ID"


class AwsClient:
    def __init__(self, ec2_client, asg_client):
        self.ec2_client = ec2_client
        self.asg_client = asg_client

    def get_instance_details(self, instance_id: str) -> dict:
        try:
            return self.ec2_client.describe_instances(InstanceIds=[instance_id])
        except botocore.exceptions.ClientError as e:
            logging.error(f"failed to fetch information on instance {instance_id}: {e}")
            raise e

    def create_interface(self, subnet_id: str, security_group_id: str) -> str:
        try:
            return self.ec2_client.create_network_interface(
                SubnetId=subnet_id,
                Groups=[security_group_id],
                TagSpecifications=[{
                    "ResourceType": "network-interface",
                    "Tags": [{
                        "Key": "CorelightManaged",
                        "Value": "true"
                    }]
                }]
            )['NetworkInterface']['NetworkInterfaceId']

        except botocore.exceptions.ClientError as e:
            logging.error(f"[{e.response['Error']['Message']}] error creating network interface with "
                          f"subnet {subnet_id} and security group {security_group_id}: {e}")
            raise e

    def attach_interface(self, interface_id: str, instance_id: str) -> dict:
        try:
            return self.ec2_client.attach_network_interface(
                NetworkInterfaceId=interface_id,
                InstanceId=instance_id,
                DeviceIndex=1
            )
        except botocore.exceptions.ClientError as e:
            logging.error(f"[{e.response['Error']['Message']}] error attaching network interface "
                          f"{interface_id} to {instance_id}: {e}")
            raise e

    def modify_attachment_to_delete_on_termination(self, attachment_id: str, network_interface_id: str):
        try:
            self.ec2_client.modify_network_interface_attribute(
                Attachment={
                    'AttachmentId': attachment_id,
                    'DeleteOnTermination': True,
                },
                NetworkInterfaceId=network_interface_id
            )
        except botocore.exceptions.ClientError as e:
            logging.error(f"[{e.response['Error']['Message']}] failed to modify network attachment on {attachment_id}: {e}")
            raise e

    def delete_interface(self, interface_id: str) -> dict:
        try:
            return self.ec2_client.delete_network_interface(NetworkInterfaceId=interface_id)
        except botocore.exceptions.ClientError as e:
            logging.error(f"[{e.response['Error']['Message']}] error attaching network interface {interface_id}: {e}")
            raise e

    def complete_lifecycle_action(
            self,
            lifecycle_hook_name: str,
            auto_scaling_group_name: str,
            instance_id: str,
            lifecycle_action_token: str,
            lifecycle_action_result: LifecycleActionResult
    ):
        try:
            self.asg_client.complete_lifecycle_action(
                LifecycleHookName=lifecycle_hook_name,
                AutoScalingGroupName=auto_scaling_group_name,
                InstanceId=instance_id,
                LifecycleActionToken=lifecycle_action_token,
                LifecycleActionResult=lifecycle_action_result.value
            )
        except botocore.exceptions.ClientError as e:
            logging.error(
                f"[{e.response['Error']['Message']}] error completing lifecycle action {lifecycle_action_result} "
                f"for instance {instance_id}: {e}")
            raise e


class LifecycleEventService:
    def __init__(self, config: EnvironmentConfig, aws_client: AwsClient):
        self.config: EnvironmentConfig = config
        self.aws_client: AwsClient = aws_client
        self.instance_data = {}

    def process_event(self, event: Ec2LifecycleHookEvent):
        network_interface_id = self.aws_client.create_interface(self.config.subnet_id, self.config.security_group_id)
        try:
            attachment_resp = self.aws_client.attach_interface(network_interface_id, event.instance_id)
            self.aws_client.modify_attachment_to_delete_on_termination(attachment_resp["AttachmentId"], network_interface_id)
        except Exception as e:
            logging.error(f"unable to attach NIC {network_interface_id}: {e}")
            logging.info(f"Deleting {network_interface_id}")
            self.aws_client.delete_interface(network_interface_id)
            raise e

    def should_process_event(self, event: Ec2LifecycleHookEvent) -> bool:
        self.instance_data = self.aws_client.get_instance_details(event.instance_id)['Reservations'][0]['Instances'][0]

        if event.destination != "AutoScalingGroup":
            logging.error(f"Destination should be 'AutoScalingGroup' and it is set to {event.destination}")
            return False

        if len(self.instance_data['NetworkInterfaces']) > 1:
            logging.error(f"instance {event.instance_id} has more than one network interface")
            return False

        return True

    def complete_lifecycle_action(self, event: Ec2LifecycleHookEvent, action: LifecycleActionResult):
        return self.aws_client.complete_lifecycle_action(
            lifecycle_hook_name=event.lifecycle_hook_name,
            auto_scaling_group_name=event.autoscaling_group_name,
            instance_id=event.instance_id,
            lifecycle_action_token=event.lifecycle_action_token,
            lifecycle_action_result=action
        )


def lambda_handler(event, context):
    logging.getLogger().setLevel(logging.INFO)
    logging.info("initiating Corelight autoscale group monitoring NIC lambda")
    config: EnvironmentConfig = parse_environment()
    ec2_client = boto3.client("ec2")
    asg_client = boto3.client("autoscaling")
    aws_client = AwsClient(ec2_client, asg_client)
    lifecycle_event_svc: LifecycleEventService = LifecycleEventService(config, aws_client)
    parsed_event: Ec2LifecycleHookEvent = from_aws_event_bridge_json(event)

    try:
        lifecycle_event_svc.process_event(parsed_event)
        lifecycle_event_svc.complete_lifecycle_action(parsed_event, LifecycleActionResult.CONTINUE)
        logging.info("Lifecycle action completed successfully")
    except Exception as e:
        logging.info(f"failed to process event: {e}")
        lifecycle_event_svc.complete_lifecycle_action(parsed_event, LifecycleActionResult.ABANDON)
        raise e


def parse_environment() -> EnvironmentConfig:
    subnet = os.getenv(EnvironmentVariables.TARGET_SUBNET.value, "")
    security_group_id = os.getenv(EnvironmentVariables.TARGET_SECURITY_GROUP_ID.value, "")

    if subnet == "":
        msg = f"environment variable ${EnvironmentVariables.TARGET_SUBNET.value} is not defined"
        logging.error(msg)
        raise Exception(msg)

    if security_group_id == "":
        msg = f"environment variable ${EnvironmentVariables.TARGET_SECURITY_GROUP_ID} is not defined"
        logging.error(msg)
        raise Exception(msg)

    return EnvironmentConfig(subnet_id=subnet, security_group_id=security_group_id)
