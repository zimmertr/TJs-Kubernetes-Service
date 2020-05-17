TODO
    1) Finalize TKS Planning
        - Push up all repos
        - Migrate older projects
        - Configure all submodules
    2) Recover all data from Mac Pro
    3) Install Proxmox on Mac Pro
    4) Finish configuring R730
        - Install iDRAC Service Module
        - Configure:
            - SMTP
            - Networking
            - Alerts & Notifications
    5) Develop TKS-Bootstrap_Proxmox
        - Solve State Management
    6) Reinstall Proxmox on both hosts and provision with CaC.
    7) Rename SaturnPool to DataPool
    8) Develop TKS-Build_Template
    9) Build VM Templates
    10) Develop TKS-Deploy_Vault
    11) Rekey entire infrastructure using Vault
    12) Develop TKS-Deploy_HAProxy
    13) Develop TKS-Deploy_Kubernetes
    14) Refactor TKS-Kubernetes_Manifests repo
    15) Build/Plan network diagram including Firewalls, VLANs, Storage, Applications, HA, etc
    16) Document everything
    17) Harden Infrastructure
        - iDRAC IPMI only accessible from LAN
        - DMZ VLAN (OpenVPN, public HAProxy?)
    18) Finish refactoring Kubernetes Manifests with Istio & OpenEBS
    19) Deploy OpenVPN
    20) Forward Ports


Home Lab:
    - Clean Up PowerDNS
    - Build Network Diagram depicting:
        - Storage Use Cases
        - Networking
            - Firewalls
            - VLANs
            - DMZ

R730xd:
    - Write Temp Monitoring Script
    - Script to adjust fan speeds based on temp
    - Script to shut off server based on temp
    - Script to perform ZFS Scrubs

ZFS:
    - Add SSD-Based ZFS Intent Logs in 2.5" bays

Odroids:
    - Update
    - Install SSH Keys
    - Configure SMTP to alert on:
        - Package Updates
        - Available Free Space
        - Container Status Changes

VMs:
    - 3x Kubernetes Master
    - 3x Kubernetes Node
    - HAProxy
    - OpenVPN
    - Vault
    - Grafana
    - Prometheus
    - InfluxDB
    - MacOS Catalina
    - Windows Server 2019
    - Windows XP SP3
    - Windows 10
    - FreeBSD

Kubernetes:
    - Website
    - Blog
    - Plex
    - Deluge
    - Radarr
    - Sonarr
    - Tautulli
    - Jira
    - Confluence
    - Piwigio
    - Gitlab
    - Artifactory
    - Argo CI


3d Print Ideas:
    - Rackmount chassis for Odroids & Switch
    - Case for ESP8266 modules
    - Organizer insert for 2U rackmount drawer. Perfect dimensions
