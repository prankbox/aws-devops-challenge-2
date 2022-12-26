import os
import boto3
from botocore.exceptions import ClientError


def handler(event, context):
    try:
        ec2 = boto3.resource('ec2')
        try:
            action = event["action"].split(': ', 1)[0]
            print(f'action: {action}')
            if action == "stop":
                state = "running"
            elif action == "start":
                state = "stopped"
            else:
                state = "unknown"
            try:
                tag = os.environ["TAG"]
                tagName = tag.split(": ")[0]
                print(f'tag: {tagName}')
                filters = [{'Name': f'tag:{tagName}', 'Values': ['true']},
                           {'Name': 'instance-state-name',  'Values': [state]}]
                try:
                    instances = ec2.instances.filter(Filters=filters)
                    instanceIds = []
                    for instance in instances:
                        instanceIds.append(instance.id)
                    print(f'Instances: {instanceIds}')
                    if instanceIds:
                        if state == "stopped":
                            response = ec2.instances.filter(Filters=[{'Name': 'instance-id', 'Values': instanceIds}]).start()
                            item = "StartingInstances"
                        elif state == "running":
                            response = ec2.instances.filter(Filters=[{'Name': 'instance-id', 'Values': instanceIds}]).stop()
                            item = "StoppingInstances"
                        else:
                            response = []
                            print(f'Discovered state is {state}. Nothing to do')
                        if response:
                            try:
                                for item in response[0][item]:
                                    print(f'{item["InstanceId"]} is {item["CurrentState"]["Name"]}')
                            except Exception as e:
                                print(f'Unable to read response: {e}')
                    else:
                        print("Instances list is empty. Nothing to do")
                except Exception as e:
                    print(f'Unable to {action} instances: {e}')
            except Exception as e:
                print(f'Unable to read tag: {e}')
        except Exception as e:
            print(f'Unable to read event: {e}')
    except ClientError as e:
        print(f'Client error: {e}')

    return {
        "statusCode": 200
    }
