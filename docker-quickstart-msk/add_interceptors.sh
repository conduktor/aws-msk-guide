#!/bin/bash

# cli a resource file via conduktor CLI
login_cli () {
  local FILENAME=$1
  docker run --rm \
    -e CDK_USER=$CDK_USER \
    -e CDK_PASSWORD=$CDK_PASSWORD \
    -e CDK_BASE_URL=http://conduktor-console:8080 \
    --network conduktor-net \
    --volume $PWD/resources:/resources $CONDUKTOR_CLI_IMAGE "$@"
}

# cli a resource file via conduktor CLI
cli () {
  local FILENAME=$1
  docker run --rm \
    -e CDK_API_KEY=$CDK_API_KEY \
    -e CDK_BASE_URL=http://conduktor-console:8080 \
    -e CDK_GATEWAY_BASE_URL=http://gateway-confluent-cloud:8888 \
    -e CDK_GATEWAY_USER=admin \
    -e CDK_GATEWAY_PASSWORD=conduktor \
    -e GATEWAY_ADMIN_TOKEN=$GATEWAYTOKEN \
    --network conduktor-net \
    --volume $PWD/resources:/resources $CONDUKTOR_CLI_IMAGE "$@"
}

export CONDUKTOR_CLI_IMAGE=conduktor/conduktor-ctl:latest
export CDK_USER=admin@demo.dev
export CDK_PASSWORD=adminP4ss!
export CDK_API_KEY="1"

# generate a random string
export CONSUMER_GROUP=$(openssl rand -base64 32 | head -c 5 )

login_cli login


export CDK_API_KEY=$(login_cli login)

export GATEWAYTOKEN=$(cat gatewaytoken)

# lets add some interceptors

cli delete Interceptor decrypt-customers-json --vcluster=passthrough

echo "Let's demonstrate field level encryption"

cli delete -f resources/customers-json-encrypted.yaml
cli apply -f resources/customers-json-encrypted.yaml

echo "Remember our dataset?"
cat customer-data.json

echo "Let's make sure that PII (lastname and email) data is encrypted"

cli apply -f resources/encrypt-customers-json.yaml

sleep 3

echo "Let's send unencrypted JSON"

cat customer-data.json | docker compose exec -T kafka-client \
    kafka-console-producer  \
        --bootstrap-server gateway-confluent-cloud:6969 \
        --producer.config /clientConfig/kafka-admin.properties \
        --topic customers-json-encrypted

echo  "Observe that we didn't have to modify the kafka-clients"

echo "Let's make sure messages are encrypted"

docker compose exec kafka-client \
    kafka-console-consumer \
        --bootstrap-server gateway-confluent-cloud:6969 \
        --consumer.config /clientConfig/kafka-admin.properties \
        --topic customers-json-encrypted \
        --from-beginning \
        --max-messages 3 | jq

echo "'last_name' and 'email' fields are encrypted"

echo "Let's add decryption to make it transparent for the clients"

sleep 3

cli apply -f resources/decrypt-customers-json.yaml

echo "Let's make sure messages are now decrypted"

docker compose exec kafka-client \
    kafka-console-consumer \
        --bootstrap-server gateway-confluent-cloud:6969 \
        --consumer.config /clientConfig/kafka-admin.properties \
        --topic customers-json-encrypted \
        --from-beginning \
        --max-messages 3 | jq

echo "'last_name' and 'email' fields are decrypted. Again, we did't have to modify the clients!"

echo "now lets add the partnerzones"
# add the partner zone
cli apply -f resources/customers_partnerzone.yaml