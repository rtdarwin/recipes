#! /bin/bash

function cvt_file () {
    cxx_src_file=$(echo $2 | grep "\.h$\|\.c$\|\.cpp$\|\.cc$")
    if [ -z "${cxx_src_file}" ]; then
        return;
    fi

    echo "processing $2..."
    if [ "$1" = "a" ]; then
        uconv --add-signature $2 > ${2}.ubomb
    else
        uconv --remove-signature $2 > ${2}.ubomb
    fi

    mv ${2}.ubomb $2
}

function cvt_recursively () {
    if [ -d $2 ]; then
        for i in $(ls $2);do
            cvt_recursively $1 "$2/$i"
        done
    else
        cvt_file $1 $2
    fi
}

function main() {
    if [ "$1" = "-a" ] || [ "$1" = "--add" ]; then
        cvt_recursively "a" $2
        exit
    fi
    
    if [ "$1" = "-r" ] || [ "$1" = "--remove" ]; then
        cvt_recursively "r" $2
        exit
    fi

    # if [ "$1" = "-h" ] || [ "$1" = "--help" ] || [ "$1" = "" ]; then
    echo "Usage:"
    echo "  $0 {-a|--add} dir|file"
    echo "  $0 {-r|--remove} dir|file"
    exit 1
    # fi

}

main $1 $2;
