module "google-kubernetes-engine" {
  source     = "git::https://github.com/glovecchi0/neuvector-tf.git//tf-modules/google-cloud/gke"
  prefix     = var.prefix
  project_id = var.project_id
  region     = var.region
  #  vpc        = var.vpc
  #  subnet     = var.subnet
  #  cluster_version    = var.cluster_version
  #  instance_count     = var.instance_count
  #  instance_disk_size = var.instance_disk_size
  #  disk_type          = var.disk_type
  #  image_type         = var.image_type
  #  instance_type      = var.instance_type
}

resource "null_resource" "first-setup" {
  depends_on = [module.google-kubernetes-engine.kubernetes_cluster_node_pool]
  provisioner "local-exec" {
    command = "sh ./first-setup.sh"
  }
}

resource "helm_release" "neuvector-core" {
  depends_on       = [resource.null_resource.first-setup]
  name             = "neuvector"
  repository       = "https://neuvector.github.io/neuvector-helm/"
  chart            = "core"
  create_namespace = true
  namespace        = "cattle-neuvector-system"

  values = [
    "${file("${path.cwd}/custom-helm-values.yaml")}"
  ]

  set {
    name  = "controller.secret.data.userinitcfg\\.yaml.users[0].Password"
    value = var.neuvector_password
  }
}

data "kubernetes_service" "neuvector-service-webui" {
  metadata {
    name      = "neuvector-service-webui"
    namespace = resource.helm_release.neuvector-core.namespace
  }
}

data "kubernetes_service" "neuvector-svc-controller-fed-managed" {
  metadata {
    name      = "neuvector-svc-controller-fed-managed"
    namespace = resource.helm_release.neuvector-core.namespace
  }
}

data "kubernetes_service" "neuvector-svc-controller-fed-master" {
  metadata {
    name      = "neuvector-svc-controller-fed-master"
    namespace = resource.helm_release.neuvector-core.namespace
  }
}
