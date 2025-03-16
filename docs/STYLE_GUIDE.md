# Infrastructure Automation Framework Style Guide

This document outlines the coding and documentation style standards for the Infrastructure Automation Framework repository.

## General Guidelines

- **Consistency**: Follow existing patterns in the codebase
- **Readability**: Prioritize readability over clever code
- **Documentation**: Document public interfaces, complex logic, and non-obvious behavior
- **Simplicity**: Prefer simple solutions over complex ones

## Naming Conventions

### Files and Directories

- **Scripts**: Use lowercase with hyphens (kebab-case)
  - Example: `setup-environment.sh`, `deploy-infrastructure.py`
- **Documentation**: Use UPPERCASE with underscores
  - Example: `README.md`, `INSTALL.md`, `STYLE_GUIDE.md`
- **Modules**: Use lowercase with underscores (snake_case)
  - Example: `log_management`, `network_configuration`

### Code Elements

- **Python Variables/Functions**: Use snake_case
  - Example: `def configure_environment():`, `user_config = {}`
- **Python Classes**: Use PascalCase (CapitalizedWords)
  - Example: `class InfrastructureManager:`
- **Terraform Resources**: Use snake_case
  - Example: `resource "aws_security_group" "bastion_sg" {`
- **Shell Variables**: Use UPPERCASE with underscores
  - Example: `INSTALL_DIR="$HOME/infra"`

## Code Structure

### Shell Scripts

- Start with a shebang line: `#!/bin/bash` or `#!/usr/bin/env python3`
- Include a brief header comment describing the script's purpose
- Define functions before they are used
- Use a `main()` function when appropriate
- Include proper error handling and exit codes

### Python Files

- Follow PEP 8 style guide
- Include docstrings for modules, classes, and functions
- Order imports: standard library, third-party, local modules
- Include type hints when beneficial

### Terraform Files

- Use consistent formatting (run `terraform fmt`)
- Group related resources together
- Use variables for all configurable parameters
- Include descriptive comments for non-obvious blocks
- Follow a standard file structure:
  - `main.tf`: Main resources
  - `variables.tf`: Input variables
  - `outputs.tf`: Output values
  - `versions.tf`: Provider requirements

## Documentation Guidelines

### README Files

- Each directory should have a README.md explaining its purpose
- Include sections: Overview, Usage, Configuration, Examples
- Use code blocks with appropriate language syntax highlighting
- Keep examples concise but complete

### Markdown Standards

- Use ATX-style headers (`#` for top level, `##` for second level)
- Include a table of contents for longer documents
- Use proper list formatting and indentation
- Include links to related documentation
- Use backticks for code, commands, and file paths

## Commit Messages

- Use the imperative mood ("Add feature" not "Added feature")
- Include a brief summary (50 chars or less) as the first line
- Provide more detailed explanation after a blank line, if needed
- Reference issue numbers when applicable

Example:
```
Add client device setup for mobile devices

- Create scripts for Android and iOS setup
- Include documentation for mobile access
- Configure secure access capabilities

Fixes #42
```

## Review Process

- All code should be reviewed before merging
- Ensure code follows this style guide
- Verify documentation is updated alongside code changes
- Check that tests pass (when applicable)
- Ensure commit history is clean and logical 