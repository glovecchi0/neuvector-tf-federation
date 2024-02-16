# Security from scratch in a federated multi-cloud environment

Create a pair of Kubernetes clusters on different Cloud Providers, secure from day-1 with [clustered NeuVector](https://open-docs.neuvector.com/navigation/multicluster).

### Scenario

| NV Role | Managed Kubernetes Cluster |
| ------- | -------------------------- |
| Primary NeuVector cluster | [GKE](https://github.com/glovecchi0/neuvector-tf/tree/main/tf-modules/google-cloud/gke) |
| Secondary/Remote NeuVector cluster | [EKS](https://github.com/glovecchi0/neuvector-tf/tree/main/tf-modules/aws/eks) |

### How the repository is structured

```
.
├── primary
│   └── gke #Tf files, and NV cusotm Helm Chart values file
├── remote
│   └── eks #Tf files, and NV cusotm Helm Chart values file
└── README.md

```

# How to create resources

### Prerequisites

- Copy `./primary/gke/terraform.tfvars.example` to `./primary/gke/terraform.tfvars`
- Edit `./primary/gke/terraform.tfvars`
  - Update the required variables:
    -  `prefix` to give the resources an identifiable name (eg, your initials or first name)
    -  `project_id` to specify in which Project the resources will be created
    -  `region` to suit your region
    -  `neuvector_password` to change the default admin password
- Log in to the Google Cloud provider from your local Terminal. See the preparatory steps [here](https://github.com/glovecchi0/neuvector-tf/tree/main/tf-modules/google-cloud/README.md)
- Copy `./remote/eks/terraform.tfvars.example` to `./remote/eks/terraform.tfvars`
- Edit `./remote/eks/terraform.tfvars`
  - Update the required variables:
    -  `prefix` to give the resources an identifiable name (eg, your initials or first name)
    -  `allowed_ip_cidr_range` to specify which IP addresses will be able to contact the cluster API Server
    -  `aws_region` to suit your region
    -  `neuvector_password` to change the default admin password
- Log in to the AWS provider from your local Terminal. See the preparatory steps [here](https://github.com/glovecchi0/neuvector-tf/tree/main/tf-modules/aws/README.md)

## One-click creation

```bash
cd ./primary/gke && terraform init --upgrade && terraform apply -target=module.google-kubernetes-engine --auto-approve && terraform apply --auto-approve ;
cd ./remote/eks && terraform init --upgrade && terraform apply -target=module.aws-elastic-kubernetes-service --auto-approve && terraform apply --auto-approve ;
cp ./setup-nv-federation.sh.tpl ./setup-nv-federation.sh ;
sed -i '' "s/PRIMARY_CLUSTER_FEDSVC_IP=.*/PRIMARY_CLUSTER_FEDSVC_IP=\"$(terraform output -state=./primary/gke/terraform.tfstate -raw neuvector-svc-controller-fed-managed)\"/g" ./setup-nv-federation.sh ;
sed -i '' "s/SECONDARY_CLUSTER_FEDSVC_IP=.*/SECONDARY_CLUSTER_FEDSVC_IP=\"$(terraform output -state=./remote/eks/terraform.tfstate -raw neuvector-svc-controller-fed-managed)\"/g" ./setup-nv-federation.sh ;
sed -i '' "s/PRIMARY_CLUSTER_ADMIN_PWD=.*/PRIMARY_CLUSTER_ADMIN_PWD=\"$(cat ./primary/gke/terraform.tfvars | grep -i neuvector_password | awk -F= '{print $2}' | tr -d '"' | sed 's/ //g')\"/g" ./setup-nv-federation.sh ;
sed -i '' "s/SECONDARY_CLUSTER_ADMIN_PWD=.*/SECONDARY_CLUSTER_ADMIN_PWD=\"$(cat ./remote/eks/terraform.tfvars | grep -i neuvector_password | awk -F= '{print $2}' | tr -d '"' | sed 's/ //g')\"/g" ./setup-nv-federation.sh ;
sh ./setup-nv-federation.sh
```

**These scripts work perfectly from the macOS terminal; if you use any other Linux distribution, remove `''` from the `sed` command.**
