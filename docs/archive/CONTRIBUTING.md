# Contributing Guidelines

Guidelines for making changes to the homeserver infrastructure.

## Making Changes

### 1. Create a Branch

```bash
git checkout -b feature/add-jellyfin
```

### 2. Make Your Changes

Edit the relevant files:
- `terraform/*.tf` - Infrastructure changes
- `ansible/playbooks/*.yml` - Service configuration

### 3. Test Locally

```bash
# Preview infrastructure changes
cd terraform
terraform plan

# Test Ansible playbooks
cd ../ansible
ansible-playbook playbooks/your-playbook.yml --check
```

### 4. Commit

```bash
git add .
git commit -m "Add Jellyfin media server"
```

### 5. Create Pull Request

If using GitHub/GitLab, create a PR for review.

## Commit Message Format

Use clear, descriptive commit messages:

**Good:**
- "Add 2GB RAM to Immich VM"
- "Create Jellyfin VM with 4 cores and 8GB RAM"
- "Update Nginx Proxy Manager to v2.10"
- "Fix disk size for Home Assistant"

**Bad:**
- "Update stuff"
- "Fix things"
- "Changes"

## Code Style

### Terraform

```hcl
# Use consistent formatting
terraform fmt

# Validate before committing
terraform validate
```

### Ansible

```yaml
# Use 2-space indentation
# Use descriptive task names
- name: Install Docker
  apt:
    name: docker.io
    state: present
```

## Testing Checklist

Before committing:

- [ ] `terraform fmt` run
- [ ] `terraform validate` passes
- [ ] `terraform plan` shows expected changes only
- [ ] `ansible-playbook --syntax-check` passes
- [ ] Changes tested on non-production VM (if possible)
- [ ] Documentation updated
- [ ] No secrets in commit

## Review Process

1. Run `terraform plan` and share output
2. Peer review changes
3. Apply to test environment
4. If successful, apply to production
5. Monitor for issues

## Rollback Procedure

If something breaks:

```bash
# Revert git commit
git revert HEAD

# Re-apply infrastructure
cd terraform
terraform plan
terraform apply

# Or restore from backup
ssh root@192.168.2.50 "qmrestore /path/to/backup.vma.zst <vmid>"
```

## Security

Never commit:
- API tokens
- Passwords
- Private keys
- `terraform.tfvars`
- `terraform.tfstate` (should be in gitignore)

Always commit:
- Infrastructure definitions
- Ansible playbooks
- Documentation
- Example files (*.example)

## Questions?

Ask Claude Code! It knows the infrastructure and can help with:
- Syntax questions
- Best practices
- Troubleshooting
- Code review
