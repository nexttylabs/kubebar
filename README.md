# Kubebar ☸️

**Kubebar** is a native macOS menu bar app for keeping a pulse on your Kubernetes clusters.

It provides a lightweight, "watchlist-first" status instrument that tells you at a glance whether your mission-critical workloads are healthy, which ones need attention, and whether the data you're looking at is fresh.

![screenshot](./docs/screenshots/overview-warning.png)

<p align="center">
  <!-- TODO: Add Kubebar menu screenshot here -->
  <i>"Is my cluster okay? Now you know, without leaving your current window."</i>
</p>

## Why Kubebar?

Kubebar is not a replacement for `k9s` or `kubectl`. It is the small, persistent dashboard you look at *before* you dive into deeper troubleshooting tools. It focuses on:
- **Visibility**: Always-on health status in your menu bar.
- **Speed**: Instant access to workload reasons and warning events.
- **Trust**: Clear indicators for stale data and connectivity issues.

## Prerequisites

Kubebar relies on the official Kubernetes CLI to interact with your clusters.
- **kubectl**: Must be installed and available in your `PATH`.
  ```bash
  brew install kubernetes-cli
  ```
- **Kubeconfig**: You must have a valid `~/.kube/config` with the contexts you wish to monitor.

## Getting Started

### 1. Installation

#### Option A: Download Pre-compiled (Coming Soon)
Download the latest `Kubebar.zip` from [GitHub Releases](https://github.com/nextty/kubebar/releases), extract it, and move `Kubebar.app` to your `/Applications` folder.

#### Option B: Build from Source
```bash
git clone https://github.com/nextty/kubebar.git
cd kubebar
xcodegen generate
open Kubebar.xcodeproj
# Or use the local install script
./scripts/install-local.sh
```

### 2. First Run
- Open Kubebar.
- Follow the **Setup** flow to select your Kubernetes context.
- Pick the namespaces and workloads you want to add to your **Watchlist**.
- Set your preferred **Refresh Cadence**.

---

## FAQ: Trusting Kubebar

**Q: Why does macOS say the app is "unverified" or "damaged"?**
**A**: Currently, Kubebar is distributed with an **Ad-hoc signature** because it is an open-source project without a paid Apple Developer account. To run the app:
1. **Right-click** `Kubebar.app` in Finder and select **Open**.
2. Click **Open** again in the security dialog.
3. If it still won't open, run: `xattr -cr /Applications/Kubebar.app` in your terminal.

**Q: Does Kubebar store my Kubernetes credentials?**
**A**: **No.** Kubebar uses your existing `kubectl` configuration. It never asks for, stores, or transmits your tokens or certificates. See [docs/PERMISSIONS.md](docs/PERMISSIONS.md) for details.

---

## Documentation
- [Permissions & Privacy](docs/PERMISSIONS.md) — How we use `kubectl` and handle your data.
- [Release Process](docs/RELEASING.md) — How the app is built and signed.
- [Architecture](docs/architecture/README.md) — High-level system overview.
- [Product Roadmap](docs/plans/2026-04-19-002-kubebar-product-roadmap.md) — What’s coming next.

## Build and Test

To run quality checks locally:
```bash
./scripts/swift-quality-gate.sh local
```

## Local Development

Kubebar uses `XcodeGen` to manage the project file. If you add files or change targets, run:
```bash
xcodegen generate
```

## License
MIT • [Nextty](https://github.com/nextty)
