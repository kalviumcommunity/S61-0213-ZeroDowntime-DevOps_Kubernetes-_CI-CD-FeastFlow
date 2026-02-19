# Linux Basics for DevOps

## Purpose

This module covers fundamental Linux concepts essential for DevOps practices in the FeastFlow project. While we develop on Windows, our deployment environment runs on Linux (WSL, containers, and CI/CD runners).

## Why Linux for DevOps?

- **Production Environment**: Most cloud services and containers run Linux
- **CI/CD Pipelines**: GitHub Actions, Jenkins, GitLab CI run on Linux runners
- **Containerization**: Docker containers are typically Linux-based
- **Kubernetes**: Orchestrates Linux containers in production

## What You'll Learn

1. **Linux Filesystem Structure** (`filesystem-notes.md`)
   - Where configs, logs, and application artifacts live
   - Standard Linux directory conventions
   - Debugging real-world scenarios

2. **Permissions and Ownership** (`scripts/permissions_demo.sh`)
   - Understanding `chmod` and `chown`
   - Reading `ls -l` output
   - Securing configuration files
   - Setting appropriate log file permissions

3. **Process and Network Inspection** (`scripts/process_network_check.sh`)
   - Finding running processes with `ps`
   - Checking listening ports with `ss`/`netstat`
   - Identifying what's using a specific port with `lsof`

## Running the Scripts

All scripts are designed to be safe and non-destructive. They use `/tmp` for demonstrations.

### Prerequisites

- Linux environment (WSL, Linux VM, or native Linux)
- Bash shell
- Root/sudo access (for some operations)

### Execute Scripts

```bash
# Make scripts executable
chmod +x devops/linux-basics/scripts/*.sh

# Run permissions demo
./devops/linux-basics/scripts/permissions_demo.sh

# Run process/network check
./devops/linux-basics/scripts/process_network_check.sh
```

## CI/CD Integration

The GitHub Actions workflow `.github/workflows/linux-ops-demo.yml` automatically validates these scripts on every push, ensuring they work correctly in a real Linux CI environment.

## DevOps Scenarios Covered

- **Debugging permission errors** in deployment pipelines
- **Investigating why services won't start** due to file access
- **Finding which process** is using a port
- **Checking if a service is listening** on the expected port
- **Understanding filesystem layout** to locate logs during incidents

## Resources

- [Linux Filesystem Hierarchy Standard](https://refspecs.linuxfoundation.org/FHS_3.0/fhs/index.html)
- [Linux Permissions Explained](https://www.linux.com/training-tutorials/understanding-linux-file-permissions/)
- [man pages](https://man7.org/linux/man-pages/)

---

**Note**: These examples are educational. Always follow your organization's security policies when managing real production systems.
