terraform {
  required_providers {
    tailscale = {
      source  = "tailscale/tailscale"
      version = "~> 0.16"
    }
  }
}

provider "tailscale" {
  #   api_key = "tskey-1234567CNTRL-abcdefghijklmnopqrstu" // not recommended. Use env variable `TAILSCALE_API_KEY` instead
  tailnet = var.tailnet
}


locals {
  home_dir = data.external.env.result["home"]
  hostname = data.external.env.result["hostname"]
}

resource "tailscale_tailnet_key" "host" {
  reusable      = true
  ephemeral     = false
  preauthorized = true
  expiry        = 3600
  recreate_if_invalid = true
  description   = "${local.hostname} host"
  tags          = [ for tag in var.tags: join(",",["tag:${tag}"])]

}

resource "tailscale_tailnet_key" "container" {
  count         = length(var.tags)
  reusable      = true
  ephemeral     = true
  preauthorized = true
  expiry        = 3600
  recreate_if_invalid = true
  description   = "${local.hostname} ${var.tags[count.index]} container"
  tags          = ["tag:${var.tags[count.index]}"]
}


resource "local_file" "tsauthkey" {
  content  = tailscale_tailnet_key.host.key
  filename = "${local.home_dir}/.config/homelab/tsauthkey"
  directory_permission = "700"
  file_permission = "600"
}

resource "local_file" "tsauthkeys" {
  count    = length(var.tags)
  content  = tailscale_tailnet_key.container[count.index].key
  filename = "${local.home_dir}/.config/homelab/tsauthkey-${var.tags[count.index]}"
  directory_permission = "700"
  file_permission = "600"
}

# data "tailscale_acl" "policy" {}

# output "policy" {
#     value = data.tailscale_acl.policy.hujson
# }