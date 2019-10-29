# GCP Identity Aware Proxy

I am not going to lie, I struggled with this for a while but finally got it figured out with terraform.  
We have to role this out to a large number of projects so I developed a template to automate some of the process.  
This main.tf will accomplish a few things:  
1. Create the correct firewall rule
2. Add the proper roles to a user (this has a for_each for adding multiple users)
3. Spin up an instance
4. Attach the role IAP tunnel user to the instance using an email address

What it doesnt do:
1. Currently there is no command to turn on IAP
2. To turn on IAP just open it up in the IAM section on GCP (it gets enabled)
3. Delete the default firewall rules (setup a local exec to delete them)

Here is what the main.tf looks like:
```
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
```

## Conclusion

Now you should be able to use the command  
`gcloud beta compute ssh {{ instance-name }} --zone {{ instance-zone }} --tunnel-through-iap`    
I understand that giving the compute Admin role to users can be difficult but this can be accomplished by building a custom role.