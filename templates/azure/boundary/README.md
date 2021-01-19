# Boundary

Creates an image to run a [Boundary](https://www.boundaryproject.io/) controller or worker.

This will configure a systemd service called `boundary` that is enabled to start on boot.
Read the [Boundary Documentation](https://www.boundaryproject.io/docs/installing/systemd) for details about
the user and systemd configuration. The service expects a configuration file to be located at the path
`/etc/boundary-controller.hcl`. The configuration file can be created with a cloud init file.
```yaml
#cloud-config
write_files:
- content: |
  path: /etc/boundary-controller.hcl
```

Refer to the [Configuration Documentation](https://www.boundaryproject.io/docs/configuration) for details
about what options to set.
