# Multipass Foundations: A Hands-On Guide to Lightweight Ubuntu VMs

## TL;DR

Multipass lets you create and manage lightweight Ubuntu virtual machines from a simple command line. It provides an isolated local environment for Linux development, reproducible experiments, cloud-native learning, and small multi-node labs. This guide covers installation, instance lifecycle management, resource configuration, networking, architecture considerations, cloud-init, troubleshooting, and cleanup.

## A Living Technical Reference
This article is intentionally designed as a living technical reference. Its core concepts, architecture, and procedures establish a stable foundation for working with Multipass, while additional technical details, operational practices, and relevant use cases may be incorporated over time as the tooling and ecosystem evolve.
The scope remains focused on Multipass fundamentals and practical local infrastructure. Future revisions will extend the article where they provide meaningful technical value, while preserving the original structure and reproducibility of the examples.

## Introduction

Multipass is a command-line tool from Canonical for creating and managing lightweight Ubuntu virtual machines on Linux, macOS, and Windows. It provides a practical local environment for Linux development, infrastructure experiments, reproducible testing, and cloud-native learning.
This article focuses exclusively on Multipass. Kubernetes and MicroK8s are referenced as potential use cases, but they are not installed or configured here.
The examples use Ubuntu 24.04 LTS. Pinning the Ubuntu release makes the tutorial more reproducible; replace 24.04 with another supported image release when required by your environment.
Working with Linux-based tools often requires an environment that is isolated from the host system while remaining easy to create and destroy. Multipass provides this capability locally without requiring a dedicated server or a cloud account. Its CLI allows you to launch Ubuntu instances, configure their resources, access their shells, transfer or mount files, and remove them when the experiment is complete.
The goal of this article is to establish a practical foundation for working with Multipass before moving into more advanced cloud-native scenarios. Once the fundamentals are understood, the same workflow can be extended to create repeatable local environments for development, testing, automation, and Kubernetes-related experimentation.

## Context & Scope

Multipass occupies a practical middle ground between container-based development and full virtualized or cloud infrastructure. Containers generally provide lower overhead and faster startup, while cloud infrastructure provides broader scalability and operational capabilities. Multipass provides isolated Ubuntu virtual machines locally while keeping their creation and lifecycle management relatively simple.
This makes Multipass useful for developers, platform engineers, DevOps practitioners, and engineers who need to experiment with Linux or cloud-native technologies on a workstation. A local Multipass lab can also provide the infrastructure foundation for subsequent MicroK8s, Kubernetes, and observability experiments.
This article is intentionally focused on Multipass. It explains the tool, its instance lifecycle, resource model, networking, file transfer and mounts, automation, architecture considerations, practical use cases, limitations, and common troubleshooting techniques. 

## What you will learn

This guide covers:

1. What Multipass is and how it works
2. Prerequisites
3. Install Multipass
4. Basic commands and instance lifecycle
5. CPU, memory, and disk configuration
6. Networking and VM IP addresses
7. ARM64 versus x86_64 (AMD64)
8. File transfer and mounts between the host and an instance
9. Automate setup with cloud-init
10. Limitations compared with production infrastructure
11. Troubleshooting common issues
12. Cleanup and safe removal

## 1. What Multipass is and how it works

Unlike a container, which shares the host kernel, a Multipass instance is a virtual machine with its own guest operating system, filesystem, kernel, virtual CPUs, memory, and virtual network interfaces. This provides stronger isolation than a container, although it also introduces greater resource overhead.
The multipass command is the client. A background service, the Multipass daemon (multipassd), receives requests from the client and manages the lifecycle of Multipass instances. The daemon is responsible for coordinating operations such as instance creation, startup, networking, and other VM lifecycle operations.

1. downloads or locates an Ubuntu image;
2. creates the instance disk;
3. starts the virtualization backend;
4. configures the virtual network; and
5. initializes the guest operating system.

The backend depends on the host. Current macOS releases commonly use QEMU with Apple's Hypervisor framework, while Linux commonly uses QEMU/KVM and Windows uses its built-in virtualization facilities. Multipass hides most backend details behind one consistent CLI.
The normal instance lifecycle is:

```text
launch -> initialize -> use -> stop/start -> delete -> purge
```

Instance states are more nuanced than this simplified workflow suggests. A running instance can be stopped and later started again; Multipass also supports states such as suspended and deleted.

Stopping an instance preserves its state and data. Deletion removes the instance from active use, while permanent removal depends on the deletion mechanism and the Multipass version in use. Always verify the behavior of the installed Multipass release before treating deletion as recoverable or irreversible.

## 2. Prerequisites

Before installing Multipass, verify that your system meets the basic requirements:

- A supported Linux, macOS, or Windows host.
- Hardware virtualization support appropriate to the host platform.
- Administrator privileges for installation and required system-level network configuration.
- Internet connectivity to download Multipass and Ubuntu images.

Check the current supported operating-system versions in the [official installation documentation](https://documentation.ubuntu.com/multipass/latest/how-to-guides/install-multipass/).

For a single small VM, 8 GB of host memory is normally sufficient. The three-node lab later in this article allocates approximately:

| Instance | CPUs | Memory | Disk |
| --- | ---: | ---: | ---: |
| `master` | 2 | 4 GB | 25 GB |
| `worker1` | 2 | 2 GB | 20 GB |
| `worker2` | 2 | 2 GB | 20 GB |

A host with at least 16 GB of memory is recommended for that lab. On systems with less memory, reduce the VM allocations according to the workload and available host resources.

## 3. Install Multipass

### macOS

Install the current package from the [Multipass macOS download page](https://canonical.com/multipass/download/macos). Homebrew is also available in many environments:

```bash
brew install --cask multipass
```

Multipass uses a private virtual network on macOS. VPNs, firewalls, and DNS proxies can interfere with it.

### Linux

On Ubuntu and many other Linux distributions, install the Snap package:

```bash
sudo snap install multipass
```

If the client reports a socket permission error, inspect the socket and your groups:

```bash
ls -l /var/snap/multipass/common/multipass_socket
groups
```

Log out and in again after changing group membership.

### Windows

Install the current MSI from the [Multipass Windows download page](https://canonical.com/multipass/download/windows). Windows also requires the Virtual Machine Platform feature.

### Verify the installation

```bash
multipass version
multipass help
```

## 4. Basic commands and instance lifecycle

List available images:

```bash
multipass find
```

Create a named instance:

```bash
multipass launch 24.04 --name devbox
```

List and inspect instances:

```bash
multipass list
multipass info devbox
```

Open an interactive shell:

```bash
multipass shell devbox
```

Run a command without opening a shell:

```bash
multipass exec devbox -- hostname
multipass exec devbox -- uname -m
multipass exec devbox -- df -h
```

Use `bash -c` when the command contains shell syntax:

```bash
multipass exec devbox -- bash -c 'echo "Running on $(hostname)"'
```

Control the instance lifecycle:

```bash
multipass stop devbox
multipass start devbox
multipass restart devbox
multipass suspend devbox
```

An instance IP can change after a restart or recreation. Use `multipass list` or `multipass info` whenever you need the current address.

## 5. CPU, memory, and disk configuration

Assign resources at launch time with `--cpus`, `--memory`, and `--disk`:

```bash
multipass launch 24.04 \
  --name buildbox \
  --cpus 4 \
  --memory 6G \
  --disk 40G
```

Useful starting points are:

| Workload | CPUs | Memory | Disk |
| --- | ---: | ---: | ---: |
| Shell experiments | 1 | 1–2 GB | 10 GB |
| Development service | 2 | 2–4 GB | 15–25 GB |
| Build or container host | 2–4 | 4–8 GB | 30–60 GB |
| Small Kubernetes node | 2 | 2–4 GB | 20–30 GB |

Inspect resources inside the guest:

```bash
multipass exec buildbox -- nproc
multipass exec buildbox -- free -h
multipass exec buildbox -- df -h
```

Change resources after creation by stopping the instance first:

```bash
multipass stop buildbox
multipass set local.buildbox.cpus=4
multipass set local.buildbox.memory=8G
multipass set local.buildbox.disk=60G
multipass start buildbox
```

Disk space can be increased, but shrinking disks is not a normal workflow. The guest partition or filesystem may need to be expanded after increasing the virtual disk. Back up important data first.

Read configured values with:

```bash
multipass get local.buildbox.cpus
multipass get local.buildbox.memory
multipass get local.buildbox.disk
```

## 6. Networking and VM IP addresses

Multipass normally assigns each instance a private network interface. The host can usually reach the instance through its IPv4 address, and the instance can reach the internet through the Multipass network.

Find the address from the host:

```bash
multipass list
multipass info buildbox
```

Inspect the guest network:

```bash
multipass exec buildbox -- ip -br address show scope global
multipass exec buildbox -- ip route
```

Test outbound connectivity:

```bash
multipass exec buildbox -- getent hosts ubuntu.com
multipass exec buildbox -- curl -I https://ubuntu.com
```

To test host-to-guest access, install a web server:

```bash
multipass exec buildbox -- bash -c \
  'sudo apt-get update && sudo apt-get install -y nginx'
multipass info buildbox
curl http://<INSTANCE_IP>
```

The service must listen on the VM interface, not only on `127.0.0.1`.

### Bridged networking

The default network is sufficient for most local development. Inspect available host networks before creating a bridged instance:

```bash
multipass networks
multipass set local.bridged-network=en0
multipass launch 24.04 --name bridged-box --network bridged
```

The equivalent shortcut is:

```bash
multipass launch 24.04 --name bridged-box --bridged
```

Launching an instance with --network bridged bypasses Multipass’s internal private NAT network (which normally assigns an isolated IP such as 192.168.252.x). Instead, the virtual machine connects directly to your physical network interface:

Direct LAN Assignment: The instance requests a standard local IP address directly from your router's DHCP server (e.g., 192.168.1.50), appearing on your network just like a physical laptop, phone, or server.

Seamless Local Access: Any device on the same Wi-Fi or Ethernet network can reach services running inside the VM directly via its LAN IP—eliminating the need for port forwarding or complex NAT rules on the host.

Because bridged mode exposes the VM directly to the underlying network and relies on host-level routing, keep the following constraints in mind:

Use Intentionally: Bridged networking broadens the VM's visibility across the local network and often requires platform-specific interface configuration. Use it only when external LAN devices genuinely need direct access to the instance.

Environment Compatibility: Bridging may fail or behave unpredictably across certain Wi-Fi adapters, active VPN tunnels, or strict corporate networks. Similarly, host firewalls and VPN clients can interfere with or block private VM routes.

Dynamic Addressing: Instance IP addresses are typically assigned dynamically via DHCP and may change across reboots unless reserved at the router level.

Lab-Focused Design: Multipass networking is engineered for local development, testing, and lab simulation—not for production ingress, public exposure, or load balancing.


## 7. ARM64 versus AMD64

ARM64, also called `aarch64`, is common on Apple Silicon Macs and ARM servers. AMD64, also called `x86_64`, is common on Intel and AMD computers.

Check the host architecture:

```bash
uname -m
```

Check the guest architecture:

```bash
multipass exec buildbox -- uname -m
multipass exec buildbox -- dpkg --print-architecture
```

An application or image built only for AMD64 may fail on ARM64 with:

```text
exec format error
```

Prefer multi-architecture Ubuntu, package, and container images. On Apple Silicon, check that every binary and container image used by a lab supports ARM64. Emulation may be possible for some workloads, but it can be slower and less predictable.

## 8. Share files between the host and an instance

Mount a host directory into an instance:

```bash
mkdir -p "$HOME/multipass-project"
multipass mount "$HOME/multipass-project" buildbox:/home/ubuntu/project
multipass info buildbox
```

Unmount it when finished:

```bash
multipass unmount devbox:/home/ubuntu/project
```

Avoid mounting over the guest home directory because it contains files needed to access the instance.

For a one-time copy, use `transfer`:

```bash
mkdir tmp
cat << 'EOF' > ./tmp/notes.txt
Hello WORLD!
EOF

multipass exec buildbox -- mkdir tmp
multipass transfer ./tmp/notes.txt buildbox:/home/ubuntu/tmp/notes.txt
multipass exec buildbox -- ls ./tmp
multipass transfer buildbox:/home/ubuntu/tmp/notes.txt ./tmp/notes-from-vm.txt
```

Use mounts for active development and `transfer` for artifacts or occasional backups.

## 9. Automate setup with cloud-init

Cloud-init makes first-boot configuration repeatable. Create `cloud-init.yaml` on the host:

```yaml
#cloud-config
package_update: true
package_upgrade: true

packages:
  - curl
  - git
  - htop
  - nginx

write_files:
  - path: /var/www/html/index.html
    permissions: "0644"
    content: |
      <h1>Configured by cloud-init</h1>

runcmd:
  - systemctl enable --now nginx
```

Launch an instance with the file:

```bash
multipass launch 24.04 \
  --name automation-box \
  --cpus 2 \
  --memory 2G \
  --disk 15G \
  --cloud-init cloud-init.yaml
```

Wait for initialization and inspect the result:

```bash
multipass exec automation-box -- cloud-init status --wait
multipass exec automation-box -- cloud-init status --long
multipass exec automation-box -- systemctl status nginx --no-pager
```

Keep cloud-init files in version control, make scripts idempotent, and never place production passwords or private keys in them. Cloud-init is primarily a first-boot tool, not a replacement for configuration management.

## 10. Limitations compared with production infrastructure

Multipass is a local development and learning tool, not a production platform.

### One physical host

Three virtual machines on one computer do not provide true high availability. A host failure affects every instance.

### Local resource limits

CPU, memory, disk throughput, and network performance are bounded by the host. Oversubscribing resources can make every VM slow.

### Non-production networking

Private IP addresses may change, VPNs can affect routing, and bridged networking requires platform-specific configuration. Do not use a local Multipass address as a production endpoint.

On macOS, additional IP addresses assigned inside an instance may not be reachable from the host network. This can affect designs that depend on multiple advertised addresses or bare-metal load balancers.

### Local storage and backups

Instance disks live on the host and are not automatically replicated or backed up. Export important data explicitly.

### Operational and security responsibilities

Multipass does not provide production identity management, secrets management, network policy, centralized logging, backups, or incident response. Use a properly designed cloud or datacenter platform for production workloads.

## 11. Troubleshooting common issues

### Socket or certificate errors

Start with:

```bash
multipass version
multipass list
```

On Linux, check socket permissions:

```bash
ls -l /var/snap/multipass/common/multipass_socket
groups
```

On macOS, certificate errors can look like:

```text
cannot connect to the multipass socket
SSL_ERROR_SSL: certificate verify failed
```

Inspect certificate dates when the file exists:

```bash
openssl x509 \
  -in "$HOME/Library/Application Support/multipass-client-certificate/multipass_cert.pem" \
  -noout -subject -dates
```

Upgrade Multipass with the official installer or package manager. Do not delete Multipass data directories while troubleshooting.

### Launch timeout or unknown state

A timeout does not always mean the instance was not created:

```bash
multipass list
multipass info <INSTANCE_NAME>
multipass exec <INSTANCE_NAME> -- cloud-init status --long
```

Use verbose output for another attempt:

```bash
multipass launch -vvvv 24.04 --name diagnostic-box
```

Increase the timeout for slow downloads or initialization:

```bash
multipass launch 24.04 --name slow-box --timeout 900
```

### `qemu-img` or image preparation failure

Check the Multipass version, host disk space, image architecture, and available updates. Upgrade Multipass before deleting anything. A failed launch can leave an instance record behind; inspect it with `multipass list` first.

### No IP address or failed shell connection

VPNs, host firewalls, DNS proxies, and operating-system updates can interfere with Multipass networking. Temporarily disconnect the VPN, verify firewall permissions, restart the host if necessary, and retry using the default network instead of a bridged network.

### IP connectivity works but DNS fails

Test an address and a hostname separately:

```bash
multipass exec devbox -- ping -c 3 1.1.1.1
multipass exec devbox -- getent hosts ubuntu.com
multipass exec devbox -- resolvectl status
```

If only hostname lookup fails, investigate VPN software, local DNS proxies, and services using port 53.

### Cloud-init failure

Inspect status and logs:

```bash
multipass exec devbox -- cloud-init status --long
multipass exec devbox -- sudo cloud-init analyze show
multipass exec devbox -- sudo tail -n 100 /var/log/cloud-init-output.log
```

Invalid YAML, unavailable repositories, and commands that never finish are common causes.

### `exec format error`

Compare host and guest architectures:

```bash
uname -m
multipass exec devbox -- uname -m
multipass exec devbox -- dpkg --print-architecture
```

Install a compatible or multi-architecture image or binary.

## 12. Cleanup and safe removal

Pause an instance without deleting it:

```bash
multipass stop devbox
```

Copy important files before deleting:

```bash
multipass transfer devbox:/home/ubuntu/project/results.tar.gz .
```

Delete an instance permanently:

```bash
multipass delete devbox
```

Remove deleted-instance data:

```bash
multipass purge
```

Clean up the three-node lab:

```bash
multipass delete master worker1 worker2
multipass purge
```

Delete all instances only when you are certain that no data is needed:

```bash
multipass delete --all
multipass purge
```

Unmount shared directories when finished:

```bash
multipass unmount devbox
```

## 13. Compact command reference

| Task | Command |
| --- | --- |
| Show version | `multipass version` |
| List images | `multipass images` |
| List instances | `multipass list` |
| Show details | `multipass info <name>` |
| Create an instance | `multipass launch 24.04 --name <name>` |
| Open a shell | `multipass shell <name>` |
| Run a command | `multipass exec <name> -- <command>` |
| Copy a file | `multipass transfer <source> <destination>` |
| Mount a directory | `multipass mount <host-path> <name>:<guest-path>` |
| Unmount directories | `multipass unmount <name>` |
| Stop an instance | `multipass stop <name>` |
| Start an instance | `multipass start <name>` |
| Restart an instance | `multipass restart <name>` |
| Delete an instance | `multipass delete <first-name> <second-name> ... <N-name>` |
| Delete multiple instances | `multipass delete <name>` |
| Remove deleted data | `multipass purge` |
| List host networks | `multipass networks` |
| Read a setting | `multipass get <key>` |
| Set a resource | `multipass set <key>=<value>` |

## Conclusion

Multipass provides a practical middle ground between containers and remote cloud infrastructure. It gives you real Ubuntu VMs, a simple CLI, repeatable resource configuration, private networking, and cloud-init support without requiring a separate server.

The most useful habits are to use explicit instance names, pin image releases, check current state and IP addresses, automate setup with cloud-init, account for CPU architecture, and delete unused instances.

With this foundation complete, the same three-node lab can later be extended with MicroK8s, Kubernetes, Helm, Prometheus, Grafana, and Alertmanager.

## Further reading

- [Official Multipass documentation](https://documentation.ubuntu.com/multipass/)
- [Install Multipass](https://documentation.ubuntu.com/multipass/latest/how-to-guides/install-multipass/)
- [Multipass CLI reference](https://documentation.ubuntu.com/multipass/latest/reference/command-line-interface/)
- [Cloud-init with Multipass](https://documentation.ubuntu.com/multipass/latest/how-to-guides/manage-instances/launch-customized-instances-with-multipass-and-cloud-init/)
- [Multipass networking](https://documentation.ubuntu.com/multipass/latest/how-to-guides/manage-instances/set-up-custom-networking/)
- [Multipass networking troubleshooting](https://documentation.ubuntu.com/multipass/latest/how-to-guides/troubleshoot/troubleshoot-networking/)
- [MicroK8s documentation](https://microk8s.io/docs)



## 10. Build a small multi-node lab

A three-node lab is useful for distributed systems, service discovery, networking, cluster schedulers, and Kubernetes experiments.

```text
                         Host computer
                              |
             Multipass private virtual network
                    /          |          \
              master        worker1       worker2
             2 CPU/4G       2 CPU/2G      2 CPU/2G
```

Create the nodes on the host:

```bash
multipass launch 24.04 --name master --cpus 2 --memory 4G --disk 25G
multipass launch 24.04 --name worker1 --cpus 2 --memory 2G --disk 20G
multipass launch 24.04 --name worker2 --cpus 2 --memory 2G --disk 20G
```

Verify them:

```bash
multipass list
multipass info master
multipass info worker1
multipass info worker2
```

Check each guest:

```bash
for node in master worker1 worker2; do
  echo "--- $node ---"
  multipass exec "$node" -- hostname
  multipass exec "$node" -- uname -m
  multipass exec "$node" -- uptime
done
```

Get worker addresses with `multipass list`, then test from the master:

```bash
multipass exec master -- ping -c 3 <WORKER1_IP>
multipass exec master -- ping -c 3 <WORKER2_IP>
```

Check time because distributed systems and monitoring depend on accurate timestamps:

```bash
for node in master worker1 worker2; do
  echo "--- $node ---"
  multipass exec "$node" -- date -u
done
```

Ubuntu normally synchronizes time automatically. Inspect a node if its clock has a large offset:

```bash
multipass exec master -- timedatectl status
```