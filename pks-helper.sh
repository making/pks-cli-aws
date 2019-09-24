#!/bin/bash
set -e

red=`tput setaf 1`
green=`tput setaf 2`
yellow=`tput setaf 3`
reset=`tput sgr0`


OPERATION=$1
CLUSTER_NAME=$2

function usage {
  echo "USAGE: $0 {create-tags <CLUSTER_NAME> <ENV_NAME> | attach-lb <CLUSTER_NAME> <LB_NAME>}"
}

if [ "${CLUSTER_NAME}" == "" ];then
  usage
  exit 1
fi

if [ "${OPERATION}" == "" ];then
  usage
  exit 1
fi

CLUSTER_UUID=$(pks cluster ${CLUSTER_NAME} --json | jq -r .uuid)
MASTERS=$(mktemp /tmp/master-$CLUSTER_UUID.XXXX)

aws ec2 describe-instances \
--filters "Name=tag:deployment,Values=service-instance_$(pks cluster ${CLUSTER_NAME} --json | jq -r .uuid)"  "Name=tag:instance_group,Values=master" "Name=instance-state-name,Values=running" \
--query "Reservations[].Instances[].[VpcId,InstanceId]" \
--output text \
> $MASTERS

CLUSTER_VPC=$(basename $(head -1 $MASTERS | cut -d' ' -f1))


function create-tags {
  ENV_NAME=$1
  if [ "${ENV_NAME}" == "" ];then
    usage
    exit 1
  fi
  echo -e "${green}Fetching public subnets from vpc $CLUSTER_VPC ${reset}"

  subnets=$(aws ec2 describe-subnets \
    --filters "Name=vpc-id,Values=$CLUSTER_VPC" "Name=tag:Name,Values=$ENV_NAME-public-subnet*" \
    --query 'Subnets[*].[SubnetId]' \
    --output text)

  for subnet in ${subnets[@]};do
    TAG_KEY="kubernetes.io/cluster/service-instance_$CLUSTER_UUID"
    echo -e "${green}Checking if Tag (${TAG_KEY}) exists in public subnet (${subnet}) for LoadBalancer type service${reset}"
    tag=$(aws ec2 describe-tags --filters "Name=resource-id,Values=${subnet}" --query 'Tags' --output json | jq -r "map(select(.Key == \"${TAG_KEY}\"))[0].Key")
    if [ "${tag}" == "null" ];then
      echo "> Not Found"
      echo -e "${green}Adding Tag (${TAG_KEY}) to public subnet (${subnet}) for LoadBalancer type service${reset}"
      aws ec2 create-tags --resources "$subnet" --tags Key="kubernetes.io/cluster/service-instance_${CLUSTER_UUID}",Value="shared"
    else
      echo "> Already Created"
    fi
  done
}

function attach-lb {
  LB_NAME=$1
  if [ "${LB_NAME}" == "" ];then
    usage
    exit 1
  fi
  lb=$(aws elb describe-load-balancers --output json | jq -r ".LoadBalancerDescriptions | map(select(.LoadBalancerName == \"${LB_NAME}\"))[0].LoadBalancerName")
  if [ "${lb}" == "null" ];then
    echo -e "${red}ELB (${LB_NAME}) does not exist. ${reset}"
    exit 1
  fi
  while read -r vpc instance;do
    echo -e "${green}Adding ${instance} to load balancer ${LB_NAME} ${reset}"
    aws elb register-instances-with-load-balancer --load-balancer-name ${LB_NAME} --instances $instance > /dev/null
  done < "$MASTERS"
}

case $OPERATION in
  create-tags)
    create-tags $3
    ;;
  attach-lb)
    attach-lb $3
    ;;
  *)
    usage
    exit 1
esac