#!/bin/sh

docker compose up --detach --wait

# # Add a guard on creating topics
# curl -u "admin:conduktor" \
#     -H 'Content-Type: application/json' \
#     http://localhost:8888/admin/interceptors/v1/vcluster/passthrough/interceptor/create-topic-safeguard -d '
# {
#   "name": "createTopicPolicy",
#   "pluginClass": "io.conduktor.gateway.interceptor.safeguard.CreateTopicPolicyPlugin",
#   "priority": 100,
#   "config": {
#     "topic": ".*",
#     "numPartition": {
#       "min": 1,
#       "max": 6,
#       "action": "BLOCK"
#     },
#     "replicationFactor": {
#       "min": 3,
#       "max": 3,
#       "action": "OVERRIDE",
#       "overrideValue": 3
#     }
#   }
# }  
# '