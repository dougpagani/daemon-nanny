#!/usr/bin/env bash
################################################################################
PATH_OF_SCRIPT_RELATIVE_TO_THIS_FILE=TODO
NAME_OF_SCRIPT=TODO
CRONSPEC='* * * * *' # runs every second
EXTRA_ARGS=''
NANNY_DOT_DIR="$HOME/.nanny/"
ACTIVITY_LOG_FILEPATH="$NANNY_DOT_DIR/activity.log"
QPA_SPECS_FILEPATH="$NANNY_DOT_DIR/qpa-specs"
QPA_SPEC_SYNTAX_HEADER='QUERY;PREDICATE;ACTION'
QPA_SPEC_EXAMPLE='jq .;1===1;echo do nothing'

main() {
    # grab toggldesktop since it has some useful code; it is ignored so we dont
    # deal with the git-in-git-problem.
    git clone git@github.com:toggl-open-source/toggldesktop.git || :

    preflight-helper-utility-check jq

    init-files

    modify-crontab
}

init-files() {
    # The program: references files in the dotfile-location (HOME)
    # The devs: reference files in the project directory
    # Users: change files in the dotfile-location
    # Log file should NOT be version controlled for anyone, but for each dev,
    # accessible in the project directory.
    # QPA file SHOULD be version controlled for the devs, NOT for users.
    # Devs should manually setup symlinks for the QPA's.


    # make the program's dir
    mkdir -p "$NANNY_DOT_DIR"
    # make the files
    if [[ -f "$ACTIVITY_LOG_FILEPATH" ]]; then
        : # do nothing
    else 
        touch "$ACTIVITY_LOG_FILEPATH"
    fi
    if [[ -f "$QPA_SPECS_FILEPATH" ]]; then
        : # do nothing
    else
        touch "$QPA_SPECS_FILEPATH"
        echo "$QPA_SPEC_SYNTAX_HEADER" >> "$QPA_SPECS_FILEPATH"
        echo "$QPA_SPEC_EXAMPLE" >> "$QPA_SPECS_FILEPATH"

        echo >&2 "CAVEAT: if you are a new dev, you should version control your qpa file so common usage patterns are shared"
        echo >&2 "CAVEAT: your log wont be committed"
        echo >&2 "CAVEAT: if you are a new/old dev on a new machine, both need to repair the symlink that goes DOTDIR -> PROJECTDIR"
        echo >&2 "CAVEAT: I created a template file in the dotdir; go there and move it to wherever you cloned the project, and create a symlink."
        echo >&2
        echo >&2 'EXAMPLE for new devs:'
        echo >&2 'cd ~/.nanny/'
        echo >&2 'mv qpa-specs ~/daemon-nanny/qpa-specs/doug'
        echo >&2 'ln -s ~/daemon-nanny/qpa-specs/doug qpa-specs'
        echo >&2 'cd -'
    fi

    # TODO: not guaranteed to be in the right directory, unlike for
    # modify-crontab... so maybe we should do the correct-path-detection
    # beforehand, since it makes for bootstrap to just be in the project
    # directory, since it is meant to configure the project directory.

    # This is just a convenience linking, so you dont have to go into your home
    # directory everytime you want to work with your log file, but can just
    # stay in your project directory.
    ln -s "$ACTIVITY_LOG_FILEPATH" ./logfile 

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
    main "$@"
else
    echo "${BASH_SOURCE[0]}" sourced >&2
fi

