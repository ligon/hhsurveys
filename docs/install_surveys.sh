#!/usr/bin/env bash
#
# Analysis of Household Surveys -- one-step install for macOS and Linux.
#
#   curl -fsSL https://hhsurveys-workshop.ligonresearch.org/install_surveys.sh -o install_surveys.sh
#   bash install_surveys.sh
#
# What it does, in order:
#   1. Finds conda, or installs Miniforge into ~/miniforge3 if there is none.
#   2. Creates a `surveys' environment (Python 3.12 + git).
#   3. pip installs LSMS_Library, datamat and jupyterlab.
#   4. Asks for your World Bank Microdata API key and stores it where the
#      library actually looks for it.
#   5. Checks that the whole chain works by reading real survey data.
#
# It is safe to run more than once: every step is skipped if already done.
# It never touches an existing conda installation beyond creating one
# environment, and it never edits your shell startup files.
#
# GnuPG is deliberately NOT installed.  LSMS_Library decrypts its own S3
# read credentials in pure Python (Fernet, via `cryptography', a hard
# dependency) as of LSMS_Library GH #741.  The gpg binary, which macOS and
# Windows do not ship, is only a fallback for wheels built before that.
#
set -euo pipefail

ENV_NAME="${SURVEYS_ENV:-surveys}"
PYTHON_VERSION="3.12"
MINIFORGE_HOME="${MINIFORGE_HOME:-$HOME/miniforge3}"

BOLD=""; PLAIN=""; RED=""; GREEN=""; YELLOW=""
if [ -t 1 ] && command -v tput >/dev/null 2>&1 && [ "$(tput colors 2>/dev/null || echo 0)" -ge 8 ]; then
    BOLD="$(tput bold)"; PLAIN="$(tput sgr0)"
    RED="$(tput setaf 1)"; GREEN="$(tput setaf 2)"; YELLOW="$(tput setaf 3)"
fi

step()  { printf '\n%s==> %s%s\n' "$BOLD" "$*" "$PLAIN"; }
ok()    { printf '%s    ok%s  %s\n' "$GREEN" "$PLAIN" "$*"; }
warn()  { printf '%s    !!%s  %s\n' "$YELLOW" "$PLAIN" "$*"; }
die()   { printf '\n%s    xx%s  %s\n\n' "$RED" "$PLAIN" "$*" >&2; exit 1; }

# --- 0. what machine is this ------------------------------------------------

case "$(uname -s)" in
    Darwin) OS="MacOSX" ;;
    Linux)  OS="Linux" ;;
    *)      die "This script handles macOS and Linux. On Windows use install_surveys.ps1." ;;
esac
ARCH="$(uname -m)"
case "$ARCH" in
    x86_64|arm64|aarch64) ;;
    *) die "Unsupported processor: $ARCH. Follow the manual steps on the install page." ;;
esac

step "Analysis of Household Surveys -- installing on $OS/$ARCH"

command -v curl >/dev/null 2>&1 || die "\`curl' is required and was not found."

# --- 1. conda ---------------------------------------------------------------

step "Looking for conda"

CONDA_SH=""
find_conda_sh() {
    # An already-active conda tells us its root directly.
    if [ -n "${CONDA_EXE:-}" ] && [ -x "${CONDA_EXE}" ]; then
        local root; root="$(dirname "$(dirname "$CONDA_EXE")")"
        [ -f "$root/etc/profile.d/conda.sh" ] && { CONDA_SH="$root/etc/profile.d/conda.sh"; return 0; }
    fi
    if command -v conda >/dev/null 2>&1; then
        local base; base="$(conda info --base 2>/dev/null || true)"
        [ -n "$base" ] && [ -f "$base/etc/profile.d/conda.sh" ] && { CONDA_SH="$base/etc/profile.d/conda.sh"; return 0; }
    fi
    local candidate
    for candidate in "$MINIFORGE_HOME" "$HOME/mambaforge" "$HOME/miniconda3" \
                     "$HOME/anaconda3" "/opt/homebrew/Caskroom/miniforge/base" \
                     "/opt/miniforge3" "/opt/conda"; do
        [ -f "$candidate/etc/profile.d/conda.sh" ] && { CONDA_SH="$candidate/etc/profile.d/conda.sh"; return 0; }
    done
    return 1
}

if find_conda_sh; then
    ok "found $(dirname "$(dirname "$CONDA_SH")")"
else
    warn "no conda found; installing Miniforge into $MINIFORGE_HOME"
    [ -e "$MINIFORGE_HOME" ] && die "$MINIFORGE_HOME exists but holds no conda. Move it aside and re-run."

    INSTALLER="$(mktemp -t miniforge.XXXXXX).sh"
    trap 'rm -f "$INSTALLER"' EXIT
    URL="https://github.com/conda-forge/miniforge/releases/latest/download/Miniforge3-${OS}-${ARCH}.sh"
    printf '    downloading %s\n' "$URL"
    curl -fL --progress-bar "$URL" -o "$INSTALLER" \
        || die "Download failed. Check your connection and try again."

    # -b batch (no prompts, no shell init), -p prefix.  We deliberately do
    # not run `conda init': this script should not rewrite anyone's .bashrc
    # or .zshrc behind their back.
    bash "$INSTALLER" -b -p "$MINIFORGE_HOME" >/dev/null \
        || die "Miniforge installer failed."
    rm -f "$INSTALLER"; trap - EXIT

    CONDA_SH="$MINIFORGE_HOME/etc/profile.d/conda.sh"
    [ -f "$CONDA_SH" ] || die "Miniforge installed but $CONDA_SH is missing."
    ok "installed Miniforge"
fi

# shellcheck disable=SC1090
. "$CONDA_SH"

# --- 2. the environment -----------------------------------------------------

step "Creating the \`$ENV_NAME' environment"

if conda env list | awk '{print $1}' | grep -qx "$ENV_NAME"; then
    ok "\`$ENV_NAME' already exists; leaving it alone"
else
    # `git' is here because LSMS_Library shells out to it; `gnupg' is NOT
    # (see the header).
    conda create -y -n "$ENV_NAME" "python=$PYTHON_VERSION" git \
        || die "Could not create the environment."
    ok "created"
fi

conda activate "$ENV_NAME" || die "Could not activate \`$ENV_NAME'."
PY="$(command -v python)"
ok "python is $PY"

# --- 3. the packages --------------------------------------------------------

step "Installing LSMS_Library, datamat and jupyterlab"
printf '    This is the slow step: about 1.3 GB. Leave it running.\n\n'

# datamat is imported by sessions 4-6 and is a dependency of neither
# LSMS_Library nor CFEDemands, so it has to be named explicitly.
python -m pip install --upgrade --quiet pip || true
python -m pip install --upgrade LSMS_Library datamat jupyterlab \
    || die "pip install failed. Scroll up for the first red ERROR line."
ok "installed"

python - <<'PY' || die "The library will not import. Send the message above with your report."
import importlib.metadata as md
for pkg in ("lsms-library", "CFEDemands", "datamat"):
    try:
        print(f"    {pkg:14s} {md.version(pkg)}")
    except md.PackageNotFoundError:
        print(f"    {pkg:14s} MISSING")
import lsms_library  # noqa: F401
PY

# --- 4. the World Bank Microdata key ---------------------------------------

step "World Bank Microdata API key"

# The config location is platform-dependent -- ~/.config on Linux but
# ~/Library/Application Support on macOS -- so we ask the library's own
# resolution rather than guessing.  This mirrors lsms_library/config.py.
read_config_path() {
    python - <<'PY'
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
PY
}

CONFIG_FILE="$(read_config_path)"

HAVE_KEY="$(python - <<'PY'
try:
    from lsms_library import config
    print("yes" if config.microdata_api_key() else "no")
except Exception:
    print("no")
PY
)"

if [ "$HAVE_KEY" = "yes" ]; then
    ok "a key is already configured in $CONFIG_FILE"
elif [ -n "${MICRODATA_API_KEY:-}" ]; then
    ok "using the MICRODATA_API_KEY already in your environment"
elif [ ! -t 0 ]; then
    warn "no key configured, and this is not an interactive terminal."
    warn "Re-run without piping, or set MICRODATA_API_KEY, or add it later:"
    warn "  $CONFIG_FILE"
else
    cat <<'EOF'
    The key is free and takes about five minutes. It is what gives you
    access to the data -- both direct World Bank downloads and the fast
    shared cache.

      1. Register at  https://microdata.worldbank.org/auth/register
      2. Click the activation link they email you (check spam).
      3. Log in, then the person icon at top right -> Profile.
      4. Scroll to "API keys" and click "Generate API key".
      5. Copy it AT ONCE -- 64 characters, shown only once.

    Paste it below, or press Enter to skip and add it later.

EOF
    printf '    Key: '
    read -r WB_KEY || WB_KEY=""
    if [ -z "$WB_KEY" ]; then
        warn "skipped; add it later to $CONFIG_FILE as"
        warn "  microdata_api_key: \"your-key-here\""
    else
        WB_KEY="$WB_KEY" python - <<'PY' || die "Could not write the key."
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
try:
    path.chmod(0o600)
except OSError:
    pass
print(f"    saved to {path}")
PY
        ok "key stored"
    fi
fi

# --- 5. does it actually work ----------------------------------------------

step "Checking that it works (this reads real survey data)"

set +e
python - <<'PY'
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
PY
CHECK=$?
set -e

echo
if [ "$CHECK" -eq 0 ]; then
    printf '%s==> Done.%s\n\n' "$BOLD$GREEN" "$PLAIN"
    cat <<EOF
    To use it, every time:

        conda activate $ENV_NAME
        jupyter lab

    The workshop notebooks are at
        https://github.com/ligon/hhsurveys/tree/main/notebooks

EOF
else
    printf '%s==> Installed, but the data check failed.%s\n\n' "$BOLD$YELLOW" "$PLAIN"
    cat <<EOF
    The software is in place; something stopped it reaching the data.
    The usual cause is a missing or mistyped API key.

    That is worth reporting, and the report is useful to us:

        https://github.com/ligon/hhsurveys/issues

    Please paste the FAILED line above, and say which machine you are on.

EOF
    exit 1
fi
