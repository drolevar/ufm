#!/bin/bash
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

UFM_PATCH_MARKER="# UFM_PATCHED"

# Step 1: Check prerequisites
MISSING=""
command -v gcc    >/dev/null 2>&1 || MISSING="$MISSING gcc"
command -v nasm   >/dev/null 2>&1 || MISSING="$MISSING nasm"
command -v iasl   >/dev/null 2>&1 || MISSING="$MISSING iasl"
command -v python3 >/dev/null 2>&1 || MISSING="$MISSING python3"

if [ -n "$MISSING" ]; then
    echo "ERROR: Missing required tools:$MISSING"
    echo ""
    echo "Install them:"
    echo "  Arch/CachyOS: pacman -S nasm acpica python"
    echo "  Ubuntu/Debian: apt install gcc nasm iasl uuid-dev python3"
    exit 1
fi

# Step 2: Init submodules
echo "==> Initializing submodules..."
git submodule update --init --recursive

# Step 3: Compile BaseTools
if [ ! -f edk2/BaseTools/Source/C/bin/GenFw ]; then
    echo "==> Compiling EDK2 BaseTools..."
    make -j$(nproc) -C edk2/BaseTools
else
    echo "==> BaseTools already compiled, skipping."
fi

# Step 4: Create symlinks
echo "==> Creating symlinks..."

ln -sfn ../../../Library/UefiShellUfmCommandLib \
    edk2/ShellPkg/Library/UefiShellUfmCommandLib

ln -sfn ../../../Application/UfmApp \
    edk2/ShellPkg/Application/UfmApp

mkdir -p edk2/ShellPkg/Include/Library
ln -sfn ../../../../Include/Library/UfmCommandLib.h \
    edk2/ShellPkg/Include/Library/UfmCommandLib.h

# Step 5: Patch ShellPkg.dsc
DSC="edk2/ShellPkg/ShellPkg.dsc"
if ! grep -q "$UFM_PATCH_MARKER" "$DSC"; then
    echo "==> Patching ShellPkg.dsc..."

    # Add UfmCommandLib to [LibraryClasses.common]
    sed -i "/^\[LibraryClasses.common\]/a\\
$UFM_PATCH_MARKER\n  UfmCommandLib|ShellPkg/Library/UefiShellUfmCommandLib/UefiShellUfmCommandLib.inf" "$DSC"

    # Add UfmApp.inf to [Components] section
    sed -i "/^\[Components\]/a\\
$UFM_PATCH_MARKER\n  ShellPkg/Application/UfmApp/UfmApp.inf" "$DSC"

    # Add UFM library to both Shell.inf <LibraryClasses> blocks
    sed -i "/<LibraryClasses>/a\\
      NULL|ShellPkg/Library/UefiShellUfmCommandLib/UefiShellUfmCommandLib.inf" "$DSC"
else
    echo "==> ShellPkg.dsc already patched, skipping."
fi

# Step 6: Patch ShellPkg.dec
DEC="edk2/ShellPkg/ShellPkg.dec"
if ! grep -q "$UFM_PATCH_MARKER" "$DEC"; then
    echo "==> Patching ShellPkg.dec..."

    sed -i "/^\[LibraryClasses\]/a\\
$UFM_PATCH_MARKER\n  UfmCommandLib|Include/Library/UfmCommandLib.h" "$DEC"
else
    echo "==> ShellPkg.dec already patched, skipping."
fi

echo ""
echo "Bootstrap complete. Run 'make' to build."
