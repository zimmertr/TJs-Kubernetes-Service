# TKS

## Summary

TKS is a collection of projects used to deploy common enterprise and homelab applications to Proxmox VE. 



## Getting Started







## Submodules

| Name                                                         | Description / Key Notes                                      |
| ------------------------------------------------------------ | ------------------------------------------------------------ |
| [TKS-Bootstrap_Proxmox]( https://github.com/zimmertr/TKS-Bootstrap_Proxmox) | * Prepare iDRAC or a Bootable USB Device<br />* Provision and Configure Proxmox VE<br />* Initialize Storage & Clustering |
| [TKS-Bootstrap_Kubernetes](https://github.com/zimmertr/TKS-Bootstrap_Kubernetes) | * Build a VM template with Ansible<br />* Deploy HAProxy with Terraform to load balance K8s<br />* Deploy Kubernetes Cluster with Terraform<br />* Deploy Calico CNI Plugin |
| [TKS-Deploy_Kubernetes_Apps](https://github.com/zimmertr/TKS-Deploy_Kubernetes_Apps) | * Deploy Kubernetes apps like MetalLB, Istio, etc.<br />* Deploy enterprise apps like Jira, OpenVPN, etc.<br />* Deploy homelab apps like Plex, ruTorrent, Sonarr, etc.<br /><br />* Leverage Kustomize when possible, Ansible when not<br />* Support for Istio, External Secrets, resource management, etc.<br />* Lean on NFS & ZFS for Persistent Volumes<br /> |
| [TKS-Deploy_Harbor](https://github.com/zimmertr/TKS-Deploy_Harbor) | * Deploy Harbor with Terraform<br />* Leverage LetsEncrypt to receive a valid SSL Certificate<br />* Integrate with Kubernetes to self host container images |
| TKS-Deploy_Vault                                             | * Deploy Vault with Terraform<br />* Configure Vault to act as a secret store for Kubernetes |
| TKS-Deploy_Argo                                              | * Deploy Argo with Terraform<br />* Configure Argo to perform continuous delivery for Kubernetes |
| TKS-Deploy_Gitlab                                            | * Deploy Gitlab with Terraform<br />* Configure Gitlab to manage continuous integration for Kubernetes |





### FAQ

> **Q:** Where did the older Ansible/QEMU based project go?
>
> **A:** I retired that project in favor of TKS. You can find the code [here](https://github.com/zimmertr/Bootstrap-Kubernetes-with-QEMU), however. 

