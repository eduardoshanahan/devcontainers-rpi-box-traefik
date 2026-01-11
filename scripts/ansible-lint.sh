#!/bin/sh

set -eu

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
ANSIBLE_ROOT="${REPO_ROOT}/src"
ANSIBLE_CFG="${ANSIBLE_ROOT}/ansible.cfg"

make_temp_file() {
    tmp_dir="${TMPDIR:-/tmp}"
    umask 077
    i=0
    while :; do
        i=$((i + 1))
        path="${tmp_dir}/ansible-lint.$$.$i"
        if (set -C; : > "$path") 2>/dev/null; then
            printf '%s' "$path"
            return 0
        fi
        [ "$i" -ge 100 ] && return 1
    done
}

print_filtered_stderr() {
    # Filter known noisy upstream DeprecationWarnings from pathspec used by ansible-lint.
    # Keep all other output intact.
    awk '
      /DeprecationWarning: GitWildMatchPattern/ { skip_next=1; next }
      skip_next && /^  / { skip_next=0; next }
      { skip_next=0; print }
    ' "$1" >&2
}

if [ $# -ge 1 ]; then
    PLAYBOOK="$1"
else
    PLAYBOOK="${LINT_PLAYBOOK:-}"
fi

if [ -z "$PLAYBOOK" ]; then
    printf 'Usage: %s /path/to/playbook.yml\n' "$0" >&2
    printf 'Or set LINT_PLAYBOOK in the environment.\n' >&2
    exit 1
fi

if ! command -v ansible-lint >/dev/null 2>&1; then
    printf '%s\n' "ansible-lint command not found; run this script inside the devcontainer." >&2
    exit 1
fi

export ANSIBLE_CONFIG="$ANSIBLE_CFG"

printf '%s\n' ">>> Running ansible-lint on ${PLAYBOOK}"
stderr_file="$(make_temp_file)"
if [ -z "$stderr_file" ]; then
    printf '%s\n' "Failed to create temp file for stderr capture." >&2
    exit 1
fi

lint_rc=0
if command -v python3 >/dev/null 2>&1 && python3 -c "import ansiblelint" >/dev/null 2>&1; then
    python3 -W "ignore::DeprecationWarning" -m ansiblelint "$PLAYBOOK" 2>"$stderr_file" || lint_rc=$?
else
    PYTHONWARNINGS="ignore::DeprecationWarning" ansible-lint "$PLAYBOOK" 2>"$stderr_file" || lint_rc=$?
fi

print_filtered_stderr "$stderr_file"
rm -f "$stderr_file"
exit "$lint_rc"
