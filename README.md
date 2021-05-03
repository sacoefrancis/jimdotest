# jimdotest

![alt text](https://github.com/sacoefrancis/jimdotest/blob/master/123.png?raw=true)

Steps:

1.Kinesis services is consumed by python program running in ec2 instance, where same producer program to runs, can see the producer and consumer program in user_data.tpl

2.consumer program will pump the data into s3 bucket by consumer.py program

3.Based on record count s3 will trigger lambda which will put record into aws redshift
