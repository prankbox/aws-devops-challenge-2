import boto3
import os

region = os.environ['REGION']
tag_key = os.environ['TAG_KEY']
tag_value = os.environ['TAG_VALUE']


def get_ec2_instances() -> list():
    """
    Getting list of EC2 instances based on tag: stopstart = enabled
    :return: list of EC2 instances
    """
    ec2_list = []
    ec2_client = boto3.client('ec2', region_name=region)
    ec2_filtered = ec2_client.describe_instances(
        Filters=[
            {
                'Name': f'tag:{tag_key}',
                'Values': [
                    f'{tag_value}',
                ]
            },
        ],
    )
    for reservation in ec2_filtered['Reservations']:
        for instance in reservation['Instances']:
            ec2_list.append(instance['InstanceId'])
    print(f"Found the following EC Instances by tag: {ec2_list}")
    return ec2_list


def stop_ec2_instances():
    """
    Stopping EC2 instances based on tag: stopstart = enabled
    :return: None
    """
    instances = get_ec2_instances()
    ec2_client = boto3.client('ec2')
    ec2_client.stop_instances(
        InstanceIds=instances
    )
    print(f"The following EC2 instances are stopping now: {instances}")


def start_ec2_instances():
    """
    Starting EC2 instances based on tag: stopstart = enabled
    :return: None
    """
    instances = get_ec2_instances()
    ec2_client = boto3.client('ec2')
    ec2_client.start_instances(
        InstanceIds=instances
    )
    print(f"The following EC2 instances are starting now: {instances}")
    

def lambda_handler(event, context):
    """
    Executing appropriate function based on EventBridge scheduled payload
    :return: None
    """
    if event["action"] == "start":
        start_ec2_instances()
    if event["action"] == "stop":
        stop_ec2_instances()