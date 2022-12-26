import boto3
region = '${aws_region}'
ec2 = boto3.client('ec2', region_name=region)

def lambda_handler(event, context):
    client = boto3.client('ec2')

    looking_instances = client.describe_instances(
      Filters=[
        {
            'Name': 'tag:${tag_name}',
            'Values': [
                '${tag_value}',
            ]
        },
    ],
    )
    
    instance_ids = []    
    
    for reservation in looking_instances['Reservations']:
        for instance in reservation['Instances']:
            instance_ids.append(instance['InstanceId'])

    ec2.start_instances(InstanceIds=instance_ids)
    print('started your instances: ' + str(instance_ids))

    result = None
    response = {'result': result}
    return response