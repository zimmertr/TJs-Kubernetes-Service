# 0022. The machine secrets ignore later `talos_version` changes instead of refusing to be destroyed

- Status: Accepted
- Date: 2026-10-09
- Decider: Claude, while validating v2 on `test` (T23)
- Issues and PRs: T23, the TKS v2 PR

## Context

[0011](0011-in-place-upgrades-by-terraform.md) put `prevent_destroy` on `talos_machine_secrets`, so that lowering `talos_config_version` could not replace the secrets and regenerate the cluster's PKI.

## Decision

`talos_machine_secrets` has `lifecycle { ignore_changes = [talos_version] }` and no `prevent_destroy`. The secrets keep the contract version they were created with. The rest of 0011 stands.

## Evidence

- 2026-10-09: `terraform destroy` of the v2 `test` cluster failed with "Instance cannot be destroyed". `prevent_destroy` blocks every destroy, not only a replacement, so no v2 cluster could be destroyed without editing code.
- `talos_version` is the only argument of `talos_machine_secrets` that TKS changes after creation, and lowering it is what forces a replacement (0011, Evidence).

## Alternatives rejected

- Keep `prevent_destroy` and document `terraform state rm` before a destroy: it's a manual step that leaves the secrets out of state for good.

## Consequences

- `terraform destroy` works.
- Lowering `talos_config_version` no longer replaces the secrets. It only changes the generated machine config, and the variable's validation still keeps it at or below `talos_version`.
