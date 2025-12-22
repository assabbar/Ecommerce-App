##########################################################################
# Kubernetes Namespaces pour la séparation des services
##########################################################################

# Namespace pour le Backend (Microservices)
resource "kubernetes_namespace" "backend" {
  provider = kubernetes.aks

  metadata {
    name = "backend"
    labels = {
      name        = "backend"
      environment = "dev"
      tier        = "application"
    }
  }

  depends_on = [azurerm_kubernetes_cluster.aks]
}

# Namespace pour le Frontend (Application Web)
resource "kubernetes_namespace" "frontend" {
  provider = kubernetes.aks

  metadata {
    name = "frontend"
    labels = {
      name        = "frontend"
      environment = "dev"
      tier        = "presentation"
    }
  }

  depends_on = [azurerm_kubernetes_cluster.aks]
}

# Namespace pour le Monitoring (Stack de surveillance)
resource "kubernetes_namespace" "monitoring" {
  provider = kubernetes.aks

  metadata {
    name = "monitoring"
    labels = {
      name        = "monitoring"
      environment = "dev"
      tier        = "infrastructure"
    }
  }

  depends_on = [azurerm_kubernetes_cluster.aks]
}

##########################################################################
# ImagePullSecrets pour accès au Azure Container Registry (ACR)
# NOTE: Utilisation de Managed Identity d'AKS via azurerm_role_assignment.acr_pull
# Les pods accèdent directement à l'ACR sans secret Kubernetes supplémentaire
##########################################################################

##########################################################################
# Service Accounts pour les déploiements
##########################################################################

resource "kubernetes_service_account" "backend_sa" {
  provider = kubernetes.aks

  metadata {
    name      = "backend-sa"
    namespace = kubernetes_namespace.backend.metadata[0].name
  }

  depends_on = [kubernetes_namespace.backend]
}

resource "kubernetes_service_account" "frontend_sa" {
  provider = kubernetes.aks

  metadata {
    name      = "frontend-sa"
    namespace = kubernetes_namespace.frontend.metadata[0].name
  }

  depends_on = [kubernetes_namespace.frontend]
}

resource "kubernetes_service_account" "monitoring_sa" {
  provider = kubernetes.aks

  metadata {
    name      = "monitoring-sa"
    namespace = kubernetes_namespace.monitoring.metadata[0].name
  }

  depends_on = [kubernetes_namespace.monitoring]
}
