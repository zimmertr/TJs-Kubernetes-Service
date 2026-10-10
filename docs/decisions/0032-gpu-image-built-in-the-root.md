# 0032. The GPU pool's Talos image is built in the root, beside the general one

- Status: Accepted
- Date: 2026-10-10
- Decider: TJ
- Issues and PRs: #89

## Context

T27 planned for `modules/gpu_worker` to build its own Talos image. But every node's first patch is `configs/global.yaml`, rendered by the root with the pool's installer image, and `talos_machine` upgrades each node from that image. A module that owned the image would have had to render the root's patch templates itself.

## Decision

The root calls `modules/talos_image` a second time as `module.gpu_image` (pool `gpu`, with `gpu_workers.extensions`), with `count = 0` when there are no GPU nodes. It renders the GPU nodes' patches with that image's installer, like the general pool's. `modules/gpu_worker` takes the image as an input and covers the PCI lookup, the mapping and the VMs.

## Evidence

- `tests/cluster.tftest.hcl` (`gpu_workers_get_their_own_image_taint_and_label`) checks that GPU nodes install from the GPU image and not the general one.

## Alternatives rejected

- Building the image in `gpu_worker`: it would need `global.yaml` split, so that the installer document could be rendered separately from the patches that don't depend on an image.

## Consequences

Every pool's image is built the same way, in one place. The patches every node gets, apart from `global.yaml`, are kept in `local.shared_patches`, so a new pool only renders `global.yaml` with its own installer.
