plugin "terraform" {
  enabled = true
  preset  = "recommended"
}

# No provider plugins exist for bpg/proxmox or namecheap/namecheap.
# The terraform plugin above still catches: unused variables/locals/outputs,
# deprecated syntax, missing required_version, and naming issues.
