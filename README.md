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
* `${ENV_NAME}-pks-master-security-group` security group

Objects above should be created by https://github.com/pivotal-cf/terraforming-aws .

## How to use

### Create a Load Balancer (CLB)

```
pks-aws create-lb <CLUSTER_NAME> <ENV_NAME>
```

* `CLUSTER_NAME` should be same as the name you will use with `pks create-cluster <CLUSTER_NAME>`.

* `ENV_NAME` is the value you configured in `terraform.tfvars` when installing PKS.


This command creates a CLB with the name `k8s-master-<CLUSTER_NAME>`.

If you want to specify the LB name, use `pks-aws create-lb <CLUSTER_NAME> <ENV_NAME> <LB_NAME>` instead.

See also https://docs.pivotal.io/pks/1-5/aws-cluster-load-balancer.html#create

### Create tags for public subnets

```
pks-aws create-tags <CLUSTER_NAME> <ENV_NAME>
```

This commands add `kubernetes.io/cluster/service-instance_${CLUSTER_UUID}` tag to public subnets of the given environment.
Nothing happens if the subnets already have the tag.

See also https://docs.pivotal.io/pks/1-5/deploy-workloads.html#aws

### Attach a LB to master VM(s)

```
pks-aws attach-lb <CLUSTER_NAME>
```

This commands register master vms of the given cluster behind the CLB with the name `k8s-master-<CLUSTER_NAME>`.


If you want to specify the LB name, use `pks-aws attach-lb <CLUSTER_NAME> <LB_NAME>` instead.

See also https://docs.pivotal.io/pks/1-5/aws-cluster-load-balancer.html#reconfigure

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

### Re-attach a LB for each master after upgrading all clusters

```
for cluster_name in $(pks clusters --json | jq -r '.[].name'); do
 pks-aws attach-lb ${cluster_name}
done
```

## Author

Originally based on: https://github.com/ronakbanka/manage-pks