# TKS

* [Summary](#Summary)
* [Requirements](#Requirements)
  * [Hardware](#Hardware)
  * [Software](#Software)
* [Getting Started](#Gettined-Started)
* [Frequently Asked Questions](#Frequently-Asked-Questions)
<hr>

## Summary

As infrastructure becomes more and more abstracted from the user, it becomes both easier to work with and harder to manage. Hypervisors, containers, orchestration platforms, etc. Cloud providers today manage to automate this complexity at scale for millions of enterprise customers.  TKS is a collection of projects aiming to provide a similar experience with bare metal.

Each component of TKS is broken out into a dedicated subproject. The is that each component should be able to be used interchangeably with other platforms. For example, [TKS-Deploy_Kubernetes_Apps](https://github.com/zimmertr/TKS-Deploy_Kubernetes_Apps) is collection of Kubernetes manifests, Kustomizations, and Ansible projects that should allow you to deploy applications to any Kubernetes cluster.   

Combining all of the components together will produce a platform that leverages:

| Technology    | Description                                              |
| ------------- | -------------------------------------------------------- |
| Proxmox VE    | Type 1 Hypervisor                                        |
| ZFS           | Block storage for VMs and file storage for containers    |
| Kubernetes    | Container Orchestration Platform                         |
| HAProxy       | Virtual Load Balancer for Kubernetes Control Plane nodes |
| Grafana Stack | Federated monitoring platform                            |
| Vault         | Encrypted & decentralized secrets management             |
| Gitlab        | Source Control & Continuous Integration                  |
| ArgoCD        | Continuous Delivery                                      |
| Harbor        | Container Image Registry                                 |

When possible, automation is leveraged using common tooling like Terraform, Ansible, Cloud Init, and Kustomize. When configuration is necessary, options are exposed through environment variables and defaults are configured as appropriate. 
<hr>

## Requirements

### Hardware

TKS requires a server, some storage, and an understanding of how to network everything together. You don't need much compute, I ran all of this on a [2008 Mac Pro](https://everymac.com/systems/apple/mac_pro/specs/mac-pro-eight-core-3.2-2008-specs.html) for years. You could even re-purpose this to run on a cloud platform like AWS. [TKS-Bootstrap_Proxmox](https://github.com/zimmertr/TKS-Bootstrap_Proxmox) provides instructions for getting started with a Bootable USB Flash Drive or Dell [iDRAC](https://en.wikipedia.org/wiki/Dell_DRAC). 

Today I develop this on a [Dell PowerEdge R730xd](https://www.dell.com/en-us/work/shop/cty/pdp/spd/poweredge-r730xd?) with 384GB of DDR4 ECC memory and 32 [Xeon E5-2640 v3](https://ark.intel.com/content/www/us/en/ark/products/83359/intel-xeon-processor-e5-2640-v3-20m-cache-2-60-ghz.html) cores. My storage is broken into four pieces: 

* 512GB RAID 1 ZFS Pool consisting of two mirrored [Samsung 970 Pro M.2 SSDs](https://www.samsung.com/semiconductor/minisite/ssd/product/consumer/970pro/) used for compute storage.
* 18TB RAID 10 ZFS Pool consisting of 6 [6TB HGST Ultrastar He6 7200RPM](https://www.amazon.com/gp/product/B00GTD3AR2/) hard drives used for file storage. 
* 6TB RAID 10 Hardware Raid consisting of 6 [2TB HGST Ultrastar He6 7200RPM](https://www.amazon.com/HGST-Ultrastar-7K3000-7200rpm-0F12455/dp/B004Q3QMA4) hard drives exposed via LVM in Proxmox and used for additional file storage as well as backups, templates, etc in Proxmox. 
* 16GB [Dell K9R5M SATADOM](https://www.dell.com/support/manuals/ae/en/aebsdt1/poweredge-r630/satadom%20techsheet_pub/installing-and-removing-satadom?guid=guid-c0fcfb66-a046-4fdf-9add-fcc9d511635d&lang=en-us) for Proxmox

### Software

I'm able to use all of the tooling here from both MacOS and Arch Linux. It will probably work on Windows too. An understanding of how to use the following tools will be helpful, but hopefully not necessary with the documentation.

* [Proxmox](https://www.proxmox.com/en/)
* [Containerization](https://en.wikipedia.org/wiki/OS-level_virtualization)
* [Kubernetes](https://en.wikipedia.org/wiki/Kubernetes)
* [Kustomize](https://kustomize.io/)
* [Ansible](https://www.ansible.com/)
* [Terraform](https://www.terraform.io/)
<hr>

## Getting Started

Clone this repository to retrieve the submodules below. This repository is treated like a *Release* and each Submodule should reflect the most current stable commit from each project. You can review the `master` branch for each project for additional unstable updates if desired. Detailed instructions for how to use each project is located in the respective README.

The `./inventory.yml` file at the root of this repository is used for Ansible in each of the submodules. Be sure to modify it as per your environment before starting.

| Name                                                         | Description                                                  |
| ------------------------------------------------------------ | ------------------------------------------------------------ |
| [TKS-Bootstrap_Proxmox]( https://github.com/zimmertr/TKS-Bootstrap_Proxmox) | * Prepare iDRAC or a Bootable USB Device<br />* Provision and Configure Proxmox VE<br />* Initialize Storage & Clustering |
| TKS-Build_Template                                           | * Build a VM template with Ansible                           |
| [TKS-Bootstrap_Kubernetes](https://github.com/zimmertr/TKS-Bootstrap_Kubernetes) | * Deploy HAProxy with Terraform to load balance K8s<br />* Deploy Kubernetes Cluster with Terraform<br />* Deploy Calico CNI Plugin |
| [TKS-Deploy_Kubernetes_Apps](https://github.com/zimmertr/TKS-Deploy_Kubernetes_Apps) | * Deploy Kubernetes apps like MetalLB, Istio, etc.<br />* Deploy enterprise apps like Jira, OpenVPN, etc.<br />* Deploy homelab apps like Plex, ruTorrent, Sonarr, etc.<br /><br />* Leverage Kustomize when possible, Ansible when not<br />* Support for Istio, External Secrets, resource management, etc.<br />* Lean on NFS & ZFS for Persistent Volumes |
| [TKS-Deploy_Harbor](https://github.com/zimmertr/TKS-Deploy_Harbor) | * Deploy Harbor with Terraform<br />* Leverage LetsEncrypt to receive a valid SSL Certificate<br />* Integrate with Kubernetes to self host container images |
| [TKS-Deploy_Grafana](https://github.com/zimmertr/TKS-Deploy_Grafana) | * Deploy Grafana with Terraform<br />* Configure Kubernetes to ship logs<br />* Configure other apps to ship logs |
| TKS-Deploy_Vault                                             | * Deploy Vault with Terraform<br />* Configure Vault to act as a secret store for Kubernetes |
| TKS-Deploy_Argo                                              | * Deploy Argo with Terraform<br />* Configure Argo to perform continuous delivery for Kubernetes |
| TKS-Deploy_Gitlab                                            | * Deploy Gitlab with Terraform<br />* Configure Gitlab to manage continuous integration for Kubernetes |
<hr>


## Frequently Asked Questions

**Q: Where did the older Ansible/QEMU based project go?**

I retired that project in favor of TKS. You can find the code [here](https://github.com/zimmertr/Bootstrap-Kubernetes-with-QEMU), however. 

**Q: Why did you choose Debian instead of X?**

* Debian is stable and easy to configure
* I [tried](https://github.com/Telmate/terraform-provider-proxmox/issues/208#issuecomment-703230173) to use Flatcar first unsuccessfully
* CentOS is enterprisey
* If you're still opposed, consider adding a PR with support for another OS? :) 

**Q: Why did you expose configuration through environment variables?**

IaC and CaC tooling usually expose configuration through variables files, so I understand why you might ask that. My goal in exposing configuration through environment variables was to better support CI/CD with this tooling. 

**Q: Why didn't you use X? Why aren't you using Y?**

Consider opening an issue informing me why you think that.

**Q: Why do you make things so complicated?**

It's fun. TKS is developed as a hobby. 

**Q: I found an issue! How should I notify you?**

Please file a GitHub issue under the respective subproject. Please do not email me for support until you have initiated the issue process on GitHub. Pull requests are also welcome and encouraged. :) 

**Q: What are some ways that I can contribute?**

- Add support for additional types of storage
- Add support for multiple Proxmox nodes
- Add support for alternative network configurations
- Improve Terraform & Ansible code quality
- Submit your Kustomize overlays as an example for others
