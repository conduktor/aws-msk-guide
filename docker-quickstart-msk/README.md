# Conduktor Gateway with MSK and Hashicorp

## Pre-requisites (IAM User)

You will need to create a valid IAM user with admin privledges to the cluster [Follow this guide from conduktor](https://docs.conduktor.io/guide/conduktor-in-production/admin/configure-clusters#connect-to-a-msk-cluster)


This example starts console and gateway
## Running the demo

### Set up Config

Copy the file `env-sample` to `.env` and edit it to contain an MSK bootstrap server as well as an API key and secret for this cluster. For testing purposes, we recommend to use a user-API key with, not a service account.

### Console

The console should work out of the box once you create a valid `.env` file. [Here is the cluster configuration if you want to review it](https://docs.conduktor.io/guide/conduktor-in-production/deploy-artifacts/deploy-console/sample-config#amazon-msk-with-iam-authentication-example)


### Gateway

You will probably need to tweak the number `GATEWAY_PORT_COUNT` based on the number of msk brokers you are connecting too. Just set that number to `number_of_brokers + 1`


### Starting

Once the `.env` file has been created, start the stack using
```bash
./start.sh
```

This will start *console* 

To add the gateway instance to the cluster run 
```
./add_gateway_to_console.sh
```

This will start the Gateway, add gateway to console, and add generate a token. You should be able to add a partnerzone from settings, more on this later

*adding encryption* 
```
./add_interceptors.sh
```
From here you should have a sample topic called `customers-json-encrypted` which should have encrypted customer data.

You should be able to share this data with users via the partner zone from the settings section see
[adding a partnerzone](https://docs.conduktor.io/platform/navigation/partner-zones/#create-a-partner-zone)



### *All of the demos will be run inside the docker network*


## (optional) using gateway as a cli user

List topics via Gateway:
```bash
docker compose exec kafka-client \
    kafka-topics \
    --list \
    --bootstrap-server gateway-msk:6969 \
    --command-config /clientConfig/kafka-admin.properties
```
You should see at least the internal topics created by Gateway:
```
_conduktor_gateway_acls
_conduktor_gateway_auditLogs
_conduktor_gateway_consumer_offsets
_conduktor_gateway_consumer_subscriptions
_conduktor_gateway_encryption_configs
_conduktor_gateway_interceptor_configs
_conduktor_gateway_license
_conduktor_gateway_topic_mappings
_conduktor_gateway_user_mappings
```
