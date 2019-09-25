# `pks-aws` CLI

A helper script of `pks` cli for AWS.


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

### Create tags for public subnets

```
pks-aws create-tags <CLUSTER_NAME> <ENV_NAME>
```

This commands add `kubernetes.io/cluster/service-instance_${CLUSTER_UUID}` tag to public subnets of the given environment.
Nothing happens if the subnets already have the tag.

### Attach a LB to master VM(s)

```
pks-aws attach-lb <CLUSTER_NAME>
```

This commands register master vms of the given cluster behind the CLB with the name `k8s-master-<CLUSTER_NAME>`.


If you want to specify the LB name, use `pks-aws attach-lb <CLUSTER_NAME> <LB_NAME>` instead.

## Author

Originally based on: https://github.com/ronakbanka/manage-pks