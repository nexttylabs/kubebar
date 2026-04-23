# Permissions and Security

Kubebar is designed with a "security-first, local-only" philosophy. It acts as a lightweight observer for your Kubernetes clusters, relying entirely on your existing local environment and security configurations.

## The `kubectl` Dependency

Kubebar is a wrapper around the `kubectl` command-line tool. It does not implement its own Kubernetes API client; instead, it leverages the battle-tested authentication and communication logic of `kubectl`.

- **Requirement**: `kubectl` must be installed and accessible in your system `PATH` (typically `/usr/local/bin/kubectl` or `/opt/homebrew/bin/kubectl`).
- **Access**: Kubebar calls `kubectl` to fetch cluster status, node health, workload details, and events. It never asks for or stores your Kubernetes credentials (tokens, certificates, or passwords).

## File System Access

### 1. Kubeconfig (`~/.kube/config`)
To understand which clusters are available and how to connect to them, Kubebar needs to read your `kubeconfig` file.
- **Why**: To populate the context picker during setup and to authorize requests via `kubectl`.
- **Note**: macOS may prompt you for permission to access the `.kube` folder when Kubebar first attempts to run a command.

### 2. Application Support
Kubebar stores its own configuration (selected context, watchlist, and refresh cadence) at:
`~/Library/Application Support/Kubebar/config.json`
- This file contains **no sensitive credentials**. It only stores the *names* of the resources you wish to monitor.

## Privacy Boundary

- **No Remote Telemetry**: Kubebar does not send usage data or cluster information to any external servers.
- **No Secret Access**: Kubebar never queries Kubernetes `Secrets`. It only reads high-level status metadata (Pods, Nodes, Events).
- **Process Isolation**: All Kubernetes interaction happens through sub-processes calling your local `kubectl` binary.

## Handling Permission Denied Errors

If you see a "Permission Denied" state in the menu:
1. **Check Kubeconfig**: Ensure your current user has read access to `~/.kube/config`.
2. **Binary Path**: Ensure `kubectl` is executable. You can verify this by running `which kubectl` in your terminal.
3. **macOS Gatekeeper**: If you are running a pre-compiled version of Kubebar, you may need to explicitly allow it to execute sub-processes in **System Settings > Privacy & Security**.
