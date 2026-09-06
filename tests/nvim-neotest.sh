#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "${BASH_SOURCE[0]}")/.."

python3 - <<'PY'
import json
import re
import tomllib
from pathlib import Path

root = Path.cwd()
config = (root / "dot_config/nvim/lua/plugins/neotest.lua").read_text()
treesitter = (root / "dot_config/nvim/lua/plugins/treesitter.lua").read_text()
ui = (root / "dot_config/nvim/lua/plugins/ui.lua").read_text()
which_key = (root / "dot_config/nvim/lua/plugins/which-key.lua").read_text()

for plugin in (
    "nvim-neotest/neotest",
    "rcasia/neotest-java",
    "nvim-neotest/neotest-python",
    "fredrikaverpil/neotest-golang",
):
    assert plugin in config, f"missing Neotest plugin: {plugin}"

keys = re.findall(r'"(<leader>n[^" ]*)"', config)
expected = {
    "<leader>nn", "<leader>nf", "<leader>na", "<leader>nl", "<leader>nd",
    "<leader>nD", "<leader>ns", "<leader>no", "<leader>nO", "<leader>nx",
}
assert set(keys) == expected, f"unexpected Neotest mappings: {keys}"
assert len(keys) == len(set(keys)), "duplicate Neotest mappings"
assert '"<leader>n", group = "テスト"' in which_key
assert '"<leader>sn"' in ui and '"<leader>n"' not in ui

assert 'jvm_args = { "-Xmx512m" }' in config
assert "classpath_provider = java_classpath_provider()" in config
assert "build_tool_getter = java_build_tool_getter" in config
assert 'go_test_args = { "-v", "-count=1" }' in config
assert '"-race"' not in config
assert re.search(r"discovery\s*=\s*{\s*concurrent\s*=\s*1", config)
assert re.search(r"running\s*=\s*{\s*concurrent\s*=\s*false", config)
assert re.search(r'ensure_installed\s*=\s*{.*?"go"', treesitter, re.S)

with (root / "dot_config/mise/config.toml").open("rb") as file:
    tools = tomllib.load(file)["tools"]
assert tools.get("gotestsum"), "gotestsum is not managed by mise"

lock = json.loads((root / "dot_config/nvim/lazy-lock.json").read_text())
for plugin in ("neotest", "neotest-java", "neotest-python", "neotest-golang", "FixCursorHold.nvim"):
    assert plugin in lock, f"missing lazy-lock entry: {plugin}"

print("Neotest adapters, mappings, resource limits and toolchain checks passed")
PY
