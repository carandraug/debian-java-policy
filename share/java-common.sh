function jvm_scan_file() {
    file="$1"

    grep -v '#' "$file" | while read jvm; do
        if [ -n "$jvm" -a -x "$jvm/bin/java" ]; then
            echo -n $jvm
            return
        fi
    done
}

function jvm_find() {
    local jvm

    if [ -n "$JAVA_HOME" ]; then
        jvm="$JAVA_HOME"
    fi

    for file in \
        "$HOME/.jvm.d/$1" \
        "$HOME/.jvm" \
        "/etc/jvm.d/$1" \
        "/etc/jvm"; do \
        if [ -z "$jvm" ]; then
            if [ -r "$file" ]; then
                jvm="$(jvm_scan_file "$file")"
            fi
        fi
    done

    echo -n "$jvm"
}

function jvm_config() {
    echo JAVA_HOME="$(jvm_find "$1")"
}
