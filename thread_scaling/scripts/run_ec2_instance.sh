#!/bin/sh

#
# DON'T FORGET TO SHUT IT DOWN WHEN YOU'RE DONE
#

aws ec2 run-instances \
    --dry-run \
    --image-id ami-1ecae776 \
    --key-name gsg-keypair \
    --instance-type c4.8xlarge \
    --placement AvailabilityZone=us-east-1c \
    --subnet-id subnet-5b76c570 \
    --count 1
