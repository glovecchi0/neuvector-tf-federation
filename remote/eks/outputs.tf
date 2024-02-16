output "neuvector-webui-url" {
  value       = "https://${data.kubernetes_service.neuvector-service-webui.status.0.load_balancer.0.ingress[0].hostname}:8443"
  description = "NeuVector WebUI (Console) URL"
}

output "neuvector-svc-controller-fed-managed" {
  value       = "${data.kubernetes_service.neuvector-svc-controller-fed-managed.status.0.load_balancer.0.ingress[0].hostname}"
  description = "NeuVector fed-managed IP"
}

output "neuvector-svc-controller-fed-master" {
  value       = "${data.kubernetes_service.neuvector-svc-controller-fed-master.status.0.load_balancer.0.ingress[0].hostname}"
  description = "NeuVector fed-master IP"
}
