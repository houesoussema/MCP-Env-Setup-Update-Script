# MCP (Model Context Protocol) Environment Setup and Update Script for Windows

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
![Version: 1.0.0](https://img.shields.io/badge/Version-1.0.0-blue)
![PowerShell: Core/Desktop](https://img.shields.io/badge/PowerShell-Core%20%7C%20Desktop-purple)

This is an unfinished work!! (but it works)

This PowerShell script automates the setup and maintenance of my MCP (Model Context Protocol) server environment on a Windows machine. It handles the installation and updating of essential dependencies, specific MCP-related packages, sets up required directories, clones and configures custom MCP server components from Git, performs basic tests, and offers flexible MCP configuration options for tools like Claude Desktop and the MCP Superassistant Proxy.

**Author:** [oussema (houesoussema)](https://github.com/houesoussema)
**Last Modified (Script):** 13-6-25 

## Table of Contents

- [Overview](#overview)
- [Features](#features)
- [Prerequisites](#prerequisites)
- [Installation of the Script](#installation-of-the-script)
- [Usage](#usage)
  - [Parameters](#parameters)
- [What The Script Installs/Configures](#what-the-script-installsconfigures)
  - [General MCP Resources](#general-mcp-resources)
  - [Core Dependencies (via Chocolatey)](#core-dependencies-via-chocolatey)
  - [Python Tooling (via pip/uv)](#python-tooling-via-pipuv)
  - [Global NPM Packages](#global-npm-packages)
  - [Python Packages (via pip/uvx)](#python-packages-via-pipuvx)
  - [Custom Cloned MCP Server (from Git)](#custom-cloned-mcp-server-from-git)
  - [Directories Created](#directories-created)
- [MCP Configuration Options](#mcp-configuration-options)
- [MCP Superassistant Proxy](#mcp-superassistant-proxy)
- [Known Issues](#known-issues)
  - [docs-fetch-mcp TypeScript Build Errors](#docs-fetch-mcp-typescript-build-errors)
- [Troubleshooting](#troubleshooting)
- [Contributing](#contributing)
- [License](#license)

## Overview

The `setup-mcp-servers.ps1` script is designed to streamline the deployment and upkeep of an MCP server ecosystem (the one that i use) on Windows. It takes care of:
1.  Installing and updating core software like Node.js, Python, and Git using Chocolatey.
2.  Setting up Python-specific tooling like `uv` and `uvx`.
3.  Installing various MCP server components distributed as NPM packages or Python packages.
4.  Cloning, building (where possible), and configuring custom MCP servers from Git repositories.
5.  Creating necessary directory structures (e.g., `C:\MCP`).
6.  Performing basic health checks on installed servers.
7.  Offering choices for MCP configuration:
    *   A standalone `mcpconfig.json` file.
    *   Directly updating the Claude Desktop application's configuration.
8.  Optionally launching the MCP Superassistant Proxy.

## Features

*   **Automated Dependency Management:** Installs Chocolatey (if needed), Node.js (LTS), Python, and Git.
*   **MCP Server Installation:** Handles installation of numerous MCP servers from NPM and PyPI.
*   **Custom Server Setup:** Clones and attempts to build the `docs-fetch-mcp` server.
*   **Directory Structure:** Creates a standardized `C:\MCP` directory for servers and configurations.
*   **Server Testing:** Performs basic functionality tests for key MCP servers.
*   **Flexible Configuration:** Allows users to choose between creating a standalone `mcpconfig.json` or directly integrating server settings into Claude Desktop's configuration.
*   **Superassistant Proxy Integration:** Informs about and offers to launch the MCP Superassistant Proxy.
*   **Update & Force Options:** Supports skipping updates for speed (`-SkipUpdates`) or forcing reinstallation (`-Force`).

## Prerequisites

*   **Windows Operating System.**
*   **PowerShell:** The script is designed for PowerShell on Windows.
*   **Administrator Privileges:** Highly recommended for full functionality, especially for Chocolatey installation and global package management. The script will warn if not run as admin.
*   **Internet Connection:** Required for downloading dependencies, packages, and cloning repositories.

## Installation of the Script

1.  Clone this repository or download the `setup-mcp-servers.ps1` script to your local machine.
    ```bash
    git clone [<repository_url>](https://github.com/houesoussema/MCP-Env-Setup-Update-Script.git)
    cd MCP-Env-Setup-Update-Script
    ```
2.  Ensure PowerShell execution policy allows running local scripts. You might need to run:
    ```powershell
    Set-ExecutionPolicy RemoteSigned -Scope Process -Force
    # Or for more permanent change (requires admin):
    # Set-ExecutionPolicy RemoteSigned -Scope CurrentUser
    ```

Alternatively, your run the script directly :
```powershell
Invoke-WebRequest -Uri "https://raw.githubusercontent.com/houesoussema/MCP-Env-Setup-Update-Script/main/setup-mcp.ps1" -OutFile "setup-mcp.ps1"
notepad setup-mcp.ps1   # Review the code
Set-ExecutionPolicy Bypass -Scope Process -Force
.\setup-mcp.ps1
```

## Usage

Navigate to the directory containing the script in a PowerShell terminal and run:

```powershell
.\setup-mcp-servers.ps1
```

### Parameters

*   `-Force`: (Switch) If specified, the script will attempt to force reinstall components where applicable (e.g., Chocolatey packages, custom cloned server).
*   `-SkipUpdates`: (Switch) If specified, the script will skip update steps for existing components (e.g., `choco upgrade`, `npm update -g`) for faster execution.
*   `-ClaudeConfigPath <String>`: (String) Custom path to the Claude Desktop main configuration file.
    *   Default: `$env:APPDATA\Claude\claude_desktop_config.json`
    *   This path is used if you choose option 2 during the MCP Configuration step to directly update Claude Desktop's settings.

For detailed PowerShell help (once fully implemented in the script):
`Get-Help .\setup-mcp-servers.ps1 -Full`

## What The Script Installs/Configures

### General MCP Resources
*   List of official/community MCP Servers: [modelcontextprotocol/servers](https://github.com/modelcontextprotocol/servers)

### Core Dependencies (via Chocolatey)
*   **Chocolatey Package Manager:** (Installed if not present)
*   **Node.js (LTS):** JavaScript runtime environment.
*   **Python:** Programming language.
*   **Git:** Version control system.

### Python Tooling (via pip/uv)
*   **uv:** A fast Python package installer and resolver.
    *   PyPI: [pypi.org/project/uv/](https://pypi.org/project/uv/)
    *   GitHub: [astral-sh/uv](https://github.com/astral-sh/uv)
*   **uvx:** Tool to execute Python CLIs with uv.
    *   PyPI: [pypi.org/project/uvx/](https://pypi.org/project/uvx/)
    *   (Part of the `uv` ecosystem by Astral)

### Global NPM Packages
*(MCP Servers & Tools installed by this script)*
*   **@wonderwhy-er/desktop-commander:**
    *   NPM: [npmjs.com/package/@wonderwhy-er/desktop-commander](https://www.npmjs.com/package/@wonderwhy-er/desktop-commander)
    *   GitHub: [wonderwhy-er/desktop-commander](https://github.com/wonderwhy-er/desktop-commander)
*   **@modelcontextprotocol/server-sequential-thinking:**
    *   NPM: [npmjs.com/package/@modelcontextprotocol/server-sequential-thinking](https://www.npmjs.com/package/@modelcontextprotocol/server-sequential-thinking)
    *   GitHub: Likely part of [modelcontextprotocol/servers](https://github.com/modelcontextprotocol/servers) or individual repo.
*   **@modelcontextprotocol/server-memory:**
    *   NPM: [npmjs.com/package/@modelcontextprotocol/server-memory](https://www.npmjs.com/package/@modelcontextprotocol/server-memory)
    *   GitHub: Likely part of [modelcontextprotocol/servers](https://github.com/modelcontextprotocol/servers) or individual repo.
*   **@modelcontextprotocol/server-filesystem:**
    *   NPM: [npmjs.com/package/@modelcontextprotocol/server-filesystem](https://www.npmjs.com/package/@modelcontextprotocol/server-filesystem)
    *   GitHub: Likely part of [modelcontextprotocol/servers](https://github.com/modelcontextprotocol/servers) or individual repo.
*   **@modelcontextprotocol/server-brave-search:**
    *   NPM: [npmjs.com/package/@modelcontextprotocol/server-brave-search](https://www.npmjs.com/package/@modelcontextprotocol/server-brave-search)
    *   GitHub: Likely part of [modelcontextprotocol/servers](https://github.com/modelcontextprotocol/servers) or individual repo.
*   **@srbhptl39/mcp-superassistant-proxy:**
    *   NPM: [npmjs.com/package/@srbhptl39/mcp-superassistant-proxy](https://www.npmjs.com/package/@srbhptl39/mcp-superassistant-proxy)
    *   GitHub: [srbhptl39/mcp-superassistant-proxy](https://github.com/srbhptl39/mcp-superassistant-proxy)
*   **puppeteer:** Headless Chrome/Chromium browser automation.
    *   NPM: [npmjs.com/package/puppeteer](https://www.npmjs.com/package/puppeteer)
    *   GitHub: [puppeteer/puppeteer](https://github.com/puppeteer/puppeteer)

### Python Packages (via pip/uvx)
*(MCP Servers & Libraries installed by this script)*
*   **mcp-server-fetch:**
    *   PyPI: [pypi.org/project/mcp-server-fetch/](https://pypi.org/project/mcp-server-fetch/)
    *   GitHub: (If available, often linked from PyPI)
*   **mcp_server_time:**
    *   PyPI: [pypi.org/project/mcp-server-time/](https://pypi.org/project/mcp-server-time/) (Note: Script uses `mcp_server_time`, PyPI might have `mcp-server-time`)
    *   GitHub: (If available)
*   **mcp-obsidian:**
    *   PyPI: [pypi.org/project/mcp-obsidian/](https://pypi.org/project/mcp-obsidian/)
    *   GitHub: (If available)

### Custom Cloned MCP Server (from Git)
*   **package-documentation-mcp (docs-fetch-mcp):**
    *   GitHub URL: [https://github.com/wolfyy970/docs-fetch-mcp.git](https://github.com/wolfyy970/docs-fetch-mcp.git)
    *   Installed to: `C:\MCP\Servers\package-documentation-mcp`
    *   *Note: See [Known Issues](#known-issues) regarding build problems.*

### Directories Created
*   `C:\MCP`
*   `C:\MCP\Servers`
*   `C:\MCP\config`

## MCP Configuration Options

The script will prompt you to choose how to set up the MCP server configurations:

1.  **Create/Update Standalone `mcpconfig.json`:**
    *   Creates or updates `C:\MCP\config\mcpconfig.json`.
    *   This file can be manually pointed to by Claude Desktop (by setting `mcp_server_config_path` in Claude's main config).
    *   The MCP Superassistant Proxy can also use this file (e.g., via `mcp-superassistant-proxy --config C:\MCP\config\mcpconfig.json`).
    *   The script will ask for necessary details like API keys or paths for specific servers (e.g., Obsidian API key, filesystem paths).

2.  **Directly Update Claude Desktop Config:**
    *   Merges MCP server settings directly into your Claude Desktop configuration file (default: `$env:APPDATA\Claude\claude_desktop_config.json`).
    *   The script will set `mcp_server_config` with the server details and attempt to set `mcp_server_config_path` to `null` to ensure embedded settings are used.
    *   You'll be prompted for the same server-specific details as option 1.

3.  **Skip MCP Configuration:**
    *   No configuration files will be created or modified by this script. You will need to configure MCP servers manually.

## MCP Superassistant Proxy

The script provides information about the MCP Superassistant and its proxy server:
*   **Proxy Server:** `@srbhptl39/mcp-superassistant-proxy` (installed via NPM).
    *   GitHub: [srbhptl39/mcp-superassistant-proxy](https://github.com/srbhptl39/mcp-superassistant-proxy)
*   **Chrome Extension:** [MCP Superassistant on Chrome Web Store](https://chromewebstore.google.com/detail/mcp-superassistant/kngiafgkdnlkgmefdafaibkibegkcaef)

If you choose to create the standalone `mcpconfig.json` (option 1), the script will offer to launch the proxy server using this configuration file. You can also launch it manually:
```powershell
npx @srbhptl39/mcp-superassistant-proxy@latest --config "C:\MCP\config\mcpconfig.json"
```

## Known Issues

### `docs-fetch-mcp` TypeScript Build Errors
*(As of script version 1.0.0, relevant to Puppeteer v24.10.1 / TS v5.8.2 in the target project)*

*   **Description:**
    TypeScript errors are encountered when trying to build the `docs-fetch-mcp` project. The issues appear to be related to Puppeteer type definitions and launch options. This script will still attempt to clone and run `npm install`, but `npm run build` might fail until these issues are resolved in the `docs-fetch-mcp` repository or its dependencies.
*   **Error Log Snippets:**
    ```
    src/browser/browser-manager.ts:1:30 - error TS2614: Module '"puppeteer"' has no exported member 'PuppeteerLaunchOptions'.
    src/server.ts:335:9 - error TS2322: Type '"new"' is not assignable to type 'boolean | "shell" | undefined'.
    src/server.ts:360:18 - error TS2339: Property 'waitForTimeout' does not exist on type 'Page'.
    ```
*   **Steps to Reproduce (manually for `docs-fetch-mcp`):**
    1.  `git clone https://github.com/wolfyy970/docs-fetch-mcp.git`
    2.  `cd docs-fetch-mcp`
    3.  `npm install`
    4.  `npm run build`
*   **Reported Environment for the issue:**
    *   OS: Windows 10
    *   Node.js version: v24.2.0
    *   npm version: 11.4.2
    *   Puppeteer version in project: `"puppeteer": "^24.10.1"`
    *   TypeScript version in project: `"typescript": "^5.8.2"`
*   **Possible Workarounds/Notes for `docs-fetch-mcp` maintainers:**
    *   The `headless: 'new'` option for Puppeteer is a newer syntax. Ensure types are compatible or adjust to `headless: true` (old) or `headless: false`.
    *   `page.waitForTimeout()` has been deprecated. Replace with `await new Promise(r => setTimeout(r, milliseconds))` or other modern waiting strategies.
    *   `PuppeteerLaunchOptions` might have been renamed or moved. Check the specific Puppeteer version's API documentation. Alternatively, if `puppeteer` itself now bundles sufficient types, `@types/puppeteer` might not be needed or could conflict.

## Troubleshooting

*   **Run as Administrator:** If you encounter permission errors, especially during Chocolatey or global NPM package installations, try running PowerShell as an Administrator.
*   **Check Logs:** Review the script's output in the console for any specific error messages.
*   **Internet Connection:** Ensure a stable internet connection is available.
*   **Conflicting Versions:** If you have manually managed versions of Node.js, Python, or other tools, there might be conflicts. This script aims to standardize versions.
*   **Path Environment Variable:** The script attempts to refresh the PATH variable after installations. However, in some cases, a PowerShell terminal restart or even a system reboot might be necessary for all changes to take effect.
*   **Report Issues:** If you encounter problems with the script itself, please open an issue on this repository. For issues with specific MCP servers, refer to their respective repositories.

## Contributing

Contributions to improve this script are welcome! Please feel free to fork the repository, make changes, and submit a pull request.

1.  Fork the Project
2.  Create your Feature Branch (`git checkout -b feature/AmazingFeature`)
3.  Commit your Changes (`git commit -m 'Add some AmazingFeature'`)
4.  Push to the Branch (`git push origin feature/AmazingFeature`)
5.  Open a Pull Request

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file (if one exists in the repo, otherwise assume MIT as per script header) for details.
