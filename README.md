# Incident Response Analysis Infrastructure

An infrastructure as code, written for OpenTOFU / Terraform, based on QEMU/KVM. This project is purely based on OpenSource software.

<img src="https://github.com/sweigmann/dfir-infrastructure/actions/workflows/opentofu.yml/badge.svg?branch=main">

## Overview

<img src="docs/overview.png">

### Features

Each case instance comes with tools and services which are limited to the case instance. It is not intended to use a case service with data from other cases.

Available out of the box - per case:

- [DFIR-IRIS](https://www.dfir-iris.org/)
- [Timesketch](https://timesketch.org/)
- [Jupyter Notebooks](https://jupyter.org/)
- [Plaso](https://github.com/log2timeline/plaso)
- [The Sleuth Kit](https://www.sleuthkit.org/sleuthkit/)
- [Volatility3](https://volatilityfoundation.org/the-volatility-framework/)
- [DFIR-Toolkit](https://codeberg.org/dfir-dd/dfir-toolkit)
- [danalyze](https://codeberg.org/DFIR/danalyze) / [time-tools](https://codeberg.org/DFIR/time-tools) / [offset-tools](https://codeberg.org/DFIR/offset-tools)
- and more...

## Quickstart

1. Have a machine ready running KVM

   **NOTE:** You might need to disable the apparmor profile for libvirt, as otherwise, instances using chained qcow2 disk images might fail to start.

1. Set up your internal gateway to forward requests for your internal DFIR DNS zone (example: `incident-responders.org`) to the KVM machine

1. Clone this repository

1. Adapt `terraform.tfvars` according to your needs

1. Configure your cases in `cases.auto.tfvars`

1. `tofu init && tofu plan && tofu apply`

1. URLs and other means how to access your infrastructure will be displayed after the infrastructure was spawned.

1. Adding and deleting case records from `cases.auto.tfvars` and then executing `tofu plan && tofu apply` will remove and add case infrastructure as indicated.

## Further Development

This project is in its early stage and therefore must be considered constant work-in-progress. Below is a sketch of what is planned next.

### Roadmap

1. Think about automated imports from Plaso to Timesketch.
1. Develop and integrate means to analyze and visualize NetFlow data.

### Bugs

- When a case was already up and another case is created, the access network configuration is rewritten by the `libvirt` provider to include forwarding configurations for the new case network. By doing so, libvirt will loose track of the DHCP leases of the first case machines, rendering them inaccessible. Furthermore, DHCP requests by those instances will not be answered by the hypervisor. The reason for DHCP requests not being answered is yet unknown. No workaround is known.
- Bastion host and Access Network still share the same IP range. Thus, gateways would directly be accessible by the "outside world". Bastion host services should be the only services which are initially accessible.
- The Timesketch Notebook template is buggy. It lacks certain functions to extract data from the XML part of EVTX logs.  Suggestions on how to resolve this are welcome!
- The siftstation (_not_ to be confused with the SANS Sift Station) does mount the writable NFS share read-only. A workaround is to just reboot the host or issue:
    ```
    mount -o remount,rw /data/read-write /data/read-write
    ```
