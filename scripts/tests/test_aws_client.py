import boto3
import botocore.exceptions
import pytest
from botocore.stub import Stubber
from typing import Tuple
from corelight_sensor_asg_nic_manager import AwsClient, LifecycleActionResult
from . import test_data_dir
import json


@pytest.fixture
def setup_client() -> Tuple[AwsClient, Stubber, Stubber]:
    ec2_client = boto3.client('ec2')
    asg_client = boto3.client('autoscaling')
    ec2_stubber = Stubber(ec2_client)
    asg_stubber = Stubber(asg_client)
    return AwsClient(ec2_client, asg_client), ec2_stubber, asg_stubber


def test_get_instance_details_should_raise_error_on_client_failure(setup_client):
    aws_client = setup_client[0]
    ec2_stubber = setup_client[1]
    ec2_stubber.add_client_error(
        method="describe_instances",
        http_status_code=403,
        service_message="unauthorized"
    )
    ec2_stubber.activate()

    with pytest.raises(botocore.exceptions.ClientError) as e:
        aws_client.get_instance_details("my-instance-id")
        assert e.response["ResponseMetadata"]["HTTPStatusCode"] == 403
        assert e.response["Error"]["Message"] == "unauthorized"


def test_get_instance_details_should_return_instance_details(setup_client):
    aws_client = setup_client[0]
    ec2_stubber = setup_client[1]

    with open(f"{test_data_dir}/single_nic_instance_describe_response.json") as fh:
        instance_details = json.load(fh)

    ec2_stubber.add_response(method="describe_instances", service_response=instance_details)
    ec2_stubber.activate()

    resp = aws_client.get_instance_details("my-instance-id")
    assert resp == instance_details


def test_create_interface_should_raise_error_on_client_failure(setup_client):
    aws_client = setup_client[0]
    ec2_stubber = setup_client[1]
    ec2_stubber.add_client_error(
        method="create_network_interface",
        http_status_code=403,
        service_message="unauthorized"
    )
    ec2_stubber.activate()

    with pytest.raises(botocore.exceptions.ClientError) as e:
        aws_client.create_interface("foo", "bar")
        assert e.response["ResponseMetadata"]["HTTPStatusCode"] == 403
        assert e.response["Error"]["Message"] == "unauthorized"


def test_create_interface_should_return_interface_id(setup_client):
    aws_client = setup_client[0]
    ec2_stubber = setup_client[1]

    with open(f"{test_data_dir}/nic_create_response.json") as fh:
        instance_details = json.load(fh)

    ec2_stubber.add_response(method="create_network_interface", service_response=instance_details)
    ec2_stubber.activate()

    resp = aws_client.create_interface("foo", "bar")
    assert resp == "eni-1234567890abcdefg"


def test_attach_interface_should_raise_error_and_delete_interface_on_failure_on_client_error(setup_client):
    aws_client = setup_client[0]
    ec2_stubber = setup_client[1]
    ec2_stubber.add_client_error(
        method="attach_network_interface",
        http_status_code=403,
        service_message="unauthorized"
    )
    ec2_stubber.add_response(method="delete_network_interface",
                             service_response={'ResponseMetadata': {'HTTPStatusCode': 200}})
    ec2_stubber.activate()

    with pytest.raises(botocore.exceptions.ClientError) as e:
        aws_client.attach_interface("foo", "bar")
        assert e.response["ResponseMetadata"]["HTTPStatusCode"] == 403
        assert e.response["Error"]["Message"] == "unauthorized"


def test_attach_interface_should_return_aws_attachment_response(setup_client):
    aws_client = setup_client[0]
    ec2_stubber = setup_client[1]
    ec2_stubber.add_response(
        method="attach_network_interface",
        service_response={"AttachmentId": "foo", "NetworkCardIndex": 1}
    )
    ec2_stubber.activate()

    resp = aws_client.attach_interface("foo", "bar")
    assert resp["AttachmentId"] == "foo"
    assert resp["NetworkCardIndex"] == 1


def test_modify_attachment_to_delete_on_termination_should_raise_error_on_client_error(setup_client):
    aws_client = setup_client[0]
    ec2_stubber = setup_client[1]

    ec2_stubber.add_client_error(
        method="modify_network_interface_attribute",
        http_status_code=403,
        service_message="unauthorized"
    )

    ec2_stubber.activate()

    with pytest.raises(botocore.exceptions.ClientError):
        aws_client.modify_attachment_to_delete_on_termination("foo", "bar")


def test_modify_attachment_to_delete_on_termination_should_return_nothing_on_success(setup_client):
    aws_client = setup_client[0]
    ec2_stubber = setup_client[1]

    ec2_stubber.add_response(
        method="modify_network_interface_attribute",
        service_response={'ResponseMetadata': {'HTTPStatusCode': 200}}
    )

    ec2_stubber.activate()

    resp = aws_client.modify_attachment_to_delete_on_termination("foo", "bar")
    assert resp is None


def test_complete_lifecycle_action_should_raise_error_on_client_error(setup_client):
    aws_client = setup_client[0]
    asg_stubber = setup_client[2]
    asg_stubber.add_client_error(
        method="complete_lifecycle_action",
        http_status_code=403,
        service_message="unauthorized"
    )

    asg_stubber.activate()

    with pytest.raises(botocore.exceptions.ClientError) as e:
        resp = aws_client.complete_lifecycle_action(
            "foo",
            "bar",
            "baz",
            "abc123abc123abc123abc123abc123abc123abc123abc123",
            LifecycleActionResult.CONTINUE
        )
        assert e.response["ResponseMetadata"]["HTTPStatusCode"] == 403
        assert e.response["Error"]["Message"] == "unauthorized"


def test_complete_lifecycle_action_should_return_none_on_success(setup_client):
    aws_client = setup_client[0]
    asg_stubber = setup_client[2]
    asg_stubber.add_response(
        method="complete_lifecycle_action",
        service_response={}
    )

    asg_stubber.activate()

    resp = aws_client.complete_lifecycle_action(
        "foo",
        "bar",
        "baz",
        "abc123abc123abc123abc123abc123abc123abc123abc123",
        LifecycleActionResult.CONTINUE
    )

    assert resp is None
