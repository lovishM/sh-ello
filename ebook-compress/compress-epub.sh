#!/usr/bin/env bash

# -------------------------------------------------------------
# Needs imagemagick tool to be installed
#   Assumes commands `convert` and `mogrify` to be available
# -------------------------------------------------------------
# Changes extra heavy image files to compressed ones which are
# still as good to read in a tablet or a laptop
# -------------------------------------------------------------
# Run in the folder containing EPUB files, and they'll be
# compressed and kept in `./compressed` folder, and `processed`
# folder will contain the original files
# -------------------------------------------------------------

# Lower limit of compression
_lower_limit=${1:-35}
if ! (echo ${_lower_limit} | grep -qxE '[0-9]+')
then
    echo "Wrong Argument. Exiting."
    exit 1
fi
echo "Initialized with lower limit of compression = ${_lower_limit}"

count=0

skip_and_move() {

    cwd="$1"
    f="$2"

    mv "${cwd}"/"${f}" "${cwd}"/compressed/"${f}"
    echo " skipped (images already compressed)"
    cd "${cwd}"
}

cwd=$( pwd )
mkdir -p compressed
mkdir -p processed

compress() {
    while read f
    do
        __d="${f%/*}"
        __f="${f##*/}"

        count=$(( count + 1 ))
        name="${__f%.*}"

        d=""
        mkdir -p ./compressed/"${__d}"
        [ -e "./compressed/${__d}/${name}.epub" ] && echo "[${count}] File [$f] already compressed" && continue

        [ ${#__d} -gt 2 ] && printf "%-150s " "[${count}] Working on file [.../${__f}]" || printf "%-150s " "[${count}] Working on file [${f}]"

        rm -fr work
        mkdir -p work

        # unzip the epub file
        ( cd work && unzip -q ../"$f" ) || return 1
        printf "."

        # Find the images directory
        __x=$( find "$(pwd)/work" \( -name 'images' -o -name 'Images' \) -type d )

        if [ -z "${__x}" ]; then
            skip_and_move "${cwd}" "${f}"
            continue
        fi

        # Skip is folder is ~ 4k
        if [ $( du -k "${__x}" | awk '{print $1}' ) -le 4 ]; then
            skip_and_move "${cwd}" "${f}"
            continue
        fi

        d="$( dirname "${__x}" )/_X"

        mkdir -p "${d}"
        cd "${__x}"

        _max=$( du -k * | sort -nk 1 | tail -1 | awk '{print $1}' )
        _copy=true

        if [ ${_max} -le 500 ]; then
            _copy=false
        else
            percentage=$(( 50000 / _max ))
            [ ${percentage} -lt ${_lower_limit} ] && percentage=${_lower_limit}
            [ ${percentage} -gt 90 ] && _copy=false
        fi

        if ! $_copy
        then
            skip_and_move "${cwd}" "${f}"
            continue
        fi

        # Compress (uses mogrify, can use convert too)
        ( mogrify -resize ${percentage}% -path "${d}" * ) || return 1

        cd "${cwd}"
        printf "."

        # Move all images
        mv "${d}"/* "${__x}"/
        rm -fr "${d}"

        # Compress and create epub
        ( cd work/ && zip -qrX "${cwd}"/compressed/"${__d}"/"${name}".epub mimetype $(ls |xargs echo| sed 's/mimetype//g') -x *.DS_Store ) || return 1

        mkdir -p "${cwd}"/processed/"${__d}"
        mv "${cwd}"/"${f}" "${cwd}"/processed/"${f}"

        __prev=$( du -k "${cwd}"/processed/"${f}" | awk '{print $1}' )
        __curr=$( du -k "${cwd}"/compressed/"${f}" | awk '{print $1}' )

        if [ ${__curr} -gt ${__prev} ]; then
            __final_percent="+$(( ( (__curr - __prev) * 100) / __prev ))%"
        else
            __final_percent="-$(( ( (__prev - __curr) * 100) / __prev ))%"
        fi

        echo " done (set = ${percentage}, done = ${__final_percent})"
    done < <( find . -type f -name '*.epub' -not \( -path './compressed/*' -prune \) -not \( -path './processed/*' -prune \) | sort )
}

if ! compress
then
    echo failed
    exit 1
fi

rm -fr "${cwd}"/work

