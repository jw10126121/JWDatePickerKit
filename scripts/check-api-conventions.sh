#!/bin/sh
set -eu

if [ "$#" -ne 1 ]; then
    printf '用法：sh %s <另一个选择器仓库的路径>\n' "$0" >&2
    exit 2
fi

repo_root=$(CDPATH='' cd -- "$(dirname -- "$0")/.." && pwd)
local_doc="$repo_root/API_CONVENTIONS.md"
peer_doc="$1/API_CONVENTIONS.md"

if [ ! -f "$peer_doc" ]; then
    printf '找不到共同 API 公约：%s\n' "$peer_doc" >&2
    exit 2
fi

diff -u "$local_doc" "$peer_doc"
