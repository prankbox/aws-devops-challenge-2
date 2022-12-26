"""
Author: Yevhen Skyba
E-mail: eugene.skiba@gmail.com
"""
import boto3, os

tag_filter = os.getenv('TAG_FILTER', 'startstop:true').split(':')
ec2 = boto3.resource('ec2')


def lambda_handler(event, context):
    for instance in ec2.instances.filter(Filters=[{'Name': f'tag:{tag_filter[0]}', 'Values': [tag_filter[1]]}]).all():
        if instance.state['Name'] == 'running' and event['action'] == 'stop':
            print(f'Instance: {instance.id}, action: stop, response: {ec2.instances.filter(InstanceIds=[instance.id]).stop()[0]["ResponseMetadata"]["HTTPStatusCode"]}')
        elif instance.state['Name'] == 'stopped' and event['action'] == 'start':
            print(f'Instance: {instance.id}, action: start, response: {ec2.instances.filter(InstanceIds=[instance.id]).start()[0]["ResponseMetadata"]["HTTPStatusCode"]}')
