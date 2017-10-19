#!/usr/bin/env python

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

import argparse
import boto3
import json
import os
import sys

argparser = argparse.ArgumentParser(description="Notify via email or HTTP that FPGA CL build is complete")
argparser.add_argument('--email', help='Email to notify', default=os.environ.get('EMAIL', None))
argparser.add_argument('--url', help='url to notify', default=os.environ.get('SNS_NOTIFY_URL', None))
argparser.add_argument('--user', help='User performing build', default=os.environ.get('USER', 'default'))
argparser.add_argument('--project', help='Name of project built', default=None)
argparser.add_argument('--filename', help='Name of checkpoint archive', default=None)
argparser.add_argument('--timestamp', help='Timestamp of build', default=None)
argparser.add_argument('--sourcehash', help='md5sum of the RTL', default=None)
argparser.add_argument('--fpga-image-ids', help='JSON output from aws ec2 create-fpga-image', default=None)
options = argparser.parse_args()

sns = boto3.client('sns')
topic_resp = sns.create_topic(Name="FPGA_CL_BUILD_%s" % options.user)
print(topic_resp['TopicArn'])

if options.url:
    topic_resp_json = sns.create_topic(Name="FPGA_CL_BUILD_JSON")
    list_resp_json = sns.list_subscriptions_by_topic(TopicArn=topic_resp_json['TopicArn'])
    if not any(i['Endpoint'] == options.url for i in list_resp_json.get('Subscriptions')):
        print("Subscribing to the FPGA_CL_BUILD topic")
        sub_resp_json = sns.subscribe(TopicArn=topic_resp_json['TopicArn'], Protocol='http', Endpoint=options.url)
        print(sub_resp_json)

list_resp = sns.list_subscriptions_by_topic(TopicArn=topic_resp['TopicArn'])

if list_resp.get('Subscriptions'):
    print(list_resp.get('Subscriptions'))

if os.environ.get('EMAIL') is None:
    print('Please set your EMAIL environment variable to your email address.')
    sys.exit(1)

print("Using email address: %s" % os.environ.get('EMAIL'))

# subscribe if email is not in list
if not any(i['Endpoint'] == os.environ.get('EMAIL') for i in list_resp.get('Subscriptions')):
    print("Subscribing to the FPGA_CL_BUILD topic")
    sub_resp = sns.subscribe(TopicArn=topic_resp['TopicArn'], Protocol='email', Endpoint=os.environ.get('EMAIL'))
    print(sub_resp)

message_dict = { 'subject': 'Your FPGA CL build is complete.',
                 'user': options.user,
                 'email': options.email,
                 'project': options.project,
                 'filename': options.filename,
                 'timestamp': options.timestamp,
                 'sourceHash': options.sourcehash,
                 'FpgaImageId': '',
                 'FpgaImageGlobalId': '',
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
if options.url:
    print('notifying %s' % options.url);
    imageIds = json.loads(options.fpga_image_ids) if options.fpga_image_ids else None
    pub_resp = sns.publish(TopicArn=topic_resp_json['TopicArn'],
                           Message=json.dumps(message_dict),
                           Subject='Your FPGA CL build is complete.')

sys.exit(0)
