# Deploying Gateway on AWS

## [create eks cluster and policies](https://docs.aws.amazon.com/eks/latest/userguide/create-cluster.html)

## set up the aws eks load balancer helm chart

[you will need to install the ingress helm chart for eks](https://docs.aws.amazon.com/eks/latest/userguide/lbc-helm.html)



```
curl -O https://raw.githubusercontent.com/kubernetes-sigs/aws-load-balancer-controller/v2.11.0/docs/install/iam_policy.json

aws iam create-policy \
    --policy-name AWSLoadBalancerControllerIAMPolicy \
    --policy-document file://iam_policy.json

eksctl create iamserviceaccount \
  --cluster=serious-hiphop-sparrow \
  --namespace=kube-system \
  --name=aws-load-balancer-controller \
  --role-name AmazonEKSLoadBalancerControllerRole \
  --attach-policy-arn=arn:aws:iam::****:policy/AWSLoadBalancerControllerIAMPolicy \
  --approve
```

**you might have to create a policy also, please see if the above works before adding the below**
```
aws iam create-policy --policy-name AWSLoadBalancerControllerCustomPolicy --policy-document file://aws-load-balancer-controller-policy.json

aws iam attach-role-policy --role-name AmazonEKSAutoClusterRole --policy-arn arn:aws:iam::****:policy/AWSLoadBalancerControllerCustomPolicy
```

### tag the subnets you would like to use for kubernetes (public subnets)
```
aws ec2 create-tags --resources subnet**** --tags Key=kubernetes.io/role/elb,Value=1
```

### tag the subnets you would like to use for kubernetes (private subnets)
```
aws ec2 create-tags --resources subnet-**** --tags Key=kubernetes.io/role/internal-elb,Value=1
```
## configure the values.yaml

review lines 102 to 109 to set up connectivity to confluent cloud

## second deploy the chart

./start.sh

## try a simple connectivity test (use kcat or kafka-topics)

kcat -b ****.elb.us-east-1.amazonaws.com:9092 -L

kafka-topics --bootstrap-server ****.elb.us-east-1.amazonaws.com:9092 --list

# Next Steps!

* Run `./add_vault.sh`
* Follow the steps in [EXCHANGE](./EXCHANGE.md)
* Test Gateway `./test-gateway.sh`
* [Deploy console (make sure to set up postgres rds)](https://docs.conduktor.io/guide/conduktor-in-production/deploy-artifacts/deploy-console/kubernetes)

