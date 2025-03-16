# Infrastructure Automation Framework Documentation

Welcome to the Infrastructure Automation Framework documentation. This directory contains additional documentation and guides for using the framework.

## Available Documentation

### Quick References

- [Quick Reference Guide](QUICK_REFERENCE.md) - One-liners and essential commands

### Installation and Setup

- [Installation Guide](../INSTALL.md) - Complete installation instructions
- [Client Device Setup](../client-devices/README.md) - Configure laptops, tablets, and mobile devices

### Core Infrastructure

- [Tier 1 Core Infrastructure](../tier1-core/README.md) - Base network and security infrastructure
- [Log Management](../tier2-services/log_management/README.md) - Centralized logging infrastructure
- [Logging Best Practices](../tier2-services/log_management/LOGGING_BEST_PRACTICES.md) - Guidelines for logging

## Repository Structure

The Infrastructure Automation Framework is organized into logical tiers:

- **Tier 0**: Discovery and assessment (`tier0-discovery/`)
- **Tier 1**: Core infrastructure (`tier1-core/`)
- **Tier 2**: Essential services (`tier2-services/`)
- **Client Devices**: End-user device setup (`client-devices/`)

## Getting Help

For more information, refer to the main [README.md](../README.md) or use the controller's help command:

```bash
python controller.py help
``` 