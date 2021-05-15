#!/usr/bin/env bash
################################################################################
PATH_OF_SCRIPT_RELATIVE_TO_THIS_FILE=index.js
NAME_OF_SCRIPT=start
CRONSPEC='* * * * *' # runs every second
EXTRA_ARGS=''
NANNY_DOT_DIR="$HOME/.nanny/"
ACTIVITY_LOG_FILEPATH="$NANNY_DOT_DIR/activity.log"
QPA_SPECS_FILEPATH="$NANNY_DOT_DIR/qpa-specs"
QPA_SPEC_SYNTAX_HEADER='QUERY;PREDICATE;ACTION'
QPA_SPEC_EXAMPLE='jq .;1===1;echo do nothing'
PROJ_DIR_ROOT="$(pwd)" # only works since npm always runs out of proj-root

main() {
    # grab toggldesktop since it has some useful code; it is ignored so we dont
    # deal with the git-in-git-problem.
    if [[ -d toggldesktop ]]; then
        : # already there
    else
        git clone git@github.com:toggl-open-source/toggldesktop.git
    fi

    modify-crontab

    # They swallow errors so let's install in dev mode
    install-active-win-dev-mode

    preflight-helper-utility-check jq

    init-files
}

install-active-win-dev-mode() {
    # clone
    if [[ -d active-win ]]; then
        : # already there
    else
        git clone https://github.com/dougpagani/active-win
    fi
    # Now, since we want to simultaneously develop two things in a
    # version-controllable way, let's link.
    cd active-win 
    npm link
    cd - &> /dev/null
    npm link active-win
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
    if [[ -L ./logfile ]]; then
        : # do nothing, link already exists
    else
        ln -s "$ACTIVITY_LOG_FILEPATH" ./logfile 
    fi

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
    crontabLine="$(prepare-crontab-line)"
    if (crontab -l | grep -q "$crontabLine"); then
        : # do nothing, already exists
    else
        set +e # disabled because we let read encounter EOF -- https://stackoverflow.com/a/67066283
        read -r -d '' crontabEntry << EOM
# --------------------------------------
# AUTO-INSERTED BY DAEMON-NANNY 
oldPath=\$PATH
PATH=$PATH 
$crontabLine
# CAVEAT: CANT REST OLD PATH B/C VARIABLES ARE ONE-WAY
# END: AUTO-INSERTED BY DAEMON-NANNY 
# --------------------------------------
EOM
        set -e
        { \crontab -l; echo "$crontabEntry"; } | \crontab - 
    fi
}

prepare-crontab-line() {
    scriptPath="$(get-absolute-path-to-script)"
    scriptName="${NAME_OF_SCRIPT}"
    nodePath="$npm_node_execpath" # dependent upon having been run with an npm script
    npmPath="$(printf '%s' "$nodePath" | sed 's_node$_npm_')"
    cronlogfile="${PROJ_DIR_ROOT}/cronlog"
    if (is-linux); then
        linuxDisplayString="DISPLAY='${DISPLAY}'"
    else
        linuxDisplayString=""
    fi
    echo "$CRONSPEC $linuxDisplayString $nodePath $npmPath --scripts-prepend-node-path=true --prefix ${PROJ_DIR_ROOT} run $scriptName $EXTRA_ARGS >> $cronlogfile 2>&1"
}

is-linux() {
    [[ "$OSTYPE" = "linux-gnu" ]]
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

