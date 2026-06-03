#!/usr/bin/env bash
set -euo pipefail

TARGET_DIR=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --help|-h)
      cat <<'EOF'
Usage:
  ./scripts/story-agent-init.sh [target-directory]

Copies story-agent assets into target-directory (default: current directory).
Autodetects GitHub Copilot (.github/), Cursor (.cursor/), Roo (.roo/),
Windsurf (.windsurf/), and Claude (CLAUDE.md) and installs matching IDE wrappers.
EOF
      exit 0
      ;;
    --*)
      echo "ERROR: unknown option: $1" >&2
      exit 1
      ;;
    *)
      if [[ -n "${TARGET_DIR}" ]]; then
        echo "ERROR: multiple target directories provided" >&2
        exit 1
      fi
      TARGET_DIR="$1"
      shift
      ;;
  esac
done

TARGET_DIR="${TARGET_DIR:-.}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SOURCE_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
ASSET_ROOT="${SOURCE_ROOT}/.ai/story-agent"
mkdir -p "${TARGET_DIR}"
TARGET_ROOT="$(cd "${TARGET_DIR}" && pwd)"

if [[ ! -d "${ASSET_ROOT}" ]]; then
  echo "ERROR: story-agent assets not found at ${ASSET_ROOT}" >&2
  exit 1
fi

created_files=0
skipped_files=0

copy_tree_additive() {
  local source_dir="$1"
  local destination_dir="$2"

  mkdir -p "${destination_dir}"

  while IFS= read -r -d '' dir_path; do
    local relative="${dir_path#${source_dir}/}"
    [[ "${relative}" == "${dir_path}" ]] && relative=""
    mkdir -p "${destination_dir}/${relative}"
  done < <(find "${source_dir}" -type d -print0)

  while IFS= read -r -d '' file_path; do
    local relative="${file_path#${source_dir}/}"
    local target_file="${destination_dir}/${relative}"
    if [[ -e "${target_file}" ]]; then
      skipped_files=$((skipped_files + 1))
      continue
    fi

    cp "${file_path}" "${target_file}"
    created_files=$((created_files + 1))
  done < <(find "${source_dir}" -type f -print0)
}

ensure_story_agent_paragraph() {
  local target_file="$1"
  local paragraph

  paragraph=$(cat <<'EOF'

## Story Agent

This repo uses story-agent for AI-assisted story planning. Run `/story-agent`, `/explain-story`, or `/plan-story` in your IDE's AI chat. Input can be a tracker ID (e.g. PROJ-123), a local file path, or inline story text. Agents live in `.ai/story-agent/agents/`.
EOF
)

  mkdir -p "$(dirname "${target_file}")"

  if [[ ! -f "${target_file}" ]]; then
    printf "%s\n" "${paragraph}" > "${target_file}"
    created_files=$((created_files + 1))
    return
  fi

  if grep -Fq ".ai/story-agent/agents/" "${target_file}"; then
    return
  fi

  printf "%s\n" "${paragraph}" >> "${target_file}"
}

ensure_gitignore_block() {
  local gitignore_file="${TARGET_ROOT}/.gitignore"
  local start_marker="# story-agent"

  if [[ ! -f "${gitignore_file}" ]]; then
    cat >"${gitignore_file}" <<'EOF'
# story-agent
.ai/story-agent/
# /story-agent
EOF
    created_files=$((created_files + 1))
    return
  fi

  if grep -Fq "${start_marker}" "${gitignore_file}"; then
    return
  fi

  cat >>"${gitignore_file}" <<'EOF'

# story-agent
.ai/story-agent/
# /story-agent
EOF
}

merge_mcp_servers_into_file() {
  local mcp_file="$1"
  local servers_template="${ASSET_ROOT}/templates/vscode/mcp.json"

  mkdir -p "$(dirname "${mcp_file}")"

  python3 - "${mcp_file}" "${servers_template}" <<'PY'
import json
import pathlib
import re
import sys

mcp_path = pathlib.Path(sys.argv[1])
servers_path = pathlib.Path(sys.argv[2])

story_servers = json.loads(servers_path.read_text(encoding="utf-8"))
# Unwrap if the template uses the standard MCP envelope format {"servers": {...}}
if isinstance(story_servers.get("servers"), dict):
    story_servers = story_servers["servers"]


def strip_jsonc(raw: str) -> str:
    out = []
    i = 0
    in_string = False
    escaped = False
    length = len(raw)

    while i < length:
        ch = raw[i]

        if in_string:
            out.append(ch)
            if escaped:
                escaped = False
            elif ch == "\\":
                escaped = True
            elif ch == '"':
                in_string = False
            i += 1
            continue

        if ch == '"':
            in_string = True
            out.append(ch)
            i += 1
            continue

        if ch == "/" and i + 1 < length:
            nxt = raw[i + 1]
            if nxt == "/":
                i += 2
                while i < length and raw[i] not in "\r\n":
                    i += 1
                continue
            if nxt == "*":
                i += 2
                while i + 1 < length and not (raw[i] == "*" and raw[i + 1] == "/"):
                    i += 1
                i += 2
                continue

        out.append(ch)
        i += 1

    cleaned = "".join(out)
    cleaned = re.sub(r",\s*([}\]])", r"\1", cleaned)
    return cleaned


config = {"servers": {}, "inputs": []}

if mcp_path.exists():
    raw = mcp_path.read_text(encoding="utf-8")
    try:
        config = json.loads(strip_jsonc(raw))
    except Exception:
        print(f"WARN: Could not parse {mcp_path}. Skipping MCP merge to avoid destructive changes.")
        sys.exit(0)

if not isinstance(config, dict):
    config = {"servers": {}, "inputs": []}

if not isinstance(config.get("servers"), dict):
    config["servers"] = {}
if not isinstance(config.get("inputs"), list):
    config["inputs"] = []

added = []
for name, server_config in story_servers.items():
    if name not in config["servers"]:
        config["servers"][name] = server_config
        added.append(name)

if added or not mcp_path.exists():
    mcp_path.write_text(json.dumps(config, indent=2) + "\n", encoding="utf-8")
    if added:
        print("MCP: added servers in " + str(mcp_path) + " -> " + ", ".join(added))
    else:
        print("MCP: created " + str(mcp_path))
else:
    print("MCP: no changes in " + str(mcp_path) + " (all story-agent servers already present)")
PY
}

merge_mcp_servers() {
  local merged_any=false
  local candidate
  local claude_global_mcp="${HOME}/.claude.json"
  local candidates=(
    ".vscode/mcp.json"
    ".cursor/mcp.json"
    ".cursor/mcp.jsonc"
    ".mcp.json"
    ".roo/mcp.json"
    ".windsurf/mcp.json"
  )

  for candidate in "${candidates[@]}"; do
    if [[ -f "${TARGET_ROOT}/${candidate}" ]]; then
      merge_mcp_servers_into_file "${TARGET_ROOT}/${candidate}"
      merged_any=true
    fi
  done

  if [[ -f "${claude_global_mcp}" ]]; then
    merge_mcp_servers_into_file "${claude_global_mcp}"
    merged_any=true
  elif [[ -f "${TARGET_ROOT}/CLAUDE.md" ]]; then
    echo "MCP: detected CLAUDE.md but ${claude_global_mcp} is missing; skipping global file creation"
  fi

  if [[ "${merged_any}" == "false" ]]; then
    if [[ -d "${TARGET_ROOT}/.cursor" ]]; then
      merge_mcp_servers_into_file "${TARGET_ROOT}/.cursor/mcp.json"
    elif [[ -f "${TARGET_ROOT}/CLAUDE.md" ]]; then
      merge_mcp_servers_into_file "${TARGET_ROOT}/.mcp.json"
    elif [[ -d "${TARGET_ROOT}/.roo" ]]; then
      merge_mcp_servers_into_file "${TARGET_ROOT}/.roo/mcp.json"
    elif [[ -f "${TARGET_ROOT}/.windsurfrules" || -d "${TARGET_ROOT}/.windsurf" ]]; then
      merge_mcp_servers_into_file "${TARGET_ROOT}/.windsurf/mcp.json"
    else
      merge_mcp_servers_into_file "${TARGET_ROOT}/.vscode/mcp.json"
    fi
  fi
}

copy_tree_additive "${ASSET_ROOT}/agents"  "${TARGET_ROOT}/.ai/story-agent/agents"
copy_tree_additive "${ASSET_ROOT}/prompts" "${TARGET_ROOT}/.ai/story-agent/prompts"
copy_tree_additive "${ASSET_ROOT}/outputs" "${TARGET_ROOT}/.ai/story-agent/outputs"

if [[ -d "${TARGET_ROOT}/.github" ]]; then
  copy_tree_additive "${ASSET_ROOT}/templates/github/agents" "${TARGET_ROOT}/.github/agents"
fi

# Always create/update AGENTS.md with a story-agent paragraph
ensure_story_agent_paragraph "${TARGET_ROOT}/AGENTS.md"

# Add to CLAUDE.md only when a .claude/ directory already exists
if [[ -d "${TARGET_ROOT}/.claude" ]]; then
  ensure_story_agent_paragraph "${TARGET_ROOT}/CLAUDE.md"
fi

if [[ -d "${TARGET_ROOT}/.cursor" ]]; then
  copy_tree_additive "${ASSET_ROOT}/templates/cursor/skills/explain-story" "${TARGET_ROOT}/.cursor/skills/explain-story"
  copy_tree_additive "${ASSET_ROOT}/templates/cursor/skills/plan-story" "${TARGET_ROOT}/.cursor/skills/plan-story"
  copy_tree_additive "${ASSET_ROOT}/templates/cursor/skills/story-agent" "${TARGET_ROOT}/.cursor/skills/story-agent"
fi

ensure_gitignore_block
merge_mcp_servers

echo
echo "story-agent init complete"
echo "- target: ${TARGET_ROOT}"
echo "- created files: ${created_files}"
echo "- skipped existing files: ${skipped_files}"

# Offer to remove the cloned story-agent source directory.
# Only shown in interactive terminals — CI pipelines (no TTY) skip this automatically.
if [[ -t 0 && "${SOURCE_ROOT}" != "${TARGET_ROOT}" ]]; then
  echo
  read -r -p "Remove the cloned story-agent folder (${SOURCE_ROOT})? [y/N] " _cleanup_response
  if [[ "${_cleanup_response}" =~ ^[Yy]$ ]]; then
    rm -rf "${SOURCE_ROOT}"
    echo "Removed ${SOURCE_ROOT}"
  fi
fi
