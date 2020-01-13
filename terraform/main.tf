terraform {
  backend "local" {
  }
}

provider "google-beta" {
  version = "~> 2.20"
  project = var.project
  region  = "europe-west1"
}


resource "google_container_cluster" "cluster" {
  provider = "google-beta"
  name     = "kubernetest"
  location = "europe-west1-d"

  initial_node_count       = 1
  remove_default_node_pool = true
  min_master_version       = "1.15"


  # Setting an empty username and password explicitly disables basic auth
  master_auth {
    username = ""
    password = ""

    client_certificate_config {
      issue_client_certificate = false
    }
  }

  addons_config {

    horizontal_pod_autoscaling {
      disabled = false
    }

    network_policy_config {
      disabled = false
    }
  }

  maintenance_policy {
    daily_maintenance_window {
      start_time = "04:00"
    }
  }

  network_policy {
    enabled = true
  }

  private_cluster_config {
    master_ipv4_cidr_block  = "10.2.0.0/28"
    enable_private_endpoint = false
    enable_private_nodes    = true
  }

  master_authorized_networks_config {
    cidr_blocks {
      cidr_block   = "0.0.0.0/0"
      display_name = "Internet"
    }
  }

  ip_allocation_policy {
    #use_ip_aliases                = true
    # services_secondary_range_name = "kubernetes-services"
    # cluster_secondary_range_name  = "kubernetes-pods"
  }

  pod_security_policy_config {
    enabled = false
  }
}


resource "google_container_node_pool" "primary_preemptible_nodes" {
  provider   = "google-beta"
  location   = "europe-west1-d"
  cluster    = google_container_cluster.cluster.name
  node_count = 1

  node_config {
    preemptible  = true
    machine_type = "n1-standard-2"

    metadata = {
      disable-legacy-endpoints = "true"
    }

    oauth_scopes = [
      "https://www.googleapis.com/auth/logging.write",
      "https://www.googleapis.com/auth/monitoring",
      "https://www.googleapis.com/auth/devstorage.read_only",
    ]
  }
}
