#!/bin/sh

#
# DON'T FORGET TO SHUT IT DOWN WHEN YOU'RE DONE
#

aws ec2 request-spot-instances \
    --spot-price "0.500" \
    --instance-count 1 \
    --type "one-time" \
    --launch-specification "{\"ImageId\":\"ami-1ecae776\",\"InstanceType\":\"c4.8xlarge\",\"Placement\":{\"AvailabilityZone\":\"us-east-1c\"},\"NetworkInterfaces\":[{\"DeviceIndex\":0,\"SubnetId\":\"subnet-5b76c570\"}]}"

echo "Use \"aws ec2 describe-instances\" to check on your reservation"
echo "Don't forget to shut it down when you're done"
