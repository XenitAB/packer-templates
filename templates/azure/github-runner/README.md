# GitHub Self-hosted Runner

Packer template for GitHub Self-hosted runner.

## Cloud-init

```YAML
#cloud-config
write_files:
- content: |
    {
      "AZURE_KEYVAULT_NAME": "kvname",
      "GITHUB_ORGANIZATION_KVSECRET": "github-organization",
      "GITHUB_APP_ID_KVSECRET": "github-app-id",
      "GITHUB_INSTALLATION_ID_KVSECRET": "github-installation-id",
      "GITHUB_PRIVATE_KEY_KVSECRET": "github-private-key"
    }
  path: /etc/github-runner/github-runner-config.json
```

## Permissions

Make sure the VM / VMSS identity has read access (get) to the Azure KeyVault Secrets.
