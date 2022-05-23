#!/usr/bin/env python33

# Amazon FPGA Hardware Development Kit
#
# Copyright 2016 Amazon.com, Inc. or its affiliates. All Rights Reserved.
#
# Licensed under the Amazon Software License (the "License"). You may not use
# this file except in compliance with the License. A copy of the License is
# located at
#
#    http://aws.amazon.com/asl/
#
# or in the "license" file accompanying this file. This file is distributed on
# an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, express or
# implied. See the License for the specific language governing permissions and
# limitations under the License.

from __future__ import print_function

import argparse
import base64
import boto3
import json
import os
import sys
import requests
import hmac

argparser = argparse.ArgumentParser(description="Notify via email or HTTP that FPGA CL build is complete")
argparser.add_argument('--email', help='Email to notify', default=os.environ.get('SNS_NOTIFY_EMAIL', None))
argparser.add_argument('--sns-notify-url', help='url to notify via SNS', default=os.environ.get('SNS_NOTIFY_URL', None))
argparser.add_argument('--notify-url', help='url to notify via POST', default=os.environ.get('NOTIFY_URL', None))
argparser.add_argument('--secret-key-file', help='File containing base64 encoded secret key for signing message sent to notify_url', default=os.environ.get('NOTIFY_SECRET_KEY_FILE', None))
argparser.add_argument('--build-user', help='User performing build', default=os.environ.get('BUILD_USER', 'default'))
argparser.add_argument('--build-project', help='Name of project built', default=os.environ.get('BUILD_PROJECT', None))
argparser.add_argument('--filename', help='Name of checkpoint archive', default=None)
argparser.add_argument('--timestamp', help='Timestamp of build', default=None)
argparser.add_argument('--sourcehash', help='md5sum of the RTL', default=None)
argparser.add_argument('--fpga-image-ids', help='JSON output from aws ec2 create-fpga-image', default=None)
options = argparser.parse_args()

sns = boto3.client('sns')
topic_resp = sns.create_topic(Name="FPGA_CL_BUILD_%s" % options.build_user)
print(topic_resp['TopicArn'])

if options.sns_notify_url:
    topic_resp_json = sns.create_topic(Name="FPGA_CL_BUILD_JSON")
    list_resp_json = sns.list_subscriptions_by_topic(TopicArn=topic_resp_json['TopicArn'])
    if not any(i['Endpoint'] == options.sns_notify_url for i in list_resp_json.get('Subscriptions')):
        print("Subscribing to the FPGA_CL_BUILD topic")
        sub_resp_json = sns.subscribe(TopicArn=topic_resp_json['TopicArn'], Protocol='http', Endpoint=options.sns_notify_url)
        print(sub_resp_json)

list_resp = sns.list_subscriptions_by_topic(TopicArn=topic_resp['TopicArn'])

if list_resp.get('Subscriptions'):
    print(list_resp.get('Subscriptions'))

if options.email is None:
    print('Please set your EMAIL environment variable to your email address.')
    sys.exit(1)

print("Using email address: %s" % options.email)

# subscribe if email is not in list
if not any(i['Endpoint'] == options.email for i in list_resp.get('Subscriptions')):
    print("Subscribing to the FPGA_CL_BUILD topic")
    sub_resp = sns.subscribe(TopicArn=topic_resp['TopicArn'], Protocol='email', Endpoint=options.email)
    print(sub_resp)

message_dict = { 'subject': 'Your FPGA CL build is complete.',
                 'user': options.build_user,
                 'email': options.email,
                 'project': options.build_project,
                 'filename': options.filename,
                 'timestamp': options.timestamp,
                 'sourceHash': options.sourcehash,
                 'fpgaImageId': '',
                 'fpgaImageGlobalId': '',
}
if options.fpga_image_ids:
    fpga_image_ids = json.loads(options.fpga_image_ids)
    message_dict['fpgaImageId'] = fpga_image_ids.get('FpgaImageId', '')
    message_dict['fpgaImageGlobalId'] = fpga_image_ids.get('FpgaImageGlobalId', '')

email_message_template = '''
Your FPGA CL build is complete:
    Project: %(project)s
    Timestamp: %(timestamp)s
    FPGA Image Id: %(fpgaImageId)s 
    FPGA Image Global Id: %(fpgaImageGlobalId)s
'''

pub_resp = sns.publish(TopicArn=topic_resp['TopicArn'],
                       Message=email_message_template % message_dict,
                       Subject='Your FPGA CL build is complete.')
if options.sns_notify_url:
    print('notifying %s' % options.sns_notify_url);
    imageIds = json.loads(options.fpga_image_ids) if options.fpga_image_ids else None
    pub_resp = sns.publish(TopicArn=topic_resp_json['TopicArn'],
                           Message=json.dumps(message_dict),
                           Subject='Your FPGA CL build is complete.')

if options.notify_url:
    message = bytes(json.dumps(message_dict), 'utf8')
    signature = None
    if options.secret_key_file:
        secret_key_b64 = open(options.secret_key_file, 'r').read()
        secret_key = base64.b64decode(secret_key_b64)
        signature = hmac.new(secret_key, message).hexdigest()
    data = {'message': message, 'signature': signature }
    resp = requests.post(options.notify_url, data=data)
    print('Posting to url %s \n data %s' % (options.notify_url, data))
    print('Posted to url %s got response %s' % (options.notify_url, resp))
    print(json.dumps({'message': message.decode('utf8'), 'signature': signature }))

sys.exit(0)
