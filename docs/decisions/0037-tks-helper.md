# 0037. `bin/manage_nodes` becomes `bin/tks`, which also handles client configs, CSRs, health checks and tokens, without `jq`

- Status: Accepted
- Date: 2026-10-10
- Decider: TJ
- Issues and PRs: #111
- Supersedes: [0023](0023-manage-nodes-returns.md)

## Context

[0023](0023-manage-nodes-returns.md) brought back `bin/manage_nodes` for node removal and rolling reboots, and [0028](0028-manage-nodes-reregister.md) added `reregister`. Setting up a cluster still had manual steps around Terraform:

- Writing the talosconfig and kubeconfig out of Terraform's outputs and merging them by hand, with kubecm or similar.
- Approving kubelet serving CSRs one by one.
- Reading tokens out of `bootstrap/`'s `api_tokens` map with `jq`.

`jq` was a requirement only for those tokens and for the script itself.

## Decision

- `bin/manage_nodes` is renamed `bin/tks`. It is still run by hand, and still talks to the cluster only through Terraform outputs, `talosctl`, `kubectl` and the Proxmox API. There are no provisioners and no SSH.
- New commands:
  - `config` merges the cluster's talosconfig into `~/.talos/config` and its kubeconfig into `~/.kube/config`. Entries from an earlier build of the same cluster are replaced, and other clusters' entries are kept.
  - `approve-csrs` approves a pending kubelet-serving CSR only if it comes from `system:node:<name>` and its SANs are exactly that node's hostname and IP. This is the check kubelet-csr-approver makes.
  - `doctor` makes read-only checks: the Proxmox API, each VM's state, each node's Talos and Kubernetes versions against the tfvars, Ready, etcd membership against the control planes, `/dev/dri/renderD*` on GPU nodes, and `talosctl health`.
  - `token USER` prints one user's token from `bootstrap/`.
- The script needs no JSON parser:
  - Each root has a `tks` output with one fact per line: the cluster's name and versions plus one line per node, or one line per user and token in `bootstrap/`.
  - The two Proxmox API fields it needs are read with `sed`.
  - `openssl` reads the CSRs' SANs.
- If the workspace has no `tks` output, `tks` stops. That usually means the backend isn't configured, and Terraform fell back to an empty local state.

## Evidence

All on `test` on 2026-10-10:

- `doctor` passed 11 checks. With an unreachable Proxmox endpoint, it reported `FAIL` for the API and the VMs and exited 1.
- In a clone with no backend configured, `tks doctor` stopped with "Workspace default has no TKS cluster".
- `config` was tested against a stand-in home directory that had another cluster's entries and stale `test` entries, with `test` as the current context.
  - The other entries were kept, and both stale ones were replaced.
  - A second run left exactly one `test` context.
  - The new files were mode 600.
  - An unreadable kubeconfig made it fail and leave the file unchanged.
- `approve-csrs` was given two CSRs created as `system:node:test-k8s-node-1`. It approved the one asking for `DNS:test-k8s-node-1, IP:192.168.40.61`, and refused the one that also asked for `192.168.40.99`.
- After `tks reboot test-k8s-node-1`, no CSR was created. The kubelet kept serving the certificate issued that morning, because a Talos reboot keeps the kubelet's certificate on disk. So `reboot` and `reregister` don't wait to approve CSRs.
- `reboot` and `reregister` of `test-k8s-node-1` completed as before. `remove` of an unknown node was a no-op.
- `token` printed the right token from a stand-in `bootstrap/` with the same output shape, also with `TF_WORKSPACE` set to the cluster's workspace. For an unknown user, it listed the users that exist.

## Alternatives rejected

- A wrapper around `terraform plan` and `apply` that pairs each workspace with its tfvars. It would hide Terraform for one benefit.
- An etcd snapshot command. `talosctl etcd snapshot` is already one step.
- Installing the cluster's add-ons. TKS doesn't know what runs on the clusters it builds.
- Keeping `jq`, or parsing `nodes` and `api_tokens` as JSON in shell. A line-per-fact output is simpler to read reliably.

## Consequences

- Any script or habit that calls `bin/manage_nodes` breaks, so this releases as a major version.
- `openssl` replaces `jq` in the requirements.
- An existing cluster's state gets the `tks` output on its next apply, which changes only outputs. Until then, `tks` refuses to run on it.
