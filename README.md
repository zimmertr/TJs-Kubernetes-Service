# TKS

As infrastructure becomes more and more abstracted from the user, it becomes both easier to work with and harder to manage. Hypervisors, containers, orchestration platforms, etc. Cloud providers today manage to automate this complexity at scale for millions of enterprise customers.  TKS is a collection of projects to provide a similar experience with bare metal. 



## Summary

TKS is broken up into submodules as each component can be used independently. When used together, however, they produce a platform that leverages:

* Proxmox VE for virtualization 
* ZFS for backing storage 
* Kubernetes for running container-compataible applications 
* HAProxy to ensure high availability for Kubernetes 
* Kustomize for configuring & deploying applications to Kubernetes 
* Istio for managing ingress and other layer 7 networking
* Grafana for monitoring and alerting
* Vault for secrets management
* Gitlab for source control and continuous integration
* ArgoCD for continuous delivery
* Harbor for publishing container images



## Requirements

TKS requires a server, some storage, and an understanding of how to network everything together. You don't need much for a server, I ran all of this happily on a 2008 Mac Pro for years. It would probably even run in the cloud if you were crazy enough. 



I use MacOS and Arch Linux to deploy all of this happily, so all of the tooling works well on those platforms. I imagine you can use this from Windows too. 



A working understanding of the following topics will also be useful:

* [Proxmox](https://www.proxmox.com/en/)
* [Containerization](https://en.wikipedia.org/wiki/OS-level_virtualization)
* [Kubernetes](https://en.wikipedia.org/wiki/Kubernetes)
* [Kustomize](https://kustomize.io/)
* [Ansible](https://www.ansible.com/)
* [Terraform](https://www.terraform.io/)





## Getting Started

Clone this repository to retrieve the submodules below. Review their documentation for information. 

| Name                                                         | Description                                                  |
| ------------------------------------------------------------ | ------------------------------------------------------------ |
| [TKS-Bootstrap_Proxmox]( https://github.com/zimmertr/TKS-Bootstrap_Proxmox) | * Prepare iDRAC or a Bootable USB Device<br />* Provision and Configure Proxmox VE<br />* Initialize Storage & Clustering |
| [TKS-Bootstrap_Kubernetes](https://github.com/zimmertr/TKS-Bootstrap_Kubernetes) | * Build a VM template with Ansible<br />* Deploy HAProxy with Terraform to load balance K8s<br />* Deploy Kubernetes Cluster with Terraform<br />* Deploy Calico CNI Plugin |
| [TKS-Deploy_Kubernetes_Apps](https://github.com/zimmertr/TKS-Deploy_Kubernetes_Apps) | * Deploy Kubernetes apps like MetalLB, Istio, etc.<br />* Deploy enterprise apps like Jira, OpenVPN, etc.<br />* Deploy homelab apps like Plex, ruTorrent, Sonarr, etc.<br /><br />* Leverage Kustomize when possible, Ansible when not<br />* Support for Istio, External Secrets, resource management, etc.<br />* Lean on NFS & ZFS for Persistent Volumes |
| [TKS-Deploy_Harbor](https://github.com/zimmertr/TKS-Deploy_Harbor) | * Deploy Harbor with Terraform<br />* Leverage LetsEncrypt to receive a valid SSL Certificate<br />* Integrate with Kubernetes to self host container images |
| TKS-Deploy_Grafana                                           | * Deploy Grafana with Terraform<br />* Configure Kubernetes to ship logs<br />* Configure other apps to ship logs |
| TKS-Deploy_Vault                                             | * Deploy Vault with Terraform<br />* Configure Vault to act as a secret store for Kubernetes |
| TKS-Deploy_Argo                                              | * Deploy Argo with Terraform<br />* Configure Argo to perform continuous delivery for Kubernetes |
| TKS-Deploy_Gitlab                                            | * Deploy Gitlab with Terraform<br />* Configure Gitlab to manage continuous integration for Kubernetes |





### FAQ

> **Q:** Where did the older Ansible/QEMU based project go?
>
> **A:** I retired that project in favor of TKS. You can find the code [here](https://github.com/zimmertr/Bootstrap-Kubernetes-with-QEMU), however. 

> **Q:** Why do you make things so complicated?
>
> **A:** It's fun.

> **Q:** I found and issue! How should I notify you?
>
> **A:** Please file a GitHub issue under the respective subproject. Please do not email me for support until you have initiated the issue process on GitHub. 

> **Q:** What are some ways that I can contribute?
>
> **A:** Adding better support for multiple Proxmox nodes, storage types, network configurations, etc.
>
> **A2:** Improving Terraform & Ansible code quality. 
>
> **A3:** Submitting your Kustomize overlays as an example for others!