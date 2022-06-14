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