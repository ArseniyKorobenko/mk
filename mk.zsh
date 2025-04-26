# You can paste this into your .zshrc or wrap in a script
# TODO: add an option to cd into a makefile's directory before running
# TODO: add wildcard support to search_parents (could be useful for other utils)

# Find files with given names in all parent directories
search_parents() {
    local dir=$PWD
    local filenames=($@)
    local found_files=()

    while [[ $dir != "/" ]]; do
        for filename in ${filenames[@]}; do
            if [[ -e "$dir/$filename" ]]; then
                found_files+=("$dir/$filename")
            fi
        done
        dir=$(dirname "$dir")
    done
    printf "%s\n" ${found_files[@]}
}

# Take a list of Make targets
# find them in the parent Makefiles
# and run them sequentially
mk() {
    local found_files=($(search_parents Makefile makefile))
    local targets=($@)

    if [[ $# -eq 0 ]]; then
        echo "mk: Building ${found_files[1]}."
        make --file ${found_files[1]}
        return $?
    fi

    local exit_status=0
    for target in ${targets[@]}; do
        local target_status="notfound"
        for file in ${found_files[@]}; do
            if make $target --file $file --dry-run >/dev/null 2>/dev/null; then
                echo "mk: Building '$target' in $file."
                make $target --file $file
                target_status=$?
                break
            fi
        done
        if [[ $target_status == "notfound" ]]; then
            echo "mk: Failed to find '$target'."
            exit_status=1
        elif [[ $target_status -ne 0 ]]; then
            echo "mk: Failed to build '$target'."
            exit_status=1
        fi
    done
    return $exit_status
}
