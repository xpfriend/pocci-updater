get_current_version() {
    IMAGE=$1
    cd ${BASE_DIR}/images/${IMAGE}/src.tmp
    git describe --tags --abbrev=0 | tr -d v
    cd ${BASE_DIR}
}

get_next_version() {
    MAJOR=`echo "$1" | cut -d. -f1`
    MINOR=`echo "$1" | cut -d. -f2`
    PATCH=`echo "$1" | cut -d. -f3`
    if [ "$2" = "p" ]; then
        echo ${MAJOR}.${MINOR}.`expr ${PATCH} + 1`
    else
        echo ${MAJOR}.`expr ${MINOR} + 1`.0
    fi
}

get_next_version_of() {
    get_next_version $(get_current_version $1) $2
}

get_number_of_updated_files() {
    cd `dirname $1` && git status --porcelain |wc -l
}

get_greater_version_of() {
    V_A=`echo "$2" | cut -d. -f"$1"`
    V_B=`echo "$3" | cut -d. -f"$1"`

    if [ -z "${V_A}" ]; then
        V_A="-1"
    fi

    if [ -z "${V_B}" ]; then
        V_B="-1"
    fi

    if [ "${V_A}" -gt "${V_B}" ]; then
        echo "$2"
        return
    fi
    if [ "${V_B}" -gt "${V_A}" ]; then
        echo "$3"
        return
    fi
}

get_greater_version() {
    for i in 1 2 3; do
        VERSION=`get_greater_version_of $i $1 $2`
        if [ -n "${VERSION}" ]; then
            echo ${VERSION}
            return
        fi
    done

    echo $1
}

handle_error() {
    if [ ${PIPESTATUS[0]} -ne 0 ]; then
        exit 1
    fi
}


get_number_of_diff_lines() {
    if [ `git branch | grep wip | wc -l` -eq 0 ]; then
        echo 0
    else
        git diff master wip | wc -l
    fi
}

export -f get_current_version
export -f get_next_version_of
export -f get_next_version
export -f get_number_of_updated_files
export -f get_greater_version_of
export -f get_greater_version
