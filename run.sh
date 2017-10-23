#!/bin/sh

export PATH="/custom/bin:$PATH"

arg_in_path() {
    which "$1" >/dev/null 2>&1 && return 0
    return 1
}

arg_is_cmd() {
    test -x "$1" && return 0 || return 1
}

arg_is_executable() {
    if arg_in_path "$1" ; then
        return 0
    elif arg_is_cmd "$1" ; then
        return 0
    else
        return 1
    fi
}

tor_boot

if test -z "$1" ; then
    echo "No arguments given to run, launching /bin/sh..."
    exec /bin/sh
elif arg_is_executable "$1" ; then
    echo "[nmap onion]" "$@"
    exec "$@"
else
    echo "[nmap onion] nmap" "$@"
    exec "nmap" "$@"
fi
