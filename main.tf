provider "google-beta" {
  project = var.project_id
}

provider "google" {
}

locals {
  permis = {
    "roles/compute.admin"          = "user:ericstumbo@student.purdueglobal.edu",
    "roles/iam.serviceAccountUser" = "user:ericstumbo@student.purdueglobal.edu"
  }
}

resource "google_project_iam_member" "project" {
  project  = var.project_id
  for_each = local.permis
  role     = each.key
  member   = each.value
}

resource "google_compute_firewall" "default" {
  project       = var.project_id
  name          = "allow-ssh-from-iap"
  network       = "default"
  source_ranges = ["35.235.240.0/20"]
  allow {
    protocol = "tcp"
  }
}

## Have to add a local-exec to delete default SSH rule

data "google_compute_image" "my_image" {
  family  = "debian-9"
  project = "debian-cloud"
}

resource "google_compute_instance" "default" {
  project      = "${var.project_id}"
  machine_type = "n1-standard-1"
  name         = "${var.instance_name}"
  zone         = "${var.zone}"
  network_interface {
    network = "default"
  }

  boot_disk {
    initialize_params {
      image = "${data.google_compute_image.my_image.self_link}"
    }
  }
}

resource "google_iap_tunnel_instance_iam_member" "instance" {
  provider = "google-beta"
  instance = "${var.instance_name}"
  zone     = "${var.zone}"
  role     = "roles/iap.tunnelResourceAccessor"
  member   = "user:ericstumbo@student.purdueglobal.edu"
  depends_on = [google_compute_instance.default]
}



