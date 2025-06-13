# =================================================================================================
# MCP (Model Context Protocol) Environment Setup and Update Script
# Version: 1.0.0
# Author: oussema / https://github.com/houesoussema
# License: MIT
# Last Modified: 13-6-25
#
# DESCRIPTION:
# This PowerShell script automates the setup and maintenance of the MCP (Model Context Protocol)
# server environment on a Windows machine. It handles the installation and updating of
# essential dependencies, specific MCP-related packages, sets up required directories,
# clones and configures custom MCP server components from Git repositories,
# performs basic tests to ensure the servers are operational, optionally creates
# a default mcpconfig.json file, and finally, offers to launch the MCP Superassistant Proxy.
#
# USAGE:
# Run this script from a PowerShell terminal. Administrator privileges are recommended for
# full functionality (especially for Chocolatey and global package installations).
#
#   .\setup-mcp-servers.ps1
#
# Optional parameters:
#   -Force:         Force reinstall components (where applicable).
#   -SkipUpdates:   Skip update steps for faster execution.
#   -ConfigPath:    Custom path to a configuration file (currently for future use by other tools,
#                   this script will offer to create one at C:\MCP\config\mcpconfig.json).
#
# For detailed help, run: Get-Help .\setup-mcp-servers.ps1 -Full (pending)
#
# --- WHAT THIS SCRIPT INSTALLS/CONFIGURES ---
#
# General MCP Resources:
#   - List of official/community MCP Servers: https://github.com/modelcontextprotocol/servers
#
# Core Dependencies (via Chocolatey):
#   - Chocolatey Package Manager (if not already installed)
#   - Node.js (LTS): JavaScript runtime environment
#   - Python: Programming language
#   - Git: Version control system
#
# Python Tooling (via pip/uv):
#   - uv: A fast Python package installer and resolver (PyPI: https://pypi.org/project/uv/, GitHub: https://github.com/astral-sh/uv)
#   - uvx: Tool to execute Python CLIs with uv (PyPI: https://pypi.org/project/uvx/)
#
# Global NPM Packages (MCP Servers & Tools installed by this script):
#   - @wonderwhy-er/desktop-commander:
#     NPM: https://www.npmjs.com/package/@wonderwhy-er/desktop-commander
#     GitHub: (Please verify and add link, e.g., https://github.com/wonderwhy-er/desktop-commander)
#   - @modelcontextprotocol/server-sequential-thinking:
#     NPM: https://www.npmjs.com/package/@modelcontextprotocol/server-sequential-thinking
#     GitHub: (Often part of https://github.com/modelcontextprotocol/servers or a monorepo - Please verify)
#   - @modelcontextprotocol/server-memory:
#     NPM: https://www.npmjs.com/package/@modelcontextprotocol/server-memory
#     GitHub: (Please verify)
#   - @modelcontextprotocol/server-filesystem:
#     NPM: https://www.npmjs.com/package/@modelcontextprotocol/server-filesystem
#     GitHub: (Please verify)
#   - @modelcontextprotocol/server-brave-search:
#     NPM: https://www.npmjs.com/package/@modelcontextprotocol/server-brave-search
#     GitHub: (Please verify)
#   - @srbhptl39/mcp-superassistant-proxy:
#     NPM: https://www.npmjs.com/package/@srbhptl39/mcp-superassistant-proxy
#     GitHub: https://github.com/srbhptl39/mcp-superassistant-proxy (for the proxy server)
#   - puppeteer: Headless Chrome/Chromium browser automation
#     NPM: https://www.npmjs.com/package/puppeteer
#     GitHub: https://github.com/puppeteer/puppeteer
#
# Python Packages (MCP Servers & Libraries installed by this script - via pip/uvx):
#   - mcp-server-fetch: (PyPI/GitHub: Please verify and add link)
#   - mcp_server_time: (PyPI/GitHub: Please verify and add link)
#   - mcp-obsidian: (PyPI/GitHub: Please verify and add link)
#
# Custom Cloned MCP Server (from Git by this script):
#   - package-documentation-mcp (docs-fetch-mcp):
#     GitHub URL: https://github.com/wolfyy970/docs-fetch-mcp.git
#     Installed to: C:\MCP\Servers\package-documentation-mcp
#
# Directories Created:
#   - C:\MCP
#   - C:\MCP\Servers
#   - C:\MCP\config
#
# Configuration File Options (User Choice):
#   1. Create/Update Standalone: C:\MCP\config\mcpconfig.json (user then manually points Claude Desktop to this if needed)
#   2. Directly Update Claude Desktop Config: $env:APPDATA\Claude\claude_desktop_config.json (merges MCP server settings)
#
# --- KNOWN ISSUES ---
#
# 1. docs-fetch-mcp TypeScript Build Errors (as of YYYY-MM-DD, relevant to Puppeteer v24.10.1 / TS v5.8.2)
#
#    Description:
#      TypeScript errors are encountered when trying to build the 'docs-fetch-mcp' project.
#      The issues appear to be related to Puppeteer type definitions and launch options.
#      This script will still attempt to clone and run 'npm install', but 'npm run build' might fail
#      until these issues are resolved in the 'docs-fetch-mcp' repository or its dependencies.
#
#    Error Log Snippets:
#      src/browser/browser-manager.ts:1:30 - error TS2614: Module '"puppeteer"' has no exported member 'PuppeteerLaunchOptions'.
#      src/server.ts:335:9 - error TS2322: Type '"new"' is not assignable to type 'boolean | "shell" | undefined'.
#      src/server.ts:360:18 - error TS2339: Property 'waitForTimeout' does not exist on type 'Page'.
#
#    Steps to Reproduce (manually for the 'docs-fetch-mcp' project):
#      1. Clone the repository: git clone https://github.com/wolfyy970/docs-fetch-mcp.git
#      2. Navigate into the directory: cd docs-fetch-mcp
#      3. Run: npm install
#      4. Run: npm run build
#
#    Expected Behavior:
#      The project should build without TypeScript errors.
#
#    Actual Behavior (as reported):
#      Three TypeScript errors related to:
#      1. Missing `PuppeteerLaunchOptions` type
#      2. Invalid `headless: 'new'` option in Puppeteer launch
#      3. Missing `waitForTimeout` method on Puppeteer's Page object
#
#    Reported Environment for the issue:
#      - OS: Windows 10
#      - Node.js version: v24.2.0
#      - npm version: 11.4.2
#      - Puppeteer version in project: "puppeteer": "^24.10.1" (likely refers to project's package.json)
#        - @types/puppeteer: 7.0.4 (if present as a direct dependency or transient)
#      - TypeScript version in project: "typescript": "^5.8.2" (likely refers to project's package.json)
#
#    Possible Workarounds/Notes for 'docs-fetch-mcp' maintainers:
#      - The `headless: 'new'` option for Puppeteer is a newer syntax. Ensure types are compatible or adjust to `headless: true` (old) or `headless: false` if needed.
#      - `page.waitForTimeout()` has been deprecated and removed in recent Puppeteer versions. Replace with `await new Promise(r => setTimeout(r, milliseconds))` or other modern waiting strategies.
#      - `PuppeteerLaunchOptions` might have been renamed or moved in `puppeteer` or `@types/puppeteer`. Check the specific version's API documentation.
#        Alternatively, if `puppeteer` itself now bundles sufficient types, `@types/puppeteer` might not be needed or could conflict.
#
#
# =================================================================================================


<#
.SYNOPSIS
MCP Servers Setup and Update Script with flexible MCP configuration options.

.DESCRIPTION
This comprehensive setup script:
1. Installs/updates dependencies (Chocolatey, Node.js, Python, Git).
2. Installs/updates MCP server components (NPM, Python).
3. Configures directories (C:\MCP, C:\MCP\Servers, C:\MCP\config).
4. Clones/updates and attempts to build 'docs-fetch-mcp'.
5. Tests installed MCP servers.
6. Prompts user to choose an MCP configuration method:
    a) Create/Update 'C:\MCP\config\mcpconfig.json' (for standalone use or manual Claude Desktop linking).
    b) Directly update Claude Desktop's main configuration file with MCP server settings.
7. Informs about MCP Superassistant and offers to launch its proxy server.

Administrator privileges recommended. Check "KNOWN ISSUES" in header.

.PARAMETER Force
If specified, this switch will attempt to reinstall all components.

.PARAMETER SkipUpdates
If specified, this switch will skip update steps for faster execution.

.PARAMETER ConfigPath
Path to the Claude Desktop main configuration file.
Default: "$env:APPDATA\Claude\claude_desktop_config.json"
This is used if the user opts to directly update the Claude Desktop config.
#>

param(
    [switch]$Force,
    [switch]$SkipUpdates,
    [string]$ClaudeConfigPath = "$env:APPDATA\Claude\claude_desktop_config.json" # Renamed for clarity
)

# Colors for output customization
$Colors = @{ Success = "Green"; Warning = "Yellow"; Error = "Red"; Info = "Cyan"; Header = "Magenta"; White = "White" }

# Function to write output to the console with specified colors.
function Write-ColorOutput {
    param([string]$Message, [string]$Color = "White")
    if ($Colors.ContainsKey($Color)) { Write-Host $Message -ForegroundColor $Colors[$Color] }
    else { Write-Host $Message }
}

# Function to check if a command/executable is available in the system's PATH.
function Test-CommandExists {
    param([string]$Command)
    try { Get-Command $Command -ErrorAction Stop | Out-Null; return $true } catch { return $false }
}

# Function to install a package using Chocolatey.
function Install-ChocoPackage {
    param([string]$Package, [string]$DisplayName)
    $commandToCheck = $Package.Split('.')[0]; if ($commandToCheck -eq "nodejs-lts") { $commandToCheck = "node" }
    if (-not $Force -and (Test-CommandExists $commandToCheck)) {
        Write-ColorOutput "✓ $DisplayName appears to be already installed (found '$commandToCheck'). Use -Force to attempt reinstall/upgrade." "Success"; return
    }
    Write-ColorOutput "Installing/Updating $DisplayName using Chocolatey..." "Info"
    try { choco install $Package -y --acceptlicense; Write-ColorOutput "✓ $DisplayName installed/updated successfully via Chocolatey" "Success" }
    catch { Write-ColorOutput "✗ Failed to install/update $DisplayName via Chocolatey: $($_.Exception.Message)" "Error" }
}

# Function to install or upgrade a Python package using pip.
function Install-PythonPackage {
    param([string]$Package, [string]$DisplayName = $Package)
    Write-ColorOutput "Installing/updating Python package: $DisplayName using pip..." "Info"
    try { python -m pip install --upgrade $Package; Write-ColorOutput "✓ Python package $DisplayName installed/updated successfully" "Success" }
    catch { Write-ColorOutput "✗ Failed to install/update Python package ${DisplayName}: $($_.Exception.Message)" "Error" } # Fix: Corrected variable reference
}

# Function to update globally installed Node.js packages using npm.
function Update-NodePackages {
    Write-ColorOutput "Updating Node.js global packages using npm..." "Info"
    try { npm update -g; Write-ColorOutput "✓ Node.js global packages updated" "Success" }
    catch { Write-ColorOutput "✗ Failed to update Node.js global packages: $($_.Exception.Message)" "Error" }
}

# Function to test if an MCP server (CLI tool) is working by calling its --help command.
function Test-MCPServer {
    param([string]$Name, [string]$Command, [array]$Args)
    Write-ColorOutput "Testing MCP server: $Name..." "Info"
    $tempOutputFile = $null
    try {
        $baseArgs = $Args; $testArgsWithHelp = $baseArgs + "--help"; $testArgsWithVersion = $baseArgs + "--version"
        if ($Command -eq "npx" -and $baseArgs.Count -ge 4 -and $baseArgs[0] -eq "-p") {
            $packageArg = $baseArgs[0..2]; $commandInPackage = $baseArgs[3]
            $testArgsWithHelp  = $packageArg + $commandInPackage + "--help"; $testArgsWithVersion = $packageArg + $commandInPackage + "--version"
        }
        $tempOutputFile = New-TemporaryFile; $output = ""; $exitCode = 1
        & $Command @testArgsWithHelp *> $tempOutputFile.FullName; $exitCode = $LASTEXITCODE; $output = Get-Content $tempOutputFile.FullName -Raw -ErrorAction SilentlyContinue
        if ($exitCode -ne 0 -or -not ($output -match "help|usage|options|MCP|version")) {
            Write-ColorOutput "  (--help test inconclusive or failed, trying --version for $Name)" "Info"
            & $Command @testArgsWithVersion *> $tempOutputFile.FullName; $exitCode = $LASTEXITCODE; $output = Get-Content $tempOutputFile.FullName -Raw -ErrorAction SilentlyContinue
        }
        if ($exitCode -eq 0 -or $output -match "help|usage|options|version|MCP" -or ($Name -eq "desktop-commander" -and $output -match "\[command\]")) {
            Write-ColorOutput "✓ $Name is working (responded to --help/--version)" "Success"; return $true
        } else {
            Write-ColorOutput "✗ $Name test failed. Exit code: $exitCode." "Warning"; Write-ColorOutput "Output (first ~200 chars): $($output.Substring(0, [System.Math]::Min($output.Length, 200)))" "Warning"; return $false
        }
    } catch { Write-ColorOutput "✗ $Name is not accessible or command test failed catastrophically: $($_.Exception.Message)" "Error"; return $false }
    finally { if ($tempOutputFile -and (Test-Path $tempOutputFile.FullName)) { Remove-Item $tempOutputFile.FullName -ErrorAction SilentlyContinue } }
}

# Function to install or update UV (a Python package manager).
function Install-UV {
    Write-ColorOutput "Installing/updating UV (Python package manager)..." "Info"
    try {
        if (Test-CommandExists "uv" -and -not $Force) {
            if (-not $SkipUpdates) { Write-ColorOutput "UV found. Attempting self-update..." "Info"; uv self update }
            else { Write-ColorOutput "UV found. Skipping self-update due to -SkipUpdates." "Info" }
        } else { Write-ColorOutput "UV not found or -Force specified. Installing/Reinstalling UV via pip..." "Info"; python -m pip install --upgrade uv }
        Write-ColorOutput "✓ UV installed/updated successfully" "Success"
    } catch { Write-ColorOutput "✗ Failed to install/update UV: $($_.Exception.Message)" "Error" }
}

# Function to create a directory if it does not already exist.
function Create-DirectoryIfNotExists {
    param([string]$Path)
    if (-not (Test-Path $Path -PathType Container)) {
        Write-ColorOutput "Creating directory: $Path" "Info"
        try { New-Item -ItemType Directory -Path $Path -Force -ErrorAction Stop | Out-Null; Write-ColorOutput "✓ Directory $Path created" "Success" }
        catch { Write-ColorOutput "✗ Failed to create directory ${Path}: $($_.Exception.Message)" "Error" }
    }
}

# Function to prompt user for input with a default value and placeholder.
function Read-HostWithDefault {
    param(
        [string]$Prompt,
        [string]$DefaultValue,
        [string]$PlaceholderIfEmpty = "PLACEHOLDER_NOT_SET"
    )
    $userInput = Read-Host "$Prompt (default: '$DefaultValue')"
    if ([string]::IsNullOrWhiteSpace($userInput)) {
        if ([string]::IsNullOrWhiteSpace($DefaultValue) -and -not ([string]::IsNullOrEmpty($PlaceholderIfEmpty))) { return $PlaceholderIfEmpty } # Use placeholder if default is empty and placeholder is not
        return $DefaultValue
    }
    return $userInput
}

# Function to gather MCP server details from the user.
function Get-MCPServerDetailsFromUser {
    Write-ColorOutput "Gathering information for MCP servers. Press Enter for default/placeholder." "Info"
    $obsidianApiKey = Read-HostWithDefault "Enter OBSIDIAN_API_KEY" "" "YOUR_OBSIDIAN_API_KEY_HERE"
    $obsidianHost = Read-HostWithDefault "Enter OBSIDIAN_HOST" "https://127.0.0.1:27124/"
    $timeTimezone = Read-HostWithDefault "Enter Timezone for 'time' server (e.g., Europe/London)" "Africa/Tunis" "YOUR_LOCAL_TIMEZONE"
    $fsPath1 = Read-HostWithDefault "Enter Filesystem Path 1 (e.g., your vault)" "C:/PATH/TO/YOUR/VAULT" # Changed default to be more generic placeholder
    $fsPath2 = Read-HostWithDefault "Enter Filesystem Path 2 (e.g., MCP base)" "C:/MCP/"

    return @{
        mcpServers = @{
            "desktop-commander" = @{ command = "npx.cmd"; args = @("@wonderwhy-er/desktop-commander@latest") }
            "sequential-thinking" = @{ command = "npx"; args = @("-y", "@modelcontextprotocol/server-sequential-thinking") }
            "memory" = @{ command = "npx"; args = @("-y", "@modelcontextprotocol/server-memory") }
            "filesystem" = @{ command = "npx"; args = @("-y", "@modelcontextprotocol/server-filesystem", $fsPath1, $fsPath2) }
            "mcp-obsidian" = @{ command = "uvx"; args = @("mcp-obsidian"); env = @{ OBSIDIAN_API_KEY = $obsidianApiKey; OBSIDIAN_HOST = $obsidianHost } }
            "fetch" = @{ command = "uvx"; args = @("mcp-server-fetch") }
            "time" = @{ command = "py"; args = @("-m", "mcp_server_time", "--local-timezone", $timeTimezone) }
            "docs-fetch" = @{ command = "node"; args = @("C:\MCP\Servers\package-documentation-mcp\build\index.js"); env = @{ MCP_TRANSPORT = "pipe" } }
        }
    }
}

# Function to create/update the standalone mcpconfig.json file.
function Update-StandaloneMCPConfig {
    param([hashtable]$McpServerSettings)

    $standaloneConfigPath = "C:\MCP\config\mcpconfig.json"
    $configDir = Split-Path $standaloneConfigPath
    Create-DirectoryIfNotExists $configDir

    try {
        $McpServerSettings | ConvertTo-Json -Depth 5 | Set-Content -Path $standaloneConfigPath -Encoding UTF8
        Write-ColorOutput "✓ Successfully created/updated standalone '$standaloneConfigPath'." "Success"
        Write-ColorOutput "  If using with Claude Desktop, you may need to point Claude to this file." "Info"
        Write-ColorOutput "  Typically, this involves setting 'mcp_server_config_path' in Claude's main config to '$standaloneConfigPath'." "Info"
        Write-ColorOutput "  Alternatively, MCP Superassistant Proxy will use this file by default if launched with '--config $standaloneConfigPath'." "Info"
    } catch {
        Write-ColorOutput "✗ Failed to create/update '$standaloneConfigPath': $($_.Exception.Message)" "Error"
    }
}

# Function to directly update Claude Desktop's config file.
function Update-ClaudeDesktopConfig {
    param(
        [hashtable]$McpServerSettings,
        [string]$TargetClaudeConfigPath
    )

    if (-not (Test-Path $TargetClaudeConfigPath)) {
        Write-ColorOutput "Claude Desktop config file not found at '$TargetClaudeConfigPath'." "Warning"
        Write-ColorOutput "Attempting to create a new config file there with MCP settings..." "Info"
        # Ensure parent directory exists for Claude config
        $claudeConfigParentDir = Split-Path -Path $TargetClaudeConfigPath -Parent
        if (-not (Test-Path $claudeConfigParentDir -PathType Container)) {
            Create-DirectoryIfNotExists $claudeConfigParentDir
        }
        $claudeConfig = @{} # Start with an empty config
    } else {
        Write-ColorOutput "Reading existing Claude Desktop config from '$TargetClaudeConfigPath'..." "Info"
        try {
            $claudeConfig = Get-Content -Path $TargetClaudeConfigPath -Raw | ConvertFrom-Json -ErrorAction Stop
        } catch {
        Write-ColorOutput "✗ Error reading or parsing '$TargetClaudeConfigPath'. It might be malformed or inaccessible." "Error"
            Write-ColorOutput $_.Exception.Message "Error"
            Write-ColorOutput "  Skipping direct update of Claude Desktop config." "Info"
            return
        }
    }

    Write-ColorOutput "Merging MCP server settings into Claude Desktop config..." "Info"
    # mcp_server_config should contain the mcpServers block directly
    $claudeConfig.mcp_server_config = $McpServerSettings.mcpServers

    # Also set mcp_server_config_path to null or remove it to ensure Claude uses embedded config
    if ($claudeConfig.PSObject.Properties.Name -contains "mcp_server_config_path") {
        $claudeConfig.mcp_server_config_path = $null # Or $claudeConfig.PSObject.Properties.Remove("mcp_server_config_path")
        Write-ColorOutput "  Set 'mcp_server_config_path' to null in Claude config to prioritize embedded settings." "Info"
    }


    try {
        $claudeConfig | ConvertTo-Json -Depth 10 | Set-Content -Path $TargetClaudeConfigPath -Encoding UTF8 # Increased depth
        Write-ColorOutput "✓ Successfully updated Claude Desktop config at '$TargetClaudeConfigPath' with MCP server settings." "Success"
        Write-ColorOutput "  Claude Desktop should now use these embedded MCP server configurations on next start." "Info"
    } catch {
        Write-ColorOutput "✗ Failed to write updated Claude Desktop config to '$TargetClaudeConfigPath': $($_.Exception.Message)" "Error"
    }
}


# =================================================================================================
# Main Execution Block
# =================================================================================================
try {
    Write-ColorOutput "=== MCP Servers Setup and Update Script ===" "Header"
    Write-ColorOutput "Starting comprehensive setup and update process..." "Info"
    Write-ColorOutput "Force mode: $Force"; Write-ColorOutput "Skip updates: $SkipUpdates"; Write-ColorOutput "Script Version: 1.0.0" "Info"

    $isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")
    if (-not $isAdmin) { Write-ColorOutput "Warning: Script is not running with Administrator privileges. Some installations or operations may fail. Recommended to run as Administrator." "Warning" }

    # Steps 1-5 (Installations, Directory Setup)
    Write-ColorOutput "`n=== Step 1: Chocolatey Package Manager Setup ===" "Header"; if (-not (Test-CommandExists "choco") -or ($Force -and (Test-CommandExists "choco")) ) { if (Test-CommandExists "choco" -and $Force) { Write-ColorOutput "Force: Ensuring Choco..." "Info" } else { Write-ColorOutput "Installing Choco..." "Info" }; Set-ExecutionPolicy Bypass -Scope Process -Force; [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.SecurityProtocolType]::Tls12 -bor [System.Net.SecurityProtocolType]::Tls13; try { Invoke-Expression (Invoke-WebRequest -Uri 'https://community.chocolatey.org/install.ps1' -UseBasicParsing).Content; Write-ColorOutput "✓ Choco done." "Success"; $env:Path = [System.Environment]::GetEnvironmentVariable("Path", "Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path", "User"); if (-not (Test-CommandExists "choco")) { Write-ColorOutput "✗ Choco not found post-install." "Error" } } catch { Write-ColorOutput "✗ Choco install failed: $($_.Exception.Message)" "Error" } } else { Write-ColorOutput "✓ Choco installed." "Success" }; if (Test-CommandExists "choco" -and -not $SkipUpdates) { Write-ColorOutput "Updating Choco..." "Info"; choco upgrade chocolatey -y }
    Write-ColorOutput "`n=== Step 2: Core Dependencies ===" "Header"; if (Test-CommandExists "choco") { Install-ChocoPackage "nodejs-lts" "Node.js (LTS)"; Install-ChocoPackage "python" "Python"; Install-ChocoPackage "git.install" "Git"; Write-ColorOutput "Refreshing PATH..." "Info"; $env:Path = [System.Environment]::GetEnvironmentVariable("Path", "Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path", "User"); if (-not (Test-CommandExists "npm")) { Write-ColorOutput "Warn: npm not found." "Warning" }; if (-not (Test-CommandExists "pip")) { Write-ColorOutput "Warn: pip not found." "Warning" } } else { Write-ColorOutput "Choco not found. Skipping core deps." "Error" }
    if (-not $SkipUpdates) { Write-ColorOutput "`n=== Step 3: Updating Core Tools ===" "Header"; if (Test-CommandExists "npm") { Write-ColorOutput "Updating npm..." "Info"; npm install -g npm@latest; Update-NodePackages } else { Write-ColorOutput "npm not found. Skip npm updates." "Warning" }; if (Test-CommandExists "pip") { Write-ColorOutput "Updating pip..." "Info"; python -m pip install --upgrade pip } else { Write-ColorOutput "pip not found. Skip pip updates." "Warning" }; if (Test-CommandExists "choco") { Write-ColorOutput "Updating Choco pkgs..." "Info"; choco upgrade all -y --except="'chocolatey'" } } else { Write-ColorOutput "`n=== Step 3: Skipped core tool updates. ===" "Info" }
    Write-ColorOutput "`n=== Step 4: Python Package Setup ===" "Header"; if (Test-CommandExists "python") { Install-UV; if(Test-CommandExists "uv") { Install-PythonPackage "uvx" "UVX" } else { Write-ColorOutput "UV not found. Skip UVX." "Warning" }; $pythonPackages = @("mcp-server-fetch", "mcp_server_time", "mcp-obsidian"); foreach ($pkg in $pythonPackages) { Install-PythonPackage $pkg } } else { Write-ColorOutput "Python not found. Skip Python pkgs." "Warning" }
    Write-ColorOutput "`n=== Step 5: Directory Setup ===" "Header"; $directories = @("C:\MCP", "C:\MCP\Servers", "C:\MCP\config"); foreach ($dir in $directories) { Create-DirectoryIfNotExists $dir }
    
    # Step 6 (Global NPM/UVX)
    Write-ColorOutput "`n=== Step 6: Global MCP Package Installation ===" "Header"; if (Test-CommandExists "npm") { $npmPackages = @("@wonderwhy-er/desktop-commander@latest", "@modelcontextprotocol/server-sequential-thinking", "@modelcontextprotocol/server-memory", "@modelcontextprotocol/server-filesystem", "@modelcontextprotocol/server-brave-search", "@srbhptl39/mcp-superassistant-proxy@latest"); foreach ($pkg in $npmPackages) { Write-ColorOutput "NPM: $pkg..." "Info"; try { $npmArgs = @("install", "-g", $pkg); if ($Force) { $npmArgs += "--force" }; & npm @npmArgs; Write-ColorOutput "✓ $pkg done." "Success" } catch { Write-ColorOutput "! $pkg failed: $($_.Exception.Message)" "Error" } } } else { Write-ColorOutput "npm not found. Skip NPM." "Warning" }; if (Test-CommandExists "uvx") { $uvxPackages = @("mcp-obsidian", "mcp-server-fetch"); foreach ($uvxPkg in $uvxPackages) { Write-ColorOutput "UVX: $uvxPkg..." "Info"; try { uvx $uvxPkg --help | Out-Null; Write-ColorOutput "✓ $uvxPkg done." "Success" } catch { Write-ColorOutput "! $uvxPkg failed: $($_.Exception.Message)" "Error" } } } else { Write-ColorOutput "uvx not found. Skip UVX." "Warning" }

    # Step 7 (Custom Server)
    Write-ColorOutput "`n=== Step 7: Custom MCP Server Setup (docs-fetch-mcp) ===" "Header"; $customServerPath = "C:\MCP\Servers\package-documentation-mcp"; $repoUrl = "https://github.com/wolfyy970/docs-fetch-mcp.git"; if (Test-CommandExists "npm") { Write-ColorOutput "Puppeteer..." "Info"; npm install -g puppeteer@latest } else { Write-ColorOutput "npm not found. Puppeteer skip." "Warning" }; Create-DirectoryIfNotExists (Split-Path $customServerPath -Parent); if (-not (Test-Path $customServerPath -PathType Container) -or $Force) { if ($Force -and (Test-Path $customServerPath -PathType Container)) { Write-ColorOutput "Force: Removing $customServerPath..." "Info"; try { Remove-Item -Recurse -Force $customServerPath -ErrorAction Stop } catch { Write-ColorOutput "✗ Remove failed: $($_.Exception.Message)" "Error" } }; Write-ColorOutput "Cloning $repoUrl..." "Info"; if(Test-CommandExists "git") { try { git clone $repoUrl $customServerPath; if ($LASTEXITCODE -eq 0) { Write-ColorOutput "✓ Repo cloned." "Success" } else { Write-ColorOutput "! Git clone code: $LASTEXITCODE." "Warning" } } catch { Write-ColorOutput "! Clone failed: $($_.Exception.Message)" "Error" } } else { Write-ColorOutput "Git not found. No clone." "Error" } } else { Write-ColorOutput "$customServerPath exists. Skip clone." "Info"; if (-not $SkipUpdates -and (Test-CommandExists "git") -and (Test-Path (Join-Path $customServerPath ".git"))) { Write-ColorOutput "Git pull $customServerPath..." "Info"; $loc = Get-Location; try { Set-Location $customServerPath; git pull; Write-ColorOutput "✓ Pulled." "Success" } catch { Write-ColorOutput "! Pull failed: $($_.Exception.Message)" "Warning" } finally { Set-Location $loc } } }; if (Test-Path "$customServerPath\package.json" -PathType Leaf) { Write-ColorOutput "Setup $customServerPath..." "Info"; Write-ColorOutput "Note: build may fail (Known Issue)." "Warning"; if(Test-CommandExists "npm"){ $loc = Get-Location; try { Set-Location $customServerPath; Write-ColorOutput "npm install..." "Info"; npm install; if ($LASTEXITCODE -ne 0) { throw "npm install fail" } Write-ColorOutput "✓ Deps." "Success"; $pkgJ = Get-Content ".\package.json" -Raw|ConvertFrom-Json -EA SilentlyContinue; if ($pkgJ -and $pkgJ.scripts.build) { Write-ColorOutput "npm build..." "Info"; npm run build; if($LASTEXITCODE -ne 0){Write-ColorOutput "! Build fail (Known Issue)." "Warning"}else{Write-ColorOutput "✓ Built." "Success"}}else{Write-ColorOutput "No build script." "Info"}; Write-ColorOutput "✓ Setup attempt." "Success"} catch {Write-ColorOutput "! Setup fail: $($_.Exception.Message)" "Error"} finally {Set-Location $loc}} else {Write-ColorOutput "npm not found. No setup." "Error"}}else{Write-ColorOutput "! package.json missing." "Warning"}
    
    # Step 8 (Testing)
    Write-ColorOutput "`n=== Step 8: Testing MCP Servers ===" "Header"; Test-MCPServer "desktop-commander" "npx" @("@wonderwhy-er/desktop-commander@latest"); Test-MCPServer "sequential-thinking" "npx" @("-p", "@modelcontextprotocol/server-sequential-thinking", "mcp-server-sequential-thinking"); Test-MCPServer "memory" "npx" @("-p", "@modelcontextprotocol/server-memory", "mcp-server-memory"); Test-MCPServer "filesystem" "npx" @("-p", "@modelcontextprotocol/server-filesystem", "mcp-server-filesystem"); if (Test-CommandExists "uvx") { Test-MCPServer "obsidian (uvx)" "uvx" @("mcp-obsidian") } else { Write-ColorOutput "uvx not found. Skip obsidian test." "Warning" }; $docsJs = "C:\MCP\Servers\package-documentation-mcp\build\index.js"; if (Test-Path $docsJs -PathType Leaf) { Test-MCPServer "docs-fetch (local)" "node" @($docsJs) } else { Write-ColorOutput "docs-fetch JS missing. Skip test." "Info" }

    # --- Step 9: MCP Configuration Choice & Setup ---
    Write-ColorOutput "`n=== Step 9: MCP Configuration Setup ===" "Header"
    Write-ColorOutput "Choose how to configure MCP servers for Claude Desktop and/or MCP Superassistant:" "Info"
    Write-ColorOutput "  1. Create/Update a standalone 'C:\MCP\config\mcpconfig.json' file." "Info"
    Write-ColorOutput "     (You can then manually point Claude Desktop to this file, or MCP Superassistant can use it)."
    Write-ColorOutput "  2. Directly update your Claude Desktop configuration file ('$ClaudeConfigPath') with MCP server settings." "Info"
    Write-ColorOutput "  3. Skip MCP configuration for now." "Info"
    
    $configChoice = Read-Host "Enter your choice (1, 2, or 3)"
    $mcpServerSettings = $null

    switch ($configChoice) {
        "1" {
            Write-ColorOutput "Proceeding with standalone 'C:\MCP\config\mcpconfig.json'..." "Info"
            $mcpServerSettings = Get-MCPServerDetailsFromUser
            Update-StandaloneMCPConfig -McpServerSettings $mcpServerSettings
        }
        "2" {
            Write-ColorOutput "Proceeding with direct update to Claude Desktop config '$ClaudeConfigPath'..." "Info"
            if (-not (Test-Path (Split-Path $ClaudeConfigPath -Parent) -PathType Container)) {
                Write-ColorOutput "Parent directory for Claude config ('$(Split-Path $ClaudeConfigPath -Parent)') does not exist. Cannot proceed with direct update." "Error"
            } else {
                $mcpServerSettings = Get-MCPServerDetailsFromUser
                Update-ClaudeDesktopConfig -McpServerSettings $mcpServerSettings -TargetClaudeConfigPath $ClaudeConfigPath
            }
        }
        "3" {
            Write-ColorOutput "Skipping MCP configuration step." "Info"
        }
        default {
            Write-ColorOutput "Invalid choice. Skipping MCP configuration step." "Warning"
        }
    }

    # --- Step 10: Launch MCP Superassistant Proxy & Info ---
    Write-ColorOutput "`n=== Step 10: MCP Superassistant Proxy ===" "Header"
    $superAssistantDefaultConfigPath = "c:/mcp/config/mcpconfig.json"
    $superAssistantProxyRepo = "https://github.com/srbhptl39/mcp-superassistant-proxy"
    $superAssistantExtensionStore = "https://chromewebstore.google.com/detail/mcp-superassistant/kngiafgkdnlkgmefdafaibkibegkcaef"

    Write-ColorOutput "The MCP Superassistant Proxy works with a Chrome Extension." "Info"
    Write-ColorOutput "  Chrome Extension Store: $superAssistantExtensionStore" "Info"
    Write-ColorOutput "  Proxy Server NPM Package: @srbhptl39/mcp-superassistant-proxy (GitHub: $superAssistantProxyRepo)" "Info"
    Write-ColorOutput "The proxy typically uses a configuration file (e.g., '$superAssistantDefaultConfigPath')." "Info"

    if ($configChoice -eq "1" -and (Test-Path $superAssistantDefaultConfigPath -PathType Leaf)) {
        Write-ColorOutput "  The standalone '$superAssistantDefaultConfigPath' was just created/updated." "Info"
    } elseif (-not (Test-Path $superAssistantDefaultConfigPath -PathType Leaf)) {
        Write-ColorOutput "Warning: Standalone config '$superAssistantDefaultConfigPath' not found or not chosen for update." "Warning"
        Write-ColorOutput "         The proxy might not start correctly or may use different settings if not configured." "Warning"
    }

    $launchProxyChoice = Read-Host "Do you want to run the MCP Superassistant Proxy now? (It will open in a new window) (Yes/No)"
    if ($launchProxyChoice -match '^(Y|Yes)$') {
        if (Test-CommandExists "npx") {
            # Prefer the standalone config if it exists, otherwise, the user needs to ensure proxy is configured
            $proxyConfigArg = if (Test-Path $superAssistantDefaultConfigPath -PathType Leaf) { "--config `"$superAssistantDefaultConfigPath`"" } else { "" }
            if ($proxyConfigArg -eq "") {
                 Write-ColorOutput "Warning: No specific config file path provided to proxy, it might look for a default or require manual setup." "Warning"
            }
            $commandToRun = "npx @srbhptl39/mcp-superassistant-proxy@latest $proxyConfigArg"
            Write-ColorOutput "Attempting to launch the proxy in a new window with command:" "Info"
            Write-ColorOutput "  $commandToRun" "Info"
            try {
                Start-Process powershell.exe -ArgumentList "-NoExit", "-Command", "$commandToRun"
                Write-ColorOutput "✓ MCP Superassistant Proxy launch command sent." "Success"
            } catch { Write-ColorOutput "✗ Failed to start Proxy process: $($_.Exception.Message)" "Error" }
        } else { Write-ColorOutput "npx not found. Cannot start Proxy." "Error" }
    } else {
        Write-ColorOutput "MCP Superassistant Proxy will not be started." "Info"
        Write-ColorOutput "Run manually: npx @srbhptl39/mcp-superassistant-proxy@latest --config `"$superAssistantDefaultConfigPath`"" "Info"
    }

    Write-ColorOutput "`n=== MCP Server Setup and Update Complete ===" "Header"
    Write-ColorOutput "All steps finished. Review output for warnings/errors." "Info"
    Write-ColorOutput "Next steps: Restart dependent apps, verify servers, relevant MCP config, and Superassistant Extension." "Info"
}
catch {
    Write-ColorOutput "`n=== CRITICAL ERROR DURING SETUP ===" "Error"; Write-ColorOutput $_.Exception.ToString() "Error"
    if ($_.ScriptStackTrace) { Write-ColorOutput "Script StackTrace: $($_.ScriptStackTrace)" "Error" }
    Write-ColorOutput "Script terminated." "Error"; exit 1
}
