# MCP Servers Setup and Update Script
# This script ensures all dependencies are installed and MCP servers are working

param(
    [switch]$Force,
    [switch]$SkipUpdates,
    [string]$ConfigPath = "$env:APPDATA\Claude\claude_desktop_config.json"
)

# Colors for output
$Colors = @{
    Success = "Green"
    Warning = "Yellow"
    Error = "Red"
    Info = "Cyan"
    Header = "Magenta"
}

function Write-ColorOutput {
    param([string]$Message, [string]$Color = "White")
    Write-Host $Message -ForegroundColor $Colors[$Color]
}

function Test-CommandExists {
    param([string]$Command)
    try {
        Get-Command $Command -ErrorAction Stop | Out-Null
        return $true
    }
    catch {
        return $false
    }
}

function Install-ChocoPackage {
    param([string]$Package, [string]$DisplayName)
    
    if (Test-CommandExists $Package) {
        Write-ColorOutput "✓ $DisplayName is already installed" "Success"
        return
    }
    
    Write-ColorOutput "Installing $DisplayName..." "Info"
    try {
        choco install $Package -y
        Write-ColorOutput "✓ $DisplayName installed successfully" "Success"
    }
    catch {
        Write-ColorOutput "✗ Failed to install $DisplayName" "Error"
        Write-ColorOutput $_.Exception.Message "Error"
    }
}

function Install-PythonPackage {
    param([string]$Package, [string]$DisplayName = $Package)
    
    Write-ColorOutput "Installing Python package: $DisplayName..." "Info"
    try {
        pip install --upgrade $Package
        Write-ColorOutput "✓ $DisplayName installed/updated successfully" "Success"
    }
    catch {
        Write-ColorOutput "✗ Failed to install $DisplayName" "Error"
        Write-ColorOutput $_.Exception.Message "Error"
    }
}

function Update-NodePackages {
    Write-ColorOutput "Updating Node.js global packages..." "Info"
    try {
        npm update -g
        Write-ColorOutput "✓ Node.js packages updated" "Success"
    }
    catch {
        Write-ColorOutput "✗ Failed to update Node.js packages" "Error"
    }
}

function Test-MCPServer {
    param([string]$Name, [string]$Command, [array]$Args)
    
    Write-ColorOutput "Testing MCP server: $Name..." "Info"
    try {
        $testArgs = @()
        if ($Args) {
            $testArgs = $Args + @("--help")
        } else {
            $testArgs = @("--help")
        }
        
        $result = & $Command $testArgs 2>&1
        if ($LASTEXITCODE -eq 0 -or $result -match "help|usage|options") {
            Write-ColorOutput "✓ $Name is working" "Success"
            return $true
        } else {
            Write-ColorOutput "✗ $Name test failed" "Warning"
            return $false
        }
    }
    catch {
        Write-ColorOutput "✗ $Name is not accessible" "Error"
        return $false
    }
}

function Install-UV {
    Write-ColorOutput "Installing/updating UV (Python package manager)..." "Info"
    try {
        if (Test-CommandExists "uv") {
            uv self update
        } else {
            pip install uv
        }
        Write-ColorOutput "✓ UV installed/updated successfully" "Success"
    }
    catch {
        Write-ColorOutput "✗ Failed to install UV" "Error"
    }
}

function Create-DirectoryIfNotExists {
    param([string]$Path)
    
    if (-not (Test-Path $Path)) {
        Write-ColorOutput "Creating directory: $Path" "Info"
        New-Item -ItemType Directory -Path $Path -Force | Out-Null
        Write-ColorOutput "✓ Directory created" "Success"
    }
}

# Main execution starts here
Write-ColorOutput "=== MCP Servers Setup and Update Script ===" "Header"
Write-ColorOutput "Starting comprehensive setup and update process..." "Info"

# Check if running as administrator
$isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")
if (-not $isAdmin) {
    Write-ColorOutput "Warning: Not running as administrator. Some installations may fail." "Warning"
}

# Step 1: Install Chocolatey if not present
Write-ColorOutput "`n=== Step 1: Package Manager Setup ===" "Header"
if (-not (Test-CommandExists "choco")) {
    Write-ColorOutput "Installing Chocolatey..." "Info"
    Set-ExecutionPolicy Bypass -Scope Process -Force
    [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072
    iex ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))
} else {
    Write-ColorOutput "✓ Chocolatey is already installed" "Success"
    if (-not $SkipUpdates) {
        choco upgrade chocolatey -y
    }
}

# Step 2: Install core dependencies
Write-ColorOutput "`n=== Step 2: Core Dependencies ===" "Header"

# Install Node.js
Install-ChocoPackage "nodejs" "Node.js"

# Install Python
Install-ChocoPackage "python" "Python"

# Install Git
Install-ChocoPackage "git" "Git"

# Refresh environment variables
$env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User")

# Step 3: Update core tools
if (-not $SkipUpdates) {
    Write-ColorOutput "`n=== Step 3: Updating Core Tools ===" "Header"
    
    # Update npm
    if (Test-CommandExists "npm") {
        Write-ColorOutput "Updating npm..." "Info"
        npm install -g npm@latest
        Update-NodePackages
    }
    
    # Update pip
    if (Test-CommandExists "pip") {
        Write-ColorOutput "Updating pip..." "Info"
        python -m pip install --upgrade pip
    }
    
    # Update chocolatey packages
    Write-ColorOutput "Updating Chocolatey packages..." "Info"
    choco upgrade all -y
}

# Step 4: Install Python packages and UV
Write-ColorOutput "`n=== Step 4: Python Package Setup ===" "Header"
Install-UV
Install-PythonPackage "uvx" "UVX"

# Install Python MCP packages
$pythonPackages = @(
    "mcp-server-fetch",
    "mcp-jina-reader",
    "mcp_server_time",
    "mcp-obsidian"
)

foreach ($package in $pythonPackages) {
    Install-PythonPackage $package
}

# Step 5: Create required directories
Write-ColorOutput "`n=== Step 5: Directory Setup ===" "Header"
$directories = @(
    "D:\AI_vault\Vault",
    "C:\MCP",
    "C:\MCP\Servers"
)

foreach ($dir in $directories) {
    Create-DirectoryIfNotExists $dir
}


# Step 6: Install/Update MCP Packages Permanently
Write-ColorOutput "`n=== Step 6: MCP Package Installation (Permanent) ===" "Header"

# --------------------
# NPM GLOBAL PACKAGES
# --------------------
$npmPackages = @(
    "@wonderwhy-er/desktop-commander@latest",
    "@modelcontextprotocol/server-sequential-thinking",
    "@modelcontextprotocol/server-memory",
    "@modelcontextprotocol/server-filesystem",
    "@modelcontextprotocol/server-brave-search",
    "@modelcontextprotocol/server-gemini"
)

foreach ($package in $npmPackages) {
    Write-ColorOutput "Installing/updating global NPM package: $package..." "Info"
    try {
        npm install -g $package --force
        Write-ColorOutput "✓ $package installed globally" "Success"
    }
    catch {
        Write-ColorOutput "! Failed to install $package" "Error"
    }
}

# --------------------
# UV / UVX PACKAGES
# --------------------
$uvxPackages = @(
    "mcp-obsidian",
    "mcp-server-fetch",
    "mcp-jina-reader@latest"
)

foreach ($uvx in $uvxPackages) {
    Write-ColorOutput "Installing UVX package (caches binary): $uvx..." "Info"
    try {
        uvx $uvx --help | Out-Null
        Write-ColorOutput "✓ $uvx cached via UVX" "Success"
    }
    catch {
        Write-ColorOutput "! Failed to cache $uvx via UVX" "Error"
    }
}

# --------------------
# PYTHON MODULES
# --------------------
$pythonModules = @(
    "mcp-server-time"
)

foreach ($module in $pythonModules) {
    Write-ColorOutput "Installing/updating Python module: $module..." "Info"
    try {
        pip install --upgrade $module
        Write-ColorOutput "✓ $module installed via pip" "Success"
    }
    catch {
        Write-ColorOutput "! Failed to install $module via pip" "Error"
    }
}

# --------------------
# NODE LOCAL MODULE (docs-fetch)
# --------------------
$localNodeProject = "C:\MCP\Servers\package-documentation-mcp"

if (Test-Path "$localNodeProject\package.json") {
    Write-ColorOutput "Installing local docs-fetch server dependencies..." "Info"
    try {
        Push-Location $localNodeProject
        npm install
        Pop-Location
        Write-ColorOutput "✓ Local package-documentation-mcp dependencies installed" "Success"
    }
    catch {
        Write-ColorOutput "! Failed to install local dependencies at $localNodeProject" "Error"
    }
} else {
    Write-ColorOutput "! Local docs-fetch path not found: $localNodeProject" "Warning"
}


# Step 7: Setup custom MCP server (docs-fetch)
Write-ColorOutput "`n=== Step 7: Custom MCP Server Setup ===" "Header"
$customServerPath = "C:\MCP\Servers\package-documentation-mcp"

if (-not (Test-Path "$customServerPath\build\index.js")) {
    Write-ColorOutput "Custom docs-fetch server not found. Please ensure it's properly installed at:" "Warning"
    Write-ColorOutput $customServerPath "Warning"
} else {
    Write-ColorOutput "✓ Custom docs-fetch server found" "Success"
}

# Step 8: Test MCP servers
Write-ColorOutput "`n=== Step 8: Testing MCP Servers ===" "Header"

# Test Node.js based servers
Test-MCPServer "desktop-commander" "npx" @("@wonderwhy-er/desktop-commander@latest", "--help")
Test-MCPServer "sequential-thinking" "npx" @("-y", "@modelcontextprotocol/server-sequential-thinking", "--help")
Test-MCPServer "memory" "npx" @("-y", "@modelcontextprotocol/server-memory", "--help")
Test-MCPServer "filesystem" "npx" @("-y", "@modelcontextprotocol/server-filesystem", "--help")

# Test Python/UV based servers
Test-MCPServer "obsidian" "uvx" @("mcp-obsidian", "--help")
Test-MCPServer "fetch" "uvx" @("mcp-server-fetch", "--help")
Test-MCPServer "jina-reader" "uvx" @("mcp-jina-reader@latest", "--help")

# Test Python module
try {
    python -c "import mcp_server_time; print('✓ mcp_server_time module is available')"
    Write-ColorOutput "✓ mcp_server_time is working" "Success"
}
catch {
    Write-ColorOutput "✗ mcp_server_time test failed" "Error"
}

# Step 9: Validate configuration file
Write-ColorOutput "`n=== Step 9: Configuration Validation ===" "Header"
if (Test-Path $ConfigPath) {
    Write-ColorOutput "✓ Claude configuration file found at: $ConfigPath" "Success"
    try {
        $config = Get-Content $ConfigPath | ConvertFrom-Json
        $serverCount = $config.mcpServers.PSObject.Properties.Count
        Write-ColorOutput "✓ Configuration contains $serverCount MCP servers" "Success"
    }
    catch {
        Write-ColorOutput "✗ Configuration file appears to be invalid JSON" "Error"
    }
} else {
    Write-ColorOutput "! Configuration file not found at: $ConfigPath" "Warning"
    Write-ColorOutput "Please ensure Claude Desktop is installed and configured" "Warning"
}

# Step 10: Final system check
Write-ColorOutput "`n=== Step 10: Final System Check ===" "Header"
$tools = @{
    "node" = "Node.js"
    "npm" = "NPM"
    "npx" = "NPX"
    "python" = "Python"
    "pip" = "Pip"
    "uv" = "UV"
    "uvx" = "UVX"
    "git" = "Git"
}

$allGood = $true
foreach ($tool in $tools.GetEnumerator()) {
    if (Test-CommandExists $tool.Key) {
        $version = & $tool.Key --version 2>$null
        Write-ColorOutput "✓ $($tool.Value): $version" "Success"
    } else {
        Write-ColorOutput "✗ $($tool.Value) not found in PATH" "Error"
        $allGood = $false
    }
}

# Summary
Write-ColorOutput "`n=== Setup Complete ===" "Header"
if ($allGood) {
    Write-ColorOutput "✓ All core dependencies are installed and accessible" "Success"
    Write-ColorOutput "✓ Your MCP servers should now work properly" "Success"
    Write-ColorOutput "`nNext steps:" "Info"
    Write-ColorOutput "1. Restart Claude Desktop if it's running" "Info"
    Write-ColorOutput "2. Test your MCP servers in Claude" "Info"
    Write-ColorOutput "3. Check the Claude Desktop logs if any servers fail to start" "Info"
} else {
    Write-ColorOutput "! Some dependencies may be missing or not in PATH" "Warning"
    Write-ColorOutput "! You may need to restart your terminal/PowerShell session" "Warning"
    Write-ColorOutput "! Or add the missing tools to your system PATH manually" "Warning"
}

Write-ColorOutput "`nScript completed!" "Header"