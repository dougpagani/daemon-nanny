#!/usr/bin/env bash
################################################################################
PATH_OF_SCRIPT_RELATIVE_TO_THIS_FILE=TODO
NAME_OF_SCRIPT=
CRONSPEC='* * * * *'
EXTRA_ARGS=''

main() {
    # grab toggldesktop since it has some useful code; it is ignored so we dont
    # deal with the git-in-git-problem.
    git clone git@github.com:toggl-open-source/toggldesktop.git || :

    preflight-helper-utility-check jq

    modify-crontab
}

printred() {
    c_grey="\x1b[38;5;1m"
    nc="\033[0m"
    printf "${c_grey}%s${nc}\n" "$*" >&2
}

die() {
    printred "$@" >&2
    exit 1
}

preflight-helper-utility-check() {
    for dep in "$@"; do
        if ! (type $dep > /dev/null); then
            die "missing dependency: $dep; please add install to this script ${BASH_SOURCE[0]}"
        fi
    done
}


modify-crontab() {
    crontabLine=$(prepare-crontab-line)
    # scriptPath="$absolutePathToScript" # HACK: comes from dynamic scope
    if (crontab -l | grep -q "$crontabLine"); then
        : # do nothing, already exists
    else
        { \crontab -l; echo "$crontabLine"; } | \crontab - 
    fi
}
prepare-crontab-line() {
    scriptName="$(get-absolute-path-to-script)"
    echo "$CRONSPEC $scriptName $EXTRA_ARGS"
}

get-absolute-path-to-script() {
    thisFileRelativeToCwd="${BASH_SOURCE[0]}"
    thisFileFullPath="$(realpath "$thisFileRelativeToCwd")"
    thisDir=$(dirname "$thisFileFullPath")

    cd "$thisDir"
    absolutePathToScript=$(realpath "$PATH_OF_SCRIPT_RELATIVE_TO_THIS_FILE")
    cd - &> /dev/null

    echo -n "$absolutePathToScript"
}

# # If executed as a script, instead of sourced
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    set -euo pipefail
    die 'TODO: add to bootstrap the instantiation of a template QPA-file in the dot-directory
... and maybe the log, too
'

    main "$@"
else
    echo "${BASH_SOURCE[0]}" sourced >&2
fi

