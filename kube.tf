module "subnets" {
  source    = "./subnets"
  cidr      = "${var.cidr}"
  num-nodes = "${var.num-nodes}"
}

provider "google" {
  credentials = "${file("account.json")}"
  project     = "${var.project}"
  region      = "${var.region}"
}
