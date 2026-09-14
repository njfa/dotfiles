#!/usr/bin/env bash
set -euo pipefail

root=$(pwd)
tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT
mkdir -p "$tmp/Windows tools"
cp tests/fixtures/wsl-interop-command "$tmp/Windows tools/command"
chmod +x "$tmp/Windows tools/command"
for name in rundll32.exe wslpath win32yank.exe; do
	ln -s command "$tmp/Windows tools/$name"
done
export PATH="$tmp/Windows tools:$PATH"
export OPEN_ARGS="$tmp/open-args" PATH_ARGS="$tmp/path-args"
export CLIP_ARGS="$tmp/clip-args" CLIP_INPUT="$tmp/clip-input"
export WINDOWS_PATH='C:\Users\Test User\a & b.txt'
mkdir "$tmp/only-opener" "$tmp/no-windows" "$tmp/clipboard-temp"
ln -s "$tmp/Windows tools/command" "$tmp/only-opener/rundll32.exe"
for name in base64 tr; do
	ln -s "$(command -v "$name")" "$tmp/no-windows/$name"
done
shell=$(command -v sh)
bash_shell=$(command -v bash)
setsid_cmd=$(command -v setsid)

# URLs and Windows paths remain single literal arguments, never shell code.
for target in 'https://example.org/?a=1&b=$(false)' "$WINDOWS_PATH"; do
	sh bin/xdg-open "$target"
	printf '%s\n' url.dll,FileProtocolHandler "$target" >"$tmp/expected"
	cmp "$tmp/expected" "$OPEN_ARGS"
	test ! -e "$PATH_ARGS"
done

touch "$tmp/a & b.txt"
sh bin/xdg-open "$tmp/a & b.txt"
printf '%s\n' -w "$tmp/a & b.txt" >"$tmp/expected"
cmp "$tmp/expected" "$PATH_ARGS"
printf '%s\n' url.dll,FileProtocolHandler "$WINDOWS_PATH" >"$tmp/expected"
cmp "$tmp/expected" "$OPEN_ARGS"
(
	cd "$tmp"
	sh "$root/bin/xdg-open" 'a & b.txt'
)
printf '%s\n' -w './a & b.txt' >"$tmp/expected"
cmp "$tmp/expected" "$PATH_ARGS"

rm "$OPEN_ARGS"
if PATH="$tmp/only-opener" "$shell" bin/xdg-open "$tmp/a & b.txt" 2>"$tmp/error"; then
	exit 1
else
	test "$?" -eq 127
fi
grep -q 'wslpath is required' "$tmp/error"
test ! -e "$OPEN_ARGS"
# Do not invoke a real Windows executable if this test runs on WSL.
if [ ! -x /mnt/c/Windows/System32/rundll32.exe ]; then
	if PATH="$tmp/no-windows" "$shell" bin/xdg-open 'https://example.org' 2>"$tmp/error"; then
		exit 1
	else
		test "$?" -eq 127
	fi
	grep -q 'rundll32.exe is unavailable' "$tmp/error"
fi

if PATH_STATUS=4 sh bin/xdg-open "$tmp/a & b.txt"; then
	printf 'opener ignored path conversion failure\n' >&2
	exit 1
else
	test "$?" -eq 4
fi
test ! -e "$OPEN_ARGS"
if OPEN_STATUS=7 sh bin/xdg-open 'https://example.org'; then
	exit 1
else
	test "$?" -eq 7
fi

# Exact UTF-8 bytes, CRLF, no final newline, and trailing blank lines.
for input in '' $'\xe6\x97\xa5\xe6\x9c\xac\xe8\xaa\x9e\r\nline\n\n' '-n \\ $(false)'; do
	printf '%s' "$input" >"$tmp/input"
	TMPDIR="$tmp/clipboard-temp" CLIP_STATUS=0 bash bin/tmux-copy <"$tmp/input" >"$tmp/output"
	cmp "$tmp/input" "$CLIP_INPUT"
	printf '%s\n' -i --crlf >"$tmp/expected"
	cmp "$tmp/expected" "$CLIP_ARGS"
	test ! -s "$tmp/output"

	# Force no controlling terminal so the OSC52 bytes can be asserted.
	TMPDIR="$tmp/clipboard-temp" CLIP_STATUS=1 setsid --wait bash bin/tmux-copy <"$tmp/input" >"$tmp/output"
	payload=$(base64 <"$tmp/input" | tr -d '\n')
	printf '\033]52;c;%s\a' "$payload" >"$tmp/expected"
	cmp "$tmp/expected" "$tmp/output"
	PATH="$tmp/no-windows" "$setsid_cmd" --wait "$bash_shell" bin/tmux-copy <"$tmp/input" >"$tmp/output"
	cmp "$tmp/expected" "$tmp/output"
	if compgen -G "$tmp/clipboard-temp/*" >/dev/null; then
		printf 'clipboard temporary file was not removed\n' >&2
		exit 1
	fi
done

# Lazygit supplies an already shell-quoted {{text}} placeholder.
template=
while IFS= read -r line; do
	case "$line" in
	*copyToClipboardCmd:*)
		template=${line#*copyToClipboardCmd: \'}
		template=${template%\'}
		;;
	esac
done <dot_config/lazygit/config.yml
test -n "$template"
mkdir -p "$tmp/home with spaces/.config/dotfiles/bin"
ln -s "$root/bin/tmux-copy" "$tmp/home with spaces/.config/dotfiles/bin/tmux-copy"
for input in '-n' $'\xe6\x97\xa5\xe6\x9c\xac\xe8\xaa\x9e\n\n' 'a\b' "a'b" '\$(false); &'; do
	quoted="'${input//\'/\'\\\'\'}'"
	# Concatenate literally: Bash replacement expansion can reinterpret '&'.
	command="${template%%\{\{text\}\}*}${quoted}${template#*\{\{text\}\}}"
	HOME="$tmp/home with spaces" CLIP_STATUS=0 sh -c "$command"
	printf '%s' "$input" >"$tmp/expected"
	cmp "$tmp/expected" "$CLIP_INPUT"
done

printf 'WSL interoperability behavior tests passed\n'
