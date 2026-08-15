# Hardware

Physical specifications for `pve1`, the single-node Proxmox host running the homelab.

Captured 2026-08-14 from a live host (`dmidecode`, `lscpu`, `lspci`, `smartctl`).

## System

| Field | Value |
|-------|-------|
| Model | Dell OptiPlex 7040 (Micro form factor -- SODIMM memory, `T`-series CPU) |
| Chassis type | Desktop (per SMBIOS) |
| Service tag / serial | `CGH7HB2` |
| System SKU | `06B9` |
| System UUID | `4c4c4544-0047-4810-8037-c3c04f484232` |
| Motherboard | Dell `096JG8` rev A00 |
| Board serial | `/CGH7HB2/CN72200645021M/` |
| Chipset | Intel Q170 |
| Hostname | `pve1` |

## BIOS

| Field | Value |
|-------|-------|
| Vendor | Dell Inc. |
| Version | 1.15.5 |
| Release date | 2019-07-19 |
| ROM size | 16 MB |
| Boot mode | UEFI (ESP on `nvme0n1p2`) |

Dell has published later 7040 BIOS revisions carrying newer CPU microcode. See
[Known Limitations](#known-limitations).

## CPU

| Field | Value |
|-------|-------|
| Model | Intel Core i5-6500T @ 2.50 GHz |
| Microarchitecture | Skylake (family 6, model 94, stepping 3) |
| Cores / threads | 4C / 4T (no Hyper-Threading) |
| Base / max clock | 2.50 GHz / 3.10 GHz (SMBIOS reports 4200 MHz ceiling) |
| TDP class | 35 W (`T` low-power SKU) |
| L1d / L1i | 128 KiB / 128 KiB (4 instances each) |
| L2 / L3 | 1 MiB (4 instances) / 6 MiB shared |
| Virtualization | VT-x, EPT, VPID, `flexpriority` |
| Notable ISA | AES-NI, AVX2, RDRAND, RDSEED, BMI1/2, MPX, Intel PT |
| Address sizes | 39-bit physical, 48-bit virtual |
| Scaling governor | `performance` |
| NUMA | Single node, CPUs 0-3 |

Hyper-Threading is disabled -- the kernel reports `SMT disabled`, which is what
lets the L1TF / MDS / MMIO mitigations report clean.

## Memory

| Field | Value |
|-------|-------|
| Installed | 16 GB (`MemTotal` 16263312 kB) |
| Slots | 2x SODIMM -- **DIMM1 populated, DIMM2 empty** |
| Max supported | 32 GB (per SMBIOS type 16) |
| ECC | None |
| Module | G.Skill `F4-3200C22-16GRS`, 16 GB, DDR4, single rank, 1.2 V |
| Rated speed | 3200 MT/s |
| Actual speed | **2133 MT/s** -- Skylake memory controller ceiling |
| Swap | 2 GB (`pve-swap` LV) |

Memory is the binding constraint on this host. See [Known Limitations](#known-limitations).

## Storage

### Internal -- boot and VM storage

| Field | Value |
|-------|-------|
| Device | Samsung SSD 980 500 GB NVMe (`nvme0n1`) |
| Controller | Samsung NVMe SSD Controller 980, **DRAM-less** |
| Serial | `S64ENU0T817561E` |
| Firmware | `3B4QFXO7` |
| Capacity | 500,107,862,016 bytes (465.8 GiB) |
| Interface | PCIe, `02:00.0` |

SMART health at capture time:

| Metric | Value |
|--------|-------|
| Percentage used | 9% |
| Available spare | 100% |
| Power-on hours | 4,301 |
| Power cycles | 56 |
| Unsafe shutdowns | 30 |
| Data written | 26.5 TB |
| Data read | 174 TB |
| Media / data integrity errors | 0 |
| Temperature | 52 C |

Layout -- LVM on `nvme0n1p3`, volume group `pve`:

| Volume | Size | Role |
|--------|------|------|
| `pve-root` | 96 GB ext4 | `/` (64% used) |
| `pve-swap` | 2 GB | swap |
| `pve-data` | 337.9 GB | LVM-thin pool for VM disks (58.8% data, 2.6% metadata) |
| `nvme0n1p2` | 1 GB vfat | `/boot/efi` |
| VG free | 22 GB | unallocated |

### External -- USB SSD

| Field | Value |
|-------|-------|
| Device | 931.5 GB USB SSD (`PSSD8`) |
| Bridge | Realtek RTL9210 M.2 NVMe adapter (`0bda:9210`) |
| Attachment | **USB-passed through to VM 100 (immich)**, not host-managed |
| Guest mount | `/mnt/external-ssd` (fuseblk), 549 GB used / 383 GB free |

`/mnt/usb-backup` is declared as a PVE `dir` storage for backups but is
**not currently a mountpoint** on the host.

## Graphics

| Field | Value |
|-------|-------|
| GPU | Intel HD Graphics 530 (`00:02.0`, rev 06) |
| Type | Integrated (Skylake GT2) |
| Capability | Quick Sync -- H.264/HEVC hardware encode+decode |

Not currently passed through to any guest.

## Networking

| Interface | Hardware | Driver | State |
|-----------|----------|--------|-------|
| `nic0` | Intel I219-LM Gigabit (`00:1f.6`) | `e1000e` 0.8-4 | UP, 1000 Mb/s full duplex, `192.168.2.50/24` |
| `wlp3s0` | Intel Wi-Fi 6 AX200 (`03:00.0`) | `iwlwifi` | DOWN, no carrier, holds `192.168.4.1/24` |
| `vmbr0` | Linux bridge, `bridge-ports none` | -- | UP, `10.10.10.1/24` |
| `tailscale0` | Tailscale WireGuard | -- | UP |

MAC addresses: `nic0` `18:66:da:10:41:b1`, `wlp3s0` `3c:21:9c:53:30:04`.

`vmbr0` is a host-internal NAT bridge with no physical uplink port; guests
`tap100i0` / `tap103i0` / `tap105i0` attach to it. Bluetooth is present via the
AX200 combo module (`8087:0029`).

For addressing, DHCP reservations, NAT rules and tunnel config see
[NETWORK.md](NETWORK.md).

## USB devices

| Device | ID | Assignment |
|--------|----|------------|
| Realtek RTL9210 M.2 NVMe adapter | `0bda:9210` | passed to VM 100 (`immich`) |
| QinHeng CH340 serial converter | `1a86:7523` | passed to VM 103 (`haos-16.3`) |
| Intel AX200 Bluetooth | `8087:0029` | host |

Both passthroughs are pinned by vendor:product ID in the VM configs, so
re-plugging into a different port is safe but swapping in same-ID hardware is not.

## Thermals

| Sensor | Reading |
|--------|---------|
| CPU package (`x86_pkg_temp`) | 52 C |
| PCH (`pch_skylake`) | 72 C |
| ACPI zones | 27 C / 29 C |
| Wi-Fi module | 47 C |
| NVMe | 52 C |

Idle-ish readings at load average ~0.9. The PCH running 20 C above the package is
normal for this chassis.

## Hypervisor

| Field | Value |
|-------|-------|
| Product | Proxmox VE 9.1.1 (`proxmox-ve` 9.1.0) |
| Kernel | 6.17.2-1-pve |
| Cluster | Standalone -- no cluster membership |
| Microcode | `intel-microcode` 3.20250812.1~deb13u1 |
| Boot | UEFI |

### Storage backends

| Name | Type | Path / target | Content |
|------|------|---------------|---------|
| `local` | dir | `/var/lib/vz` | backup, iso, vztmpl, import |
| `local-lvm` | lvmthin | `pve/data` | rootdir, images |
| `usb-backup` | dir | `/mnt/usb-backup/vzdump` | backup (not mounted) |

### Guests

| VMID | Name | vCPU | RAM | Disk | Boot | Autostart |
|------|------|------|-----|------|------|-----------|
| 100 | `immich` | 4 (`host`) | 4 GB | 64 GB | SeaBIOS | yes |
| 103 | `haos-16.3` | 2 (`qemu64`) | 4 GB | 32 GB | OVMF | yes |
| 105 | `k3s` | 4 (`host`) | 8 GB (balloon 8192) | 100 GB | OVMF | yes |
| 106 | `devbox` | 4 (`host`) | 4 GB (balloon 0) | 30 GB | OVMF | no (stopped) |

All guests are `q35` machine type on `virtio` networking attached to `vmbr0`.

## Known Limitations

**Memory is the hard ceiling.** 16 GB installed, ~15.5 GB usable, and running
guests alone are provisioned for 16 GB. At capture the host showed 13 GB used,
only 2.3 GB available, and 1.3 GB of swap already consumed. This is the
overcommit condition behind past k3s OOM kills. DIMM2 is empty and SMBIOS
reports a 32 GB maximum, so a second matching 16 GB SODIMM is the single highest-value
upgrade available. Note the platform will run any new module at 2133 MT/s regardless
of its rating.

**No ECC.** Consumer Skylake platform; memory errors fail silently.

**`vm-105-disk-1` (k3s) is at 94.65% of its thin volume.** The VG has 22 GB free
if it needs extending.

**Single disk, no redundancy.** Every guest lives on one DRAM-less consumer NVMe.
Its 30 unsafe shutdowns against 56 power cycles reflect the outage history in
[TROUBLESHOOTING.md](TROUBLESHOOTING.md). No RAID, no second internal bay in this
chassis.

**BIOS predates several microcode updates.** 1.15.5 is dated 2019-07-19. The
kernel reports `Gather data sampling: Vulnerable: No microcode` -- the only
unmitigated entry. Everything else is mitigated, partly because SMT is off.

**Ethernet is wired but the config expects Wi-Fi.** `/etc/network/interfaces`
comments `nic0` as "no cable currently" and treats `wlp3s0` as the primary uplink
at metric 200; in practice `nic0` is linked at 1 Gb/s with a DHCP lease and
`wlp3s0` is down. The config and reality have diverged -- worth reconciling.

**Passthrough pins the host.** The USB NVMe enclosure and CH340 serial adapter are
bound to guests by USB ID, so those two VMs cannot migrate off this box even if a
second node is added.
