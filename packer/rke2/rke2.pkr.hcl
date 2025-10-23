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
  description = "OS image name to use for the image"
}

variable "rke2_version" {
  type        = string
  description = "RKE2 version to install on the Image"
  default     = "v1.34.1+rke2r1"
}

source "qemu" "base-img" {
  vm_name           = "rke2-${var.vm_name}.qcow2"
  iso_url           = "build/${var.vm_name}/${var.vm_name}.raw"
  iso_checksum      = "none"
  disk_image        = true
  memory            = 1500
  output_directory  = "build/rke2"
  accelerator       = "kvm"
  disk_size         = "12000M"
  disk_interface    = "virtio"
  format            = "qcow2"
  net_device        = "virtio-net"
  boot_wait         = "3s"
  cpu_model         = "host"
  shutdown_command  = "echo 'packer' | sudo -S shutdown -P now"
  ssh_username      = "packer"
  ssh_password      = "packer"
  ssh_timeout       = "60m"
  headless          = true
}

build {
  name = "rke2"

  sources = ["source.qemu.base-img"]

  provisioner "shell" {
    execute_command = "chmod +x {{ .Path }}; sudo {{ .Vars }} {{ .Path }}"
    script          = "./scripts/install-deps.sh"
    timeout         = "20m"
  }

  provisioner "shell" {
    environment_vars = [
      "INSTALL_RKE2_VERSION=${var.rke2_version}"
    ]
    execute_command = "chmod +x {{ .Path }}; sudo {{ .Vars }} {{ .Path }}"
    script          = "./scripts/rke2-install.sh"
    timeout         = "15m"
  }

  provisioner "shell" {
    execute_command   = "chmod +x {{ .Path }}; sudo {{ .Vars }} {{ .Path }}"
    script            = "./scripts/os-stig.sh"
    expect_disconnect = true // Expect a restart due to FIPS reboot
    timeout           = "20m"
    pause_after       = "30s" // Give a grace period for the OS to restart
  }

  provisioner "shell" {
    execute_command = "chmod +x {{ .Path }}; sudo {{ .Vars }} {{ .Path }}"
    script          = "./scripts/os-prep.sh"
    timeout         = "15m"
  }

  provisioner "shell" {
    execute_command = "chmod +x {{ .Path }}; sudo {{ .Vars }} {{ .Path }}"
    script          = "./scripts/cleanup-deps.sh"
    timeout         = "15m"
  }

  provisioner "file" {
    source      = "./scripts/rke2-startup.sh"
    destination = "/tmp/rke2-startup.sh"
  }

  provisioner "file" {
    source      = "./files"
    destination = "/tmp"
  }

  provisioner "shell" {
    execute_command = "chmod +x {{ .Path }}; sudo {{ .Vars }} {{ .Path }}"
    script          = "./scripts/rke2-config.sh"
    timeout         = "15m"
  }

  provisioner "shell" {
    execute_command = "chmod +x {{ .Path }}; sudo {{ .Vars }} {{ .Path }}"
    script          = "./scripts/cleanup-cloud-init.sh"
    timeout         = "15m"
  }
}