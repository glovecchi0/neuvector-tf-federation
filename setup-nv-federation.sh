#!/bin/bash

sleep 180

PRIMARY_CLUSTER_FEDMASTER_IP="$(terraform output -state=./primary/gke/terraform.tfstate neuvector_svc_controller_fed_master | tr -d '"' | sed 's/ //g')"
PRIMARY_CLUSTER_FEDMANAGED_IP="$(terraform output -state=./primary/gke/terraform.tfstate neuvector_svc_controller_fed_managed | tr -d '"' | sed 's/ //g')"
SECONDARY_CLUSTER_FEDMASTER_IP="$(terraform output -state=./remote/eks/terraform.tfstate neuvector_svc_controller_fed_master | tr -d '"' | sed 's/ //g')"
SECONDARY_CLUSTER_FEDMANAGED_IP="$(terraform output -state=./remote/eks/terraform.tfstate neuvector_svc_controller_fed_managed | tr -d '"' | sed 's/ //g')"
PRIMARY_CLUSTER_ADMIN_PWD="$(cat ./primary/gke/terraform.tfvars | grep -v "#" | grep -i neuvector_password | awk -F= '{print $2}' | tr -d '"' | sed 's/ //g')"
SECONDARY_CLUSTER_ADMIN_PWD="$(cat ./remote/eks/terraform.tfvars | grep -v "#" | grep -i neuvector_password | awk -F= '{print $2}' | tr -d '"' | sed 's/ //g')"

echo "Login as admin on the primary NeuVector cluster and retrieve the token.json file from this user."
curl -k -H "Content-Type: application/json" -d '{"password": {"username": "admin", "password": "'$PRIMARY_CLUSTER_ADMIN_PWD'"}}' "https://$PRIMARY_CLUSTER_FEDMANAGED_IP:10443/v1/auth" > /dev/null 2>&1 > ./primary_cluster_admin_token.json
PRIMARY_CLUSTER_ADMIN_PWD_TOKEN=`cat ./primary_cluster_admin_token.json | jq -r '.token.token'`
echo

echo "Promotion of the primary cluster to Controller."
curl -k -H "Content-Type: application/json" -H "X-Auth-Token: $PRIMARY_CLUSTER_ADMIN_PWD_TOKEN" -d '{"master_rest_info": {"port": 11443, "server": "'$PRIMARY_CLUSTER_FEDMASTER_IP'"}, "name": "controller"}' "https://$PRIMARY_CLUSTER_FEDMANAGED_IP:10443/v1/fed/promote" > /dev/null 2>&1
sleep 6
echo

echo "Login as admin on the primary NeuVector cluster and retrieve the token.json file from this user."
curl -k -H "Content-Type: application/json" -d '{"password": {"username": "admin", "password": "'$PRIMARY_CLUSTER_ADMIN_PWD'"}}' "https://$PRIMARY_CLUSTER_FEDMANAGED_IP:10443/v1/auth" > /dev/null 2>&1 > ./primary_cluster_admin_token.json
PRIMARY_CLUSTER_ADMIN_PWD_TOKEN=`cat ./primary_cluster_admin_token.json | jq -r '.token.token'`
echo

echo "Retrieve the join_token from the Controller cluster."
curl -k -H "Content-Type: application/json" -H "X-Auth-Token: $PRIMARY_CLUSTER_ADMIN_PWD_TOKEN" "https://$PRIMARY_CLUSTER_FEDMANAGED_IP:10443/v1/fed/join_token" > /dev/null 2>&1 > ./primary_cluster_join_token.json
cat ./primary_cluster_join_token.json | jq -c .
PRIMARY_CLUSTER_JOIN_TOKEN=`cat ./primary_cluster_join_token.json | jq -r '.join_token'`
echo

echo "Login as admin on the remote NeuVector cluster and retrieve the token.json file from this user."
curl -k -H "Content-Type: application/json" -d '{"password": {"username": "admin", "password": "'$SECONDARY_CLUSTER_ADMIN_PWD'"}}' "https://$SECONDARY_CLUSTER_FEDMANAGED_IP:10443/v1/auth" > /dev/null 2>&1 > ./secondary_cluster_admin_token.json
SECONDARY_CLUSTER_ADMIN_PWD_TOKEN=`cat ./secondary_cluster_admin_token.json | jq -r '.token.token'`
echo

echo "Join the remote cluster to the Controller."
curl -k -H "Content-Type: application/json" -H "X-Auth-Token: $SECONDARY_CLUSTER_ADMIN_PWD_TOKEN" -d '{"join_token": "'$PRIMARY_CLUSTER_JOIN_TOKEN'", "name": "worker", "joint_rest_info": {"port": 10443, "server": "'$SECONDARY_CLUSTER_FEDMANAGED_IP'"}}' "https://$SECONDARY_CLUSTER_FEDMANAGED_IP:10443/v1/fed/join" > /dev/null 2>&1
sleep 9
echo

echo "Check the federation status on the Controller cluster."
curl -k -H "Content-Type: application/json" -H "X-Auth-Token: $PRIMARY_CLUSTER_ADMIN_PWD_TOKEN" "https://$PRIMARY_CLUSTER_FEDMANAGED_IP:10443/v1/fed/member" > /dev/null 2>&1 > ./fed_member.json
cat ./fed_member.json | jq -c .
echo

echo "Check the federation status on the Worker cluster."
curl -k -H "Content-Type: application/json" -H "X-Auth-Token: $SECONDARY_CLUSTER_ADMIN_PWD_TOKEN" "https://$SECONDARY_CLUSTER_FEDMANAGED_IP:10443/v1/fed/member" > /dev/null 2>&1 > ./fed_member.json
cat ./fed_member.json | jq -c .
cat ./fed_member.json | jq -r --arg _CLUSTER_name_ "$_CLUSTER_name_" '.joint_clusters[] | select(.name == $_CLUSTER_name_).id'
echo
