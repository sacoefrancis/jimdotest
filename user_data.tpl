#!/bin/bash

echo export STREAM_NAME="${stream_name}" >> /etc/environment
echo export STREAM_ARN="${stream_arn}" >> /etc/environment
echo export CONSUMER_NAME="${consumer_name}" >> /etc/environment
echo export BUCKET_NAME="${bucket_name}" >> /etc/environment
echo export LIMIT="${limit}" >> /etc/environment
echo export CROSS_PROFILE="${aws_profile}" >> /etc/environment

mkdir ~/.aws
touch ~/.aws/credentials
touch ~/.aws/config

cat > ~/.aws/credentials <<'AWS_CREDENTIALS'
[default]
aws_access_key_id = 
aws_secret_access_key = 
[prod]
aws_access_key_id = 
aws_secret_access_key = 
AWS_CREDENTIALS

cat > ~/.aws/config <<'AWS_CONFIG'
[default]
region = us-east-1
output = json
[prod]
region = us-east-1
output = json
AWS_CONFIG


cat > /home/ec2-user/python_consumer.py << 'CONSUMER_CODE'
import json
import os
import boto3
import time
import csv
from datetime import datetime
# from botocore.exceptions import ResourceInUseException

stream_name = os.environ.get('STREAM_NAME')
stream_arn = os.environ.get('STREAM_ARN')
# shard_id = 'shardId-000000000000'
consumer_name = os.environ.get('CONSUMER_NAME')
bucket_name = os.environ.get('BUCKET_NAME')
kinesis_client = boto3.client('kinesis')
# try:
# 	response = kinesis_client.register_stream_consumer(
# 	    StreamARN='arn:aws:kinesis:us-east-1:056740706980:stream/user_event',
# 	    ConsumerName='sample'
# 	)
# 	print(response)
# except Exception as e:
# 	print(e)

# response = kinesis_client.subscribe_to_shard(
#     ConsumerARN='arn:aws:kinesis:us-east-1:056740706980:stream/user_event/consumer/sample:1619818696',
#     ShardId='shardId-000000000000',
#     StartingPosition={
#         'Type': 'LATEST',
#         # 'SequenceNumber': 'string',
#         # 'Timestamp': datetime(2015, 1, 1)
#     }
# )

# shard_it = kinesis_client.get_shard_iterator(StreamName=stream_name, ShardId=shard_id, 
	# ShardIteratorType="LATEST")["ShardIterator"]

    
# while True:
# 	response = kinesis_client.get_records(ShardIterator=shard_it, Limit=2)
# 	shard_it = response["NextShardIterator"]
# 	if response.get('Records'):
# 		print(response)
# 	time.sleep(0.2)
# 	# print(response)


class Kinesis:

	def __init__(self, stream_arn, consumer_name, stream_name, bucket_name):
		self.session = boto3.Session(profile_name=os.environ.get('CROSS_PROFILE'))
		self.client = boto3.client('kinesis')
		self.s3_client = self.session.client('s3')
		self.stream_arn = stream_arn
		self.stream_name = stream_name
		# self.shard_id = shard_id
		self.consumer_name = consumer_name
		self.bucket_name = bucket_name
		self.stream_details = self.client.describe_stream(StreamName=self.stream_name)

	def get_kinesis_status(self):
		return self.stream_details['StreamDescription']['StreamStatus']

	def get_shard_id(self):
		return self.stream_details['StreamDescription']['Shards'][0]['ShardId']

	def get_consumer_status(self):
		response = self.client.describe_stream_consumer(
			StreamARN=self.stream_arn,
			ConsumerName=self.consumer_name,
			# ConsumerARN='string'
			)
		return response.get('ConsumerDescription', {}).get('ConsumerStatus')

	def get_consumer_arn(self):
		response = self.client.describe_stream_consumer(
			StreamARN=self.stream_arn,
			ConsumerName=self.consumer_name,
			# ConsumerARN='string'
			)
		return response.get('ConsumerDescription', {}).get('ConsumerARN')


	def register_consumer(self):
		try:
			response = self.client.register_stream_consumer(
				StreamARN=self.stream_arn,
				ConsumerName=self.consumer_name
			)
			print("register_response: ", response )
		except self.client.exceptions.ResourceInUseException as e:
			response = self.client.list_stream_consumers(StreamARN=self.stream_arn)
			for arns in response.get('Consumers'):
				if arns.get('ConsumerName') == consumer_name:
					return arns.get('ConsumerARN')
		else:
			return response.get('Consumer', {}).get('ConsumerARN')

	def subscribe_to_kinesis_shard(self, access_type='LATEST', time_stamp=datetime.now()):
		try:
			while True:
				if self.get_consumer_status() == 'ACTIVE':
					break
			response = self.client.subscribe_to_shard(
				ConsumerARN=self.get_consumer_arn(),
				ShardId=self.get_shard_id(),
				StartingPosition={
					'Type': access_type,
					# 'SequenceNumber': 'string',
					'Timestamp': time_stamp
				}
			)
		except Exception as e:
			print(e)
			raise e
		# print("subscription: ", response)

	def get_kinesis_shard_iterator(self, access_type='LATEST', time_stamp=datetime.now()):
		return self.client.get_shard_iterator(
			StreamName=self.stream_name, 
			ShardId=self.get_shard_id(), 
			ShardIteratorType=access_type,
			Timestamp=time_stamp
			)["ShardIterator"]

	def upload_to_s3(self, file_name, partition_key):
		try:
			print(file_name, partition_key, 'upload_to_s3')
			object_name = f'{partition_key}/{file_name}'
			response = self.s3_client.upload_file(f'{file_name}.csv', self.bucket_name, object_name)
		except Exception as e:
			print(e)
			return False
		else:
			print('remove files')
			os.remove(f'{file_name}.csv')
		return True

	def generate_csv(self, data, partition_key):
		data_keys = data[0].keys()
		file_name = f'{partition_key}_{int(time.time())}'
		with open(f'{file_name}.csv', 'w', newline='')  as output_file:
			dict_writer = csv.DictWriter(output_file, data_keys)
			dict_writer.writeheader()
			dict_writer.writerows(data)
		self.upload_to_s3(file_name, partition_key)

	def get_kinesis_records(self, shard_iterator, limit):
		user_event_list = []
		user_utm_list = []
		while True:
			if self.get_kinesis_status() != 'ACTIVE':
				continue
			response = self.client.get_records(ShardIterator=shard_iterator, Limit=limit)
			shard_iterator = response["NextShardIterator"]
			if response.get('Records'):
				for records in response['Records']:
					if records.get('PartitionKey') == 'user_events':
						test_data = json.loads(records['Data'].decode("utf-8"))
						user_event_list.append(test_data)
						print(len(user_event_list))
					elif records.get('PartitionKey') == 'user_utm':
						user_utm_list.append(json.loads(records['Data'].decode("utf-8")))
						print(len(user_utm_list))
			time.sleep(0.2)
			if len(user_event_list) == limit:
				self.generate_csv(user_event_list, 'user_events')
				user_event_list = []
			if len(user_utm_list) == limit:
				self.generate_csv(user_utm_list, 'user_utm')
				user_utm_list = []


if __name__ == '__main__':
	# stream_details = kinesis_client.describe_stream(StreamName=stream_name)
	# shard_id = stream_details['StreamDescription']['Shards'][0]['ShardId']
	kinesis_obj = Kinesis(stream_arn, consumer_name, stream_name, bucket_name)
	kinesis_obj.register_consumer()
	kinesis_obj.subscribe_to_kinesis_shard()
	shard_iterator = kinesis_obj.get_kinesis_shard_iterator()
	#replay stream
	# kinesis_obj.subscribe_to_kinesis_shard('AT_TIMESTAMP', '1619854490.205847')
	# shard_iterator = kinesis_obj.get_kinesis_shard_iterator('AT_TIMESTAMP', '1619854490.205847')
	kinesis_obj.get_kinesis_records(shard_iterator, int(os.environ.get('LIMIT')))
CONSUMER_CODE

cd /home/ec2-user 
python3 -m venv venv 
source venv/bin/activate
pip install boto3
python python_consumer.py &
