import boto3
import os.path
from botocore.exceptions import ClientError


s3 = boto3.client('s3')
bucket_name = '${bucket_name}'


def lambda_handler(event, context):
    request = event['Records'][0]['cf']['request']
    headers = request['headers']

    host = headers['host'][0]['value']
    path = request['uri'].lstrip('/')

    key = find_key(host, path)
    if not key is None:
        request['uri'] = os.path.join('/', key)
    return request


def find_key(host, path):
    base = os.path.join(host, path)

    try:
        s3.head_object(Bucket=bucket_name, Key=base)
        return base
    except ClientError:
        pass

    max_keys = 1000
    objects = s3.list_objects_v2(Bucket=bucket_name, MaxKeys=max_keys, Prefix=host)
    if objects['KeyCount'] == 0:
        return None
    targets = [ obj['Key'] for obj in objects['Contents'] if obj['Key'].endswith('index.html') ]

    while objects['KeyCount'] == max_keys:
        last = objects['Contents'][-1]['Key']
        objects = s3.list_objects_v2(Bucket=bucket_name, MaxKeys=max_keys, Prefix=host, StartAfter=last)
        if objects['KeyCount'] == 0:
            break
        targets.extend([ obj['Key'] for obj in objects['Contents'] if obj['Key'].endswith('index.html') ])

    targets.sort(key=lambda x: len(x.split('/')), reverse=True)
    for target in targets:
        if base.startswith(os.path.dirname(target)):
            return target

    return None
