# `pks-aws` CLI

A helper script of `pks` cli for AWS.

This script a bit reduces the pain of creating a PKS cluster on AWS.

## Prerequisite

Following CLIs are required.

* `pks` CLI and login as `pks.clusters.admin`.
* `aws` CLI and login as a user who installed PKS. `default` profile is used.
* `jq`

The PKS environment you want to manage must have

* `${ENV_NAME}-public-subnet*` subnets
* `${ENV_NAME}-pks-master-security-group` or `${ENV_NAME}-pks-api-lb-sg` security group
* `${ENV_NAME}-vms-security-group` or `${ENV_NAME}-platform-vms-sg` security group

Objects above should be created by https://github.com/pivotal-cf/terraforming-aws or https://github.com/pivotal/paving .

## How to use

### Create a Load Balancer (NLB)

```
pks-aws create-lb <CLUSTER_NAME> <ENV_NAME>
```

* `CLUSTER_NAME` should be same as the name you will use with `pks create-cluster <CLUSTER_NAME>`.

* `ENV_NAME` is the value you configured in `terraform.tfvars` when installing PKS.


This command creates a NLB with the name `pks-<CLUSTER_NAME>`.

If you want to specify the LB name, use `pks-aws create-lb <CLUSTER_NAME> <ENV_NAME> <LB_NAME>` instead.

See also https://docs.pivotal.io/pks/1-5/aws-cluster-load-balancer.html#create

### Create tags for public subnets

```
pks-aws create-tags <CLUSTER_NAME> <ENV_NAME>
```

These commands add `kubernetes.io/cluster/service-instance_${CLUSTER_UUID}` tag to public subnets and the security group of workers (`vms_security_group` or `platform-vms-sg`) of the given environment.
Nothing happens if the subnets already have the tag.

See also
* https://docs.pivotal.io/pks/1-5/deploy-workloads.html#aws (for public subnets)
* https://github.com/kubernetes/kubernetes/issues/17626#issuecomment-389824696 (for the security group of workers)

### Attach a LB to master VM(s)

```
pks-aws attach-lb <CLUSTER_NAME>
```

These commands register master vms of the given cluster behind the NLB with the name `pks-<CLUSTER_NAME>`.


If you want to specify the LB name, use `pks-aws attach-lb <CLUSTER_NAME> <LB_NAME>` instead.

See also https://docs.pivotal.io/pks/1-5/aws-cluster-load-balancer.html#reconfigure

### Delete a LB

```
pks-aws delete-lb <CLUSTER_NAME>
```

## Typical workflow

### Create a new cluster

```
ENV_NAME=my-dev
CLUSTER_NAME=cluster01

MASTER_HOSTNAME=$(pks-aws create-lb ${CLUSTER_NAME} ${ENV_NAME})
pks create-cluster ${CLUSTER_NAME} -e ${MASTER_HOSTNAME} -p small -n 1 --wait
pks-aws attach-lb ${CLUSTER_NAME}
pks-aws create-tags ${CLUSTER_NAME} ${ENV_NAME}
```

## Author

Originally based on: https://github.com/ronakbanka/manage-pks