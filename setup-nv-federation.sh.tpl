#!/bin/bash

PRIMARY_CLUSTER_FEDSVC_IP=""
SECONDARY_CLUSTER_FEDSVC_IP=""
PRIMARY_CLUSTER_ADMIN_PWD=""
SECONDARY_CLUSTER_ADMIN_PWD=""

echo "Login as admin on the primary NeuVector cluster and retrieve the token.json file from this user."
curl -k -H "Content-Type: application/json" -d '{"password": {"username": "admin", "password": "'$PRIMARY_CLUSTER_ADMIN_PWD'"}}' "https://$PRIMARY_CLUSTER_FEDSVC_IP:10443/v1/auth" > /dev/null 2>&1 > ./primary_cluster_admin_token.json
PRIMARY_CLUSTER_ADMIN_PWD_TOKEN=`cat ./primary_cluster_admin_token.json | jq -r '.token.token'`
echo

echo "Promotion of the primary cluster to Master."
curl -k -H "Content-Type: application/json" -H "X-Auth-Token: $PRIMARY_CLUSTER_ADMIN_PWD_TOKEN" -d '{"master_rest_info": {"port": 11443, "server": "'$PRIMARY_CLUSTER_FEDSVC_IP'"}, "name": "master"}' "https://$PRIMARY_CLUSTER_FEDSVC_IP:10443/v1/fed/promote" > /dev/null 2>&1
sleep 6
echo

echo "Login as admin on the secondary NeuVector cluster and retrieve the token.json file from this user."
curl -k -H "Content-Type: application/json" -d '{"password": {"username": "admin", "password": "'$SECONDARY_CLUSTER_ADMIN_PWD'"}}' "https://$SECONDARY_CLUSTER_FEDSVC_IP:10443/v1/auth" > /dev/null 2>&1 > ./secondary_cluster_admin_token.json
SECONDARY_CLUSTER_ADMIN_PWD_TOKEN=`cat ./secondary_cluster_admin_token.json | jq -r '.token.token'`
echo

echo "Join the secondary cluster to the Master."
curl -k -H "Content-Type: application/json" -H "X-Auth-Token: $SECONDARY_CLUSTER_ADMIN_PWD_TOKEN" -d '{"join_token": "'$SECONDARY_CLUSTER_ADMIN_PWD_TOKEN'", "name": "worker", "joint_rest_info": {"port": 10443, "server": "'$SECONDARY_CLUSTER_FEDSVC_IP'"}}' "https://$SECONDARY_CLUSTER_FEDSVC_IP:10443/v1/fed/join" > /dev/null 2>&1
sleep 9
echo

#Check the status
