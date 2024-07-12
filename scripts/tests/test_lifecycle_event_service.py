import json
from unittest.mock import patch

import botocore.exceptions
import pytest
from . import test_data_dir

from corelight_sensor_asg_nic_manager import LifecycleEventService, EnvironmentConfig, Ec2LifecycleHookEvent, \
    from_aws_event_bridge_json, AwsClient, LifecycleActionResult

# Equivalent of the test_data `event.json`
event = Ec2LifecycleHookEvent(
    instance_id="i-1234567890abcdef0",
    autoscaling_group_name="my-asg",
    destination="AutoScalingGroup",
    lifecycle_hook_name="my-lifecycle-hook",
    lifecycle_action_token="87654321-4321-4321-4321-210987654321"
)

cfg = EnvironmentConfig("foo", "bar")
aws_client = AwsClient("foo", "bar")


def test_from_aws_event_bridge_json_should_raise_exception_if_missing_required_attributes():
    bad_event = {"foo": "bar"}

    with pytest.raises(KeyError):
        from_aws_event_bridge_json(bad_event)


def test_from_aws_event_bridge_json_should_create_an_event_object_if_payload_correct():
    with open(f"{test_data_dir}/event.json") as fh:
        event_data = json.load(fh)
        parsed_event = from_aws_event_bridge_json(event_data)
        assert parsed_event.instance_id == event.instance_id
        assert parsed_event.autoscaling_group_name == event.autoscaling_group_name
        assert parsed_event.destination == event.destination
        assert parsed_event.lifecycle_hook_name == event.lifecycle_hook_name
        assert parsed_event.lifecycle_action_token == event.lifecycle_action_token


def test_should_process_single_nic_instance_event(mocker):
    with open(f"{test_data_dir}/single_nic_instance_describe_response.json") as fh:
        instance_data = json.load(fh)
        m = mocker.patch.object(aws_client, 'get_instance_details', return_value=instance_data)
        svc = LifecycleEventService(cfg, aws_client)
        assert svc.should_process_event(event) and m.call_count == 1


def test_should_process_multiple_nics_should_return_false(mocker):
    with open(f"{test_data_dir}/multi_nic_instance_describe_response.json") as fh:
        instance_data = json.load(fh)
        m = mocker.patch.object(aws_client, 'get_instance_details', return_value=instance_data)
        svc = LifecycleEventService(cfg, aws_client)
        assert not svc.should_process_event(event) and m.call_count == 1


def test_complete_lifecycle_action_should_raise_exception_on_client_errors(mocker):
    m = mocker.patch.object(
        aws_client,
        'complete_lifecycle_action',
        side_effect=botocore.exceptions.ClientError(
            error_response={"Error": {"Code": "fubar"}},
            operation_name="complete_lifecycle")
    )
    with pytest.raises(botocore.exceptions.ClientError):
        LifecycleEventService(cfg, aws_client).complete_lifecycle_action(event, LifecycleActionResult.CONTINUE)

    assert m.call_count == 1


def test_complete_lifecycle_action_should_return_nothing_when_no_client_errors(mocker):
    m = mocker.patch.object(
        aws_client,
        'complete_lifecycle_action',
        return_value={}
    )

    LifecycleEventService(cfg, aws_client).complete_lifecycle_action(event, LifecycleActionResult.CONTINUE)
    assert m.call_count == 1


def test_process_event_should_raise_exception_on_nic_creation_client_error(mocker):
    m = mocker.patch.object(
        aws_client,
        "create_interface",
        side_effect=botocore.exceptions.ClientError(
            error_response={"Error": {"Code": "fubar"}},
            operation_name="create_network_interface")
    )

    svc = LifecycleEventService(cfg, aws_client)

    with pytest.raises(botocore.exceptions.ClientError):
        svc.process_event(event)
    assert m.call_count == 1


def test_process_event_should_raise_exception_and_delete_nic_if_attachment_fails(mocker):
    create_nic_mocker = mocker.patch.object(aws_client, "create_interface", return_value="eni-12345")
    attach_interface_mocker = mocker.patch.object(
        aws_client,
        "attach_interface",
        side_effect=botocore.exceptions.ClientError(
            error_response={"Error": {"Code": "fubar", "Message": "error"}},
            operation_name="create_network_interface")
    )

    delete_nic_mocker = mocker.patch.object(aws_client, "delete_interface", return_value=None)

    with pytest.raises(botocore.exceptions.ClientError) as e:
        LifecycleEventService(cfg, aws_client).process_event(event)
    assert create_nic_mocker.call_count == 1 and \
           attach_interface_mocker.call_count == 1 and \
           delete_nic_mocker.call_count == 1
