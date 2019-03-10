#!/bin/sh -e
# reciprocal best hit workflow
fail() {
    echo "Error: $1"
    exit 1
}

notExists() {
	[ ! -f "$1" ]
}

# check number of input variables
[ "$#" -ne 4 ] && echo "Please provide <sequenceDB> <sequenceDB> <outDB> <tmp>" && exit 1;
# check if files exists
[ ! -f "$1" ] &&  echo "$1 not found!" && exit 1;
[ ! -f "$2" ] &&  echo "$2 not found!" && exit 1;
[   -f "$3" ] &&  echo "$3 exists already!" && exit 1;
[ ! -d "$4" ] &&  echo "tmp directory $4 not found!" && mkdir -p "$4";

A_DB="$1"
B_DB="$2"
RBH_RES="$3"
TMP_PATH="$4"

# search in both directions:
if [ ! -e "${TMP_PATH}/resAB.dbtype" ]; then
    # shellcheck disable=SC2086
    "$MMSEQS" search "${A_DB}" "${B_DB}" "${TMP_PATH}/resAB" "${TMP_PATH}/tempAB" ${SEARCH_A_B_PAR} \
        || fail "search A vs. B died"
fi

if [ ! -e "${TMP_PATH}/resBA.dbtype" ]; then
    # shellcheck disable=SC2086
    "$MMSEQS" search "${B_DB}" "${A_DB}" "${TMP_PATH}/resBA" "${TMP_PATH}/tempBA" ${SEARCH_B_A_PAR} \
        || fail "search B vs. A died"
fi

# extract best hit in both directions:
if [ ! -e "${TMP_PATH}/resA_best_B.dbtype" ]; then
    # shellcheck disable=SC2086
    "$MMSEQS" filterdb "${TMP_PATH}/resAB" "${TMP_PATH}/resA_best_B" --extract-lines 1 ${THREADS_COMP_PAR} \
        || fail "extract A best B died"
fi

if [ ! -e "${TMP_PATH}/resB_best_A.dbtype" ]; then
    # shellcheck disable=SC2086
    "$MMSEQS" filterdb "${TMP_PATH}/resBA" "${TMP_PATH}/resB_best_A" --extract-lines 1 ${THREADS_COMP_PAR} \
        || fail "extract B best A died"
fi

# swap the direction of resB_best_A:
if [ ! -e "${TMP_PATH}/resB_best_A_swap.dbtype" ]; then
    # shellcheck disable=SC2086
    "$MMSEQS" swapdb "${TMP_PATH}/resB_best_A" "${TMP_PATH}/resB_best_A_swap" ${THREADS_COMP_PAR} \
        || fail "swap B best A died"
fi

# merge the best results:
if [ ! -e "${TMP_PATH}/res_best_merged.dbtype" ]; then
    # shellcheck disable=SC2086
    "$MMSEQS" mergedbs "${TMP_PATH}/resA_best_B" "${TMP_PATH}/res_best_merged" "${TMP_PATH}/resA_best_B" "${TMP_PATH}/resB_best_A_swap" ${VERB_COMP_PAR} \
        || fail "merge best hits died"
fi

# sort by bitscore (decreasing order):
if [ ! -e "${TMP_PATH}/res_best_merged_sorted.dbtype" ]; then
    # shellcheck disable=SC2086
    "$MMSEQS" filterdb "${TMP_PATH}/res_best_merged" "${TMP_PATH}/res_best_merged_sorted" --sort-entries 2 --filter-column 2 ${THREADS_COMP_PAR} \
        || fail "sort by bitscore died"
fi

# identify the RBH pairs and write them to a result db:
if [ ! -e "${RBH_RES}.dbtype" ]; then
    # shellcheck disable=SC2086
    "$MMSEQS" result2rbh "${TMP_PATH}/res_best_merged_sorted" "${RBH_RES}" ${THREADS_COMP_PAR} \
        || fail "result2rbh died"
fi

if [ -n "$REMOVE_TMP" ]; then
    echo "Remove temporary files"
    rm -rf "${TMP_PATH}/tempAB"
    rm -rf "${TMP_PATH}/tempBA"
    "$MMSEQS" rmdb "${TMP_PATH}/resAB"
    "$MMSEQS" rmdb "${TMP_PATH}/resBA"
    "$MMSEQS" rmdb "${TMP_PATH}/resA_best_B"
    "$MMSEQS" rmdb "${TMP_PATH}/resB_best_A"
    "$MMSEQS" rmdb "${TMP_PATH}/res_best"
    rm -f "${TMP_PATH}/rbh.sh"
fi