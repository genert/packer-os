packer {
  required_version = "= 1.14.2"
  required_plugins {
    qemu = {
      version = "= 1.1.4"
      source = "github.com/hashicorp/qemu"
    }
  }
}

variable "vm_name" {
  type        = string
  description = "VM name to use for the image"
}

variable "iso_url" {
  type        = string
  description = "ISO URL to use for the image"
}

variable "iso_checksum" {
  type        = string
  description = "ISO checksum to use for the image"
}

source "qemu" "iso" {
  vm_name              = "${var.vm_name}.raw"
  iso_url              = var.iso_url
  iso_checksum         = var.iso_checksum
  memory               = 1500
  disk_image           = false
  output_directory     = "build/${var.vm_name}"
  accelerator          = "kvm"
  disk_size            = "12000M"
  disk_interface       = "virtio"
  format               = "raw"
  net_device           = "virtio-net"
  boot_wait            = "3s"
  boot_command         = ["<up>",
                          "<tab><wait>",
                          " inst.ks=http://{{.HTTPIP}}:{{.HTTPPort}}/ks.cfg",
                          "<enter>"
    ]
  http_directory       = "http"
  # Required on RHEL 9 or there will be a kernel panic on boot. Search "RHEL9" in here for details:
  #
  # https://developer.hashicorp.com/packer/integrations/hashicorp/qemu/latest/components/builder/qemu
  #
  cpu_model            = "host"
  shutdown_command     = "echo 'packer' | sudo -S shutdown -P now"
  # These are required or Packer will panic, even if no provisioners are not
  # configured
  ssh_username         = "packer"
  ssh_password         = "packer"
  ssh_timeout          = "60m"
}

build {
  name = "iso"

  sources = ["source.qemu.iso"]
}