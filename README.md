Step 1) Modify the vars files with values specific to your environment and desires.
Step 2) Provision internal DNS A records for the IP Addresses & hostnames you defined for your nodes.
Step 3) `ansible-playbook -e @Vars/vars.yml -i Inventories/Kubernetes_LXC.ini site.yml`
Step 4) ???
Step 5) Profit
