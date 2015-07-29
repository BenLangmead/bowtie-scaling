#!/bin/sh

#
# DON'T FORGET TO SHUT IT DOWN WHEN YOU'RE DONE
#

aws ec2 request-spot-instances \
    --spot-price "0.500" \
    --instance-count 1 \
    --type "one-time" \
    --launch-specification "{\"KeyName\":\"default\",\"ImageId\":\"ami-1ecae776\",\"InstanceType\":\"c4.8xlarge\",\"Placement\":{\"AvailabilityZone\":\"us-east-1c\"},\"NetworkInterfaces\":[{\"DeviceIndex\":0,\"SubnetId\":\"subnet-5b76c570\"}]}"

echo "Use \"aws ec2 describe-instances\" to check on your reservation"
echo "Don't forget to shut it down when you're done"

# To log in and run the experiment, I set EC2_IP to the IP of the instance, then:
#
# ssh -i $HOME/.ec2_jhu/default.pem ec2-user@$EC2_IP
# for i in 1 2 3 ; do wget ftp://ftp.ccb.jhu.edu/pub/data/bowtie2_indexes/hg19.$i.zip ; unzip hg19.$i.zip ; rm -f hg19.$i.zip ; done
# sudo yum install -y git gcc gcc-c++ emacs
# git clone https://github.com/BenLangmead/bowtie-scaling.git
# cd bowtie-scaling/thread_scaling/scripts/experiments
# git clone https://github.com/BenLangmead/bowtie2.git
# cd bowtie2
# emacs -nw ../run_all.sh
#
#   Edit top lines to say:
#
#   HG19_INDEX=$HOME/hg19
#   MAX_THREADS=36
#
# screen
# ../run_all.sh -t
# cat /proc/cpuinfo > runs/cpuinfo.txt
# numactl --show > runs/numactl_show.txt
# numactl --hardware > runs/numactl_hardware.txt
# uname -a > runs/uname.txt

# Log out and get the output files by doing the following:
# scp -i $HOME/.ec2_jhu/default.pem -r ec2-user@$EC2_IP:bowtie-scaling/thread_scaling/scripts/experiments/bowtie2/runs scale_data_c4_8xlarge
