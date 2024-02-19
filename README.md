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
├── setup-nv-federation.sh
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
cd ../../ ;
cd ./remote/eks && terraform init --upgrade && terraform apply -target=module.aws-elastic-kubernetes-service --auto-approve && terraform apply --auto-approve ;
cd ../../ ;
sh ./setup-nv-federation.sh ; 
echo "DONE!"
```

## One-click cleaning

```bash
cd ./remote/eks && sh ./drain-nodes.sh ; terraform destroy --auto-approve ;
cd ../../ ;
cd ./primary/gke && terraform state rm module.google-kubernetes-engine.local_file.kube-config-export ; terraform destroy -target=module.google-kubernetes-engine --auto-approve ; terraform destroy --auto-approve ;
cd ../../ ;
echo "DONE!"
```

**These scripts work perfectly from the macOS terminal; if you use any other Linux distribution, remove `''` from the `sed` command.**
