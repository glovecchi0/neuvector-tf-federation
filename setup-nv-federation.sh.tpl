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

echo "Retrieve the join_token from the Master cluster."
curl -k -H "Content-Type: application/json" -H "X-Auth-Token: $PRIMARY_CLUSTER_ADMIN_PWD_TOKEN" "https://$PRIMARY_CLUSTER_FEDSVC_IP:10443/v1/fed/join_token" > /dev/null 2>&1 > ./primary_cluster_join_token.json
cat ./primary_cluster_join_token.json | jq -c .
PRIMARY_CLUSTER_JOIN_TOKEN=`cat ./primary_cluster_join_token.json | jq -r '.join_token'`
echo

echo "Login as admin on the secondary NeuVector cluster and retrieve the token.json file from this user."
curl -k -H "Content-Type: application/json" -d '{"password": {"username": "admin", "password": "'$SECONDARY_CLUSTER_ADMIN_PWD'"}}' "https://$SECONDARY_CLUSTER_FEDSVC_IP:10443/v1/auth" > /dev/null 2>&1 > ./secondary_cluster_admin_token.json
SECONDARY_CLUSTER_ADMIN_PWD_TOKEN=`cat ./secondary_cluster_admin_token.json | jq -r '.token.token'`
echo

echo "Join the secondary cluster to the Master."
curl -k -H "Content-Type: application/json" -H "X-Auth-Token: $SECONDARY_CLUSTER_ADMIN_PWD_TOKEN" -d '{"join_token": "'$PRIMARY_CLUSTER_JOIN_TOKEN'", "name": "worker", "joint_rest_info": {"port": 10443, "server": "'$SECONDARY_CLUSTER_FEDSVC_IP'"}}' "https://$SECONDARY_CLUSTER_FEDSVC_IP:10443/v1/fed/join" > /dev/null 2>&1
sleep 9
echo

#Check the status
#curl -k -H "Content-Type: application/json" -H "X-Auth-Token: $PRIMARY_CLUSTER_ADMIN_PWD_TOKEN" "https://$PRIMARY_CLUSTER_FEDSVC_IP:10443/v1/fed/member" > /dev/null 2>&1 > ./fedMember.json
#cat ./fedMember.json | jq -c .

#curl -k -H "Content-Type: application/json" -H "X-Auth-Token: $SECONDARY_CLUSTER_ADMIN_PWD_TOKEN" "https://$SECONDARY_CLUSTER_FEDSVC_IP:10443/v1/fed/member" > /dev/null 2>&1 > ./fedMember.json
#cat ./fedMember.json | jq -c .
