#!/usr/bin/env bash
#
# run_matlab.sh — launch MATLAB with the environment PhreeqcMatlab needs on Linux.
#
# Why this exists:
#   * PhreeqcRM/IPhreeqc 3.8.6 compiled with a modern system GCC require a newer
#     libstdc++ (GLIBCXX_3.4.32) than the one MATLAB bundles. Without this,
#     loadlibrary fails with "GLIBCXX_3.4.32 not found". LD_PRELOAD forces MATLAB
#     to use the system libstdc++ (which is backward compatible).
#   * PHREEQCMATLAB_LIB_PATH lets startup.m copy the locally installed .so files
#     into libs/ instead of downloading them.
#
# Usage:
#   ./run_matlab.sh                       # interactive MATLAB
#   ./run_matlab.sh -batch "runtests('tests')"   # headless, e.g. for CI
#
# Override the defaults by exporting the variables before calling, e.g.:
#   PHREEQCMATLAB_LIB_PATH=/opt/phreeqc/lib ./run_matlab.sh

set -euo pipefail

# Locate the system libstdc++ (skip MATLAB's bundled copy).
find_system_libstdcpp() {
    for cand in \
        /usr/lib/x86_64-linux-gnu/libstdc++.so.6 \
        /usr/lib64/libstdc++.so.6 \
        /usr/lib/libstdc++.so.6; do
        [ -f "$cand" ] && { echo "$cand"; return 0; }
    done
    # Fall back to whatever the linker resolves.
    ldconfig -p 2>/dev/null | awk '/libstdc\+\+\.so\.6/ {print $NF; exit}'
}

: "${PHREEQCMATLAB_LIB_PATH:=/usr/local/lib}"
export PHREEQCMATLAB_LIB_PATH

SYS_LIBSTDCPP="${PHREEQCMATLAB_LIBSTDCPP:-$(find_system_libstdcpp)}"
if [ -n "${SYS_LIBSTDCPP:-}" ] && [ -f "$SYS_LIBSTDCPP" ]; then
    export LD_PRELOAD="${SYS_LIBSTDCPP}${LD_PRELOAD:+:$LD_PRELOAD}"
else
    echo "warning: could not locate a system libstdc++.so.6; if loadlibrary fails" >&2
    echo "         with a GLIBCXX error, set PHREEQCMATLAB_LIBSTDCPP to its path." >&2
fi

MATLAB_BIN="${MATLAB_BIN:-matlab}"
exec "$MATLAB_BIN" "$@"
