<#
    Analysis of Household Surveys -- one-step install for Windows.

    Open PowerShell (Start menu -> type "powershell") and run:

        cd $HOME\Downloads
        powershell -ExecutionPolicy Bypass -File .\install_surveys.ps1

    The -ExecutionPolicy Bypass is needed because Windows blocks
    downloaded scripts by default. It applies to this one run only and
    changes nothing on your machine.

    What it does, in order:
      1. Finds conda, or installs Miniforge into %USERPROFILE%\miniforge3.
      2. Creates a `surveys' environment (Python 3.12 + git).
      3. pip installs LSMS_Library, datamat and jupyterlab.
      4. Asks for your World Bank Microdata API key and stores it where
         the library actually looks for it -- which on Windows is under
         %LOCALAPPDATA%, not your home directory.
      5. Checks the whole chain by reading real survey data.

    Safe to run more than once: every step is skipped if already done.
    It never runs `conda init' and so never changes your PowerShell
    profile.

    GnuPG is deliberately NOT installed. LSMS_Library decrypts its own S3
    read credentials in pure Python (Fernet, via `cryptography', a hard
    dependency) as of LSMS_Library GH #741. Gpg4win is no longer needed.
#>

#Requires -Version 5.1
[CmdletBinding()]
param(
    [string] $EnvName       = $(if ($env:SURVEYS_ENV) { $env:SURVEYS_ENV } else { 'surveys' }),
    [string] $MiniforgeHome = $(if ($env:MINIFORGE_HOME) { $env:MINIFORGE_HOME } else { Join-Path $HOME 'miniforge3' })
)

$ErrorActionPreference = 'Stop'
$PythonVersion = '3.12'

function Write-Step { param($m) Write-Host "`n==> $m" -ForegroundColor White }
function Write-Ok   { param($m) Write-Host "    ok  $m" -ForegroundColor Green }
function Write-Warn { param($m) Write-Host "    !!  $m" -ForegroundColor Yellow }
function Stop-Bad   { param($m) Write-Host "`n    xx  $m`n" -ForegroundColor Red; exit 1 }

# Run a Python snippet held in a here-string, without PowerShell mangling it.
function Invoke-Py {
    param([string] $Exe, [string] $Code, [switch] $PassThru)
    $tmp = [System.IO.Path]::GetTempFileName() + '.py'
    try {
        [System.IO.File]::WriteAllText($tmp, $Code, (New-Object System.Text.UTF8Encoding $false))
        if ($PassThru) { & $Exe $tmp } else { & $Exe $tmp | Out-Host }
        return $LASTEXITCODE
    } finally { Remove-Item $tmp -ErrorAction SilentlyContinue }
}

# --- 0. what machine is this ------------------------------------------------

$arch = $env:PROCESSOR_ARCHITECTURE
switch ($arch) {
    'AMD64' { $mfArch = 'x86_64' }
    'ARM64' { $mfArch = 'arm64'  }
    default { Stop-Bad "Unsupported processor: $arch. Follow the manual steps on the install page." }
}

Write-Step "Analysis of Household Surveys -- installing on Windows/$mfArch"

# TLS 1.2 for Invoke-WebRequest on older Windows PowerShell.
try { [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12 } catch {}

# --- 1. conda ---------------------------------------------------------------

Write-Step 'Looking for conda'

function Find-Conda {
    $onPath = Get-Command conda.exe -ErrorAction SilentlyContinue
    if ($onPath) { return $onPath.Source }
    $candidates = @(
        (Join-Path $MiniforgeHome     'Scripts\conda.exe'),
        (Join-Path $HOME 'mambaforge\Scripts\conda.exe'),
        (Join-Path $HOME 'miniconda3\Scripts\conda.exe'),
        (Join-Path $HOME 'anaconda3\Scripts\conda.exe'),
        'C:\ProgramData\miniforge3\Scripts\conda.exe',
        'C:\ProgramData\Anaconda3\Scripts\conda.exe'
    )
    foreach ($c in $candidates) { if (Test-Path $c) { return $c } }
    return $null
}

$conda = Find-Conda
if ($conda) {
    Write-Ok "found $conda"
} else {
    Write-Warn "no conda found; installing Miniforge into $MiniforgeHome"
    if (Test-Path $MiniforgeHome) {
        Stop-Bad "$MiniforgeHome exists but holds no conda. Rename it and re-run."
    }

    $installer = Join-Path $env:TEMP 'Miniforge3-Install.exe'
    $url = "https://github.com/conda-forge/miniforge/releases/latest/download/Miniforge3-Windows-$mfArch.exe"
    Write-Host "    downloading $url"
    try {
        Invoke-WebRequest -Uri $url -OutFile $installer -UseBasicParsing
    } catch {
        Stop-Bad "Download failed: $($_.Exception.Message)"
    }

    # NSIS silent install. /D= must come LAST and must not be quoted, even
    # if the path contains spaces -- that is an NSIS rule, not a typo.
    $mfArgs = @('/InstallationType=JustMe', '/RegisterPython=0', '/S', "/D=$MiniforgeHome")
    Write-Host '    installing (a few minutes, no progress bar)'
    $p = Start-Process -FilePath $installer -ArgumentList $mfArgs -Wait -PassThru
    Remove-Item $installer -ErrorAction SilentlyContinue
    if ($p.ExitCode -ne 0) { Stop-Bad "Miniforge installer exited with code $($p.ExitCode)." }

    $conda = Join-Path $MiniforgeHome 'Scripts\conda.exe'
    if (-not (Test-Path $conda)) { Stop-Bad "Miniforge installed but $conda is missing." }
    Write-Ok 'installed Miniforge'
}

$condaRoot = Split-Path (Split-Path $conda -Parent) -Parent

# --- 2. the environment -----------------------------------------------------

Write-Step "Creating the ``$EnvName`` environment"

$envPath = Join-Path $condaRoot "envs\$EnvName"
$py      = Join-Path $envPath 'python.exe'

if (Test-Path $py) {
    Write-Ok "``$EnvName`` already exists; leaving it alone"
} else {
    # `git' is here because LSMS_Library shells out to it; gnupg is NOT
    # (see the header).
    & $conda create -y -n $EnvName "python=$PythonVersion" git | Out-Host
    if ($LASTEXITCODE -ne 0) { Stop-Bad 'Could not create the environment.' }
    if (-not (Test-Path $py)) { Stop-Bad "Environment created but $py is missing." }
    Write-Ok 'created'
}

# We never call `conda activate'. Invoking the environment's python.exe by
# full path does the same job and needs no `conda init', so this script
# leaves your PowerShell profile untouched.
Write-Ok "python is $py"

# --- 3. the packages --------------------------------------------------------

Write-Step 'Installing LSMS_Library, datamat and jupyterlab'
Write-Host "    This is the slow step: about 1.3 GB. Leave it running.`n"

# datamat is imported by sessions 4-6 and is a dependency of neither
# LSMS_Library nor CFEDemands, so it has to be named explicitly.
& $py -m pip install --upgrade --quiet pip | Out-Host
& $py -m pip install --upgrade LSMS_Library datamat jupyterlab | Out-Host
if ($LASTEXITCODE -ne 0) { Stop-Bad 'pip install failed. Scroll up for the first red ERROR line.' }
Write-Ok 'installed'

$versions = @'
import importlib.metadata as md
for pkg in ("lsms-library", "CFEDemands", "datamat"):
    try:
        print(f"    {pkg:14s} {md.version(pkg)}")
    except md.PackageNotFoundError:
        print(f"    {pkg:14s} MISSING")
import lsms_library  # noqa: F401
'@
if ((Invoke-Py -Exe $py -Code $versions) -ne 0) {
    Stop-Bad 'The library will not import. Send the message above with your report.'
}

# --- 4. the World Bank Microdata key ---------------------------------------

Write-Step 'World Bank Microdata API key'

# On Windows the library reads its config from %LOCALAPPDATA%, NOT from
# your home directory, so we ask the library's own resolution rather than
# guessing. This mirrors lsms_library/config.py.
$pathCode = @'
import os, pathlib
override = os.environ.get("LSMS_CONFIG_DIR", "").strip()
if override:
    d = pathlib.Path(override).expanduser()
else:
    try:
        import platformdirs
        d = platformdirs.user_config_path("lsms_library")
    except ImportError:
        d = pathlib.Path.home() / ".config" / "lsms_library"
print(d / "config.yml")
'@
$configFile = (Invoke-Py -Exe $py -Code $pathCode -PassThru | Select-Object -Last 1)

$haveKeyCode = @'
try:
    from lsms_library import config
    print("yes" if config.microdata_api_key() else "no")
except Exception:
    print("no")
'@
$haveKey = (Invoke-Py -Exe $py -Code $haveKeyCode -PassThru | Select-Object -Last 1)

if ($haveKey -eq 'yes') {
    Write-Ok "a key is already configured in $configFile"
} elseif ($env:MICRODATA_API_KEY) {
    Write-Ok 'using the MICRODATA_API_KEY already in your environment'
} else {
    Write-Host @'
    The key is free and takes about five minutes. It is what gives you
    access to the data -- both direct World Bank downloads and the fast
    shared cache.

      1. Register at  https://microdata.worldbank.org/auth/register
      2. Click the activation link they email you (check spam).
      3. Log in, then the person icon at top right -> Profile.
      4. Scroll to "API keys" and click "Generate API key".
      5. Copy it AT ONCE -- 64 characters, shown only once.

    Paste it below, or press Enter to skip and add it later.
'@
    $wbKey = Read-Host '    Key'
    if ([string]::IsNullOrWhiteSpace($wbKey)) {
        Write-Warn "skipped; add it later to $configFile as"
        Write-Warn '  microdata_api_key: "your-key-here"'
    } else {
        $env:WB_KEY = $wbKey.Trim()
        $writeCode = @'
import os, pathlib
key = os.environ["WB_KEY"].strip()
override = os.environ.get("LSMS_CONFIG_DIR", "").strip()
if override:
    d = pathlib.Path(override).expanduser()
else:
    try:
        import platformdirs
        d = platformdirs.user_config_path("lsms_library")
    except ImportError:
        d = pathlib.Path.home() / ".config" / "lsms_library"
d.mkdir(parents=True, exist_ok=True)
path = d / "config.yml"

# Preserve anything already in the file; only replace our one setting.
data = {}
if path.exists():
    try:
        import yaml
        data = yaml.safe_load(path.read_text()) or {}
    except Exception:
        backup = path.with_suffix(".yml.bak")
        backup.write_text(path.read_text())
        print(f"    (unreadable config kept at {backup})")
        data = {}
if not isinstance(data, dict):
    data = {}
data["microdata_api_key"] = key

import yaml
path.write_text(yaml.safe_dump(data, default_flow_style=False, sort_keys=True))
print(f"    saved to {path}")
'@
        $rc = Invoke-Py -Exe $py -Code $writeCode
        Remove-Item Env:\WB_KEY -ErrorAction SilentlyContinue
        if ($rc -ne 0) { Stop-Bad 'Could not write the key.' }
        Write-Ok 'key stored'
    }
}

# --- 5. does it actually work ----------------------------------------------

Write-Step 'Checking that it works (this reads real survey data)'

$checkCode = @'
import sys, warnings
warnings.filterwarnings("ignore")
try:
    import lsms_library as ll
    g = ll.Country("GhanaLSS")
    # `waves' is a property, not a method -- see the worked example on the
    # install page.  Calling it raises TypeError: 'list' object is not callable.
    print(f"    GLSS waves: {g.waves}")
    roster = g.household_roster()
    print(f"    household roster: {roster.shape[0]:,} people x {roster.shape[1]} columns")
except Exception as exc:
    print(f"    FAILED: {type(exc).__name__}: {exc}", file=sys.stderr)
    sys.exit(1)
'@
$check = Invoke-Py -Exe $py -Code $checkCode

Write-Host ''
if ($check -eq 0) {
    Write-Host '==> Done.' -ForegroundColor Green
    Write-Host @"

    To use it, every time, open the Miniforge Prompt from the Start menu
    and run:

        conda activate $EnvName
        jupyter lab

    (Or from PowerShell, without activating anything:
        & "$py" -m jupyter lab
    )

    The workshop notebooks are at
        https://github.com/ligon/hhsurveys/tree/main/notebooks

"@
} else {
    Write-Host '==> Installed, but the data check failed.' -ForegroundColor Yellow
    Write-Host @'

    The software is in place; something stopped it reaching the data.
    The usual cause is a missing or mistyped API key.

    That is worth reporting, and the report is useful to us:

        https://github.com/ligon/hhsurveys/issues

    Please paste the FAILED line above, and say which machine you are on.

'@
    exit 1
}
