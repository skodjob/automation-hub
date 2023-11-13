SED=sed
GREP=grep
DATE=date

UNAME_S=$(uname -s)
if [ $UNAME_S = "Darwin" ];
then
    # MacOS GNU versions which can be installed through Homebrew
    SED=gsed
    GREP=ggrep
    DATE=gdate
fi

############################################################
# LOGGER
############################################################
function log() {
    local level="${1}"
    shift
    echo -e "[$(date -u +"%Y-%m-%d %H:%M:%S")] [${level}]: ${@}"
}

function err_and_exit() {
    log "${RED}ERROR${NC}" "${1}" >&2
    exit ${2:-1}
}

function err() {
    log "${RED}ERROR${NC}" "${1}" >&2
}

function info() {
    log "${GREEN}INFO${NC}" "${1}"
}

function warn() {
    log "${YELLOW}WARN${NC}" "${1}"
}
