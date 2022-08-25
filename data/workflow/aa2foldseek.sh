#!/bin/sh -e
# shellcheck disable=SC2086
[ -z "$MMSEQS" ] && echo "Please set the environment variable \$MMSEQS to your MMSEQS binary." && exit 1;
[ "$#" -ne 4 ] && echo "Please provide <inputDB> <targetFoldSeekDB> <outDB> <tmpDir>" && exit 1

notExists() {
	[ ! -f "$1" ]
}

IN="$1"
TARGET="$2"
OUT="$3"
TMP_PATH="$4"

[ ! -f "${IN}.dbtype" ] && echo "${IN}.dbtype not found!" && exit 1;
[ ! -f "${TARGET}.dbtype" ] && echo "${TARGET}.dbtype not found!" && exit 1;
[ ! -f "${TARGET}_h.dbtype" ] && echo "${TARGET}_h.dbtype not found!" && exit 1;
[ ! -f "${TARGET}_ss.dbtype" ] && echo "${TARGET}_ss.dbtype not found!" && exit 1;


if notExists "${TMP_PATH}/alnDB.dbtype"; then
    # shellcheck disable=SC2086
    "$MMSEQS" search "${IN}" "${TARGET}" "${TMP_PATH}/alnDB" "${TMP_PATH}/search" ${SEARCH_PAR} \
        || fail "search failed"
    fi

if notExists "${TMP_PATH}/topHitalnDB.dbtype"; then
    # shellcheck disable=SC2086
    "$MMSEQS" filterdb "${TMP_PATH}/alnDB" "${TMP_PATH}/topHitalnDB" --extract-lines 1 ${THREADS_PAR}\
        || fail "filterdb failed"
fi

if notExists "${TMP_PATH}/topHitalnSwapDB.dbtype"; then
    # shellcheck disable=SC2086
    "$MMSEQS" swapdb "${TMP_PATH}/topHitalnDB" "${TMP_PATH}/topHitalnSwapDB" ${THREADS_PAR}\
        || fail "swapdb failed"
fi

if notExists "${OUT}.dbtype"; then
    # shellcheck disable=SC2086
    "$MMSEQS" createsubdb "${TMP_PATH}/topHitalnSwapDB" "${TARGET}" "${OUT}" ${VERBOSITY}\
        || fail "createsubdb failed"
fi

if notExists "${OUT}_ss.dbtype"; then
    # shellcheck disable=SC2086 
    "$MMSEQS" createsubdb "${TMP_PATH}/topHitalnSwapDB" "${TARGET}_ss" "${OUT}_ss" ${VERBOSITY}\
        || fail "createsubdb failed"
fi

"$MMSEQS" lndb "${IN}_h" "${OUT}_h" ${VERBOSITY}
"$MMSEQS" lndb "${IN}.lookup" "${OUT}.lookup" ${VERBOSITY}