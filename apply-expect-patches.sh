#!/bin/sh
set -eu

# No arguments needed. The source and fedora directories live alongside this script.
script_path=$(realpath -- "$0")
base_dir=$(dirname -- "$script_path")
source_dir="$base_dir/expect5.45.4"
target_dir="$base_dir/new-expect5.45.4"
patch_dir="$base_dir/fedora"

# Spec order: Patch0 through Patch20, then Patch100 through Patch106 (28).
set -- \
    expect-5.43.0-log_file.patch \
    expect-5.43.0-pkgpath.patch \
    expect-5.45-man-page.patch \
    expect-5.45-match-gt-numchars-segfault.patch \
    expect-5.45-re-memleak.patch \
    expect-5.45-exp-log-buf-overflow.patch \
    expect-5.45-segfault-with-stubs.patch \
    expect-5.45-fd-leak.patch \
    expect-5.45.4-unification-of-usage-and-man-page.patch \
    expect-5.45.4-covscan-fixes.patch \
    expect-5.45-format-security.patch \
    expect-configure-c99.patch \
    expect-c99.patch \
    expect-5.45.4-tcl9-const.patch \
    expect-5.45.4-tcl9-ansi-args.patch \
    expect-5.45.4-tcl9-varargs.patch \
    expect-5.45.4-tcl9-panic.patch \
    expect-5.45.4-tcl9-eval-tokens.patch \
    expect-5.45.4-tcl9-alloc.patch \
    expect-5.45.4-tcl9-size.patch \
    expect-5.45.4-exit-sighandler.patch \
    expect-5.32.2-random.patch \
    expect-5.45-mkpasswd-dash.patch \
    expect-5.45-check-telnet.patch \
    expect-5.45-passmass-su-full-path.patch \
    expect-5.45-mkpasswd-man.patch \
    expect-5.45.4-tcl9-mkpasswd.patch \
    expect-5.45.4-tcl9-unbuffer.patch

# Check inputs before deleting the previous output.
for command in patch cp rm find; do
    command -v "$command" >/dev/null || {
        printf 'Required command not found: %s\n' "$command" >&2
        exit 1
    }
done
if [ ! -d "$source_dir" ] || [ -L "$source_dir" ]; then
    printf 'Source must be a real directory: %s\n' "$source_dir" >&2
    exit 1
fi
if [ -L "$target_dir" ]; then
    printf 'Refusing to replace a symlink: %s\n' "$target_dir" >&2
    exit 1
fi
for patch_file in "$@"; do
    if [ ! -f "$patch_dir/$patch_file" ] || [ ! -r "$patch_dir/$patch_file" ]; then
        printf 'Missing or unreadable patch: %s\n' "$patch_dir/$patch_file" >&2
        exit 1
    fi
done

rm -rf -- "$target_dir"
cp -a -- "$source_dir" "$target_dir"

for patch_file in "$@"; do
    strip=1
    if [ "$patch_file" = expect-5.45-format-security.patch ]; then
        strip=0
    fi
    printf 'Applying %s (-p%s)\n' "$patch_file" "$strip"
    # Backups contain .kill. so they are removed only after all patches succeed.
    if ! patch --directory="$target_dir" --batch --forward \
        --backup --suffix=.kill.orig -p"$strip" \
        --input="$patch_dir/$patch_file"; then
        printf 'Patch failed: %s; partial output retained in %s\n' \
            "$patch_file" "$target_dir" >&2
        exit 1
    fi
done

find "$target_dir" -type f -name '*.kill.*' -delete
printf 'Done: applied %s patches to %s\n' "$#" "$target_dir"
