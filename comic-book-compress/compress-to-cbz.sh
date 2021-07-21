#!/usr/bin/env bash

# -------------------------------------------------------------
# Needs imagemagick tool to be installed
#   Assumes commands `convert` and `mogrify` to be available
# -------------------------------------------------------------
# Changes extra heavy image files to compressed ones which are
# still as good to read in a tablet or a laptop
# -------------------------------------------------------------
# Run in the folder containing CBR or CBZ files, and they'll be
# compressed and kept in `./compressed` folder, and `processed`
# folder will contain the original files
# -------------------------------------------------------------

count=0

cwd=$( pwd )
mkdir -p compressed
mkdir -p processed

compress() {
    for f in *.cb[rz]
    do
        count=$(( count + 1 ))
        name="${f%.*}"
        d=""
        [ -e "./compressed/${name}.cbz" ] && echo "[${count}] File [$f] already compressed" && continue

        printf "[${count}] Working on file [${f}] "

        _total=$( du -k "${f}" | awk '{print $1}' )

        rm -fr work
        mkdir -p work

        # Unpack
        # If CBR, use unrar, else unzip
        if ( echo $f | grep -q 'cbr$' )
        then
            ( cd work && unrar -inul e ../"$f" )
            if [ $? -ne 0 ]; then
                ( cd work && unzip -q ../"$f" ) || return 1
            fi
        else
            ( cd work && unzip -q ../"$f" )
            if [ $? -ne 0 ]; then
                ( cd work && unrar -inul e ../"$f" ) || return 1
            fi
        fi
        printf "."
        
        # Compress (uses mogrify, can use convert too)
        if ls ./work | grep -iq 'jpg$'
        then
            mkdir -p work/compressed
            cd work
            d="./compressed"

        else
            cd work/*/
            mkdir -p ../compressed
            d="../compressed"

        fi
        _fcount=$( ls | wc -l )
        _per=$(( _total / _fcount ))

        if [ ${_per} -lt 500 ]; then
            mv "${cwd}"/"${f}" "${cwd}"/compressed/"${f}"
            echo " skipped (images already compressed)"
            cd "${cwd}"

            continue
        else
            percentage=$(( 50000 / _per ))
            [ ${percentage} -lt 35 ] && percentage=35
        fi

        # Convert JPG to jpg
        for _i in *.JPG
        do
            [ ! -e "${_i}" ] && continue
            mv "${_i}" "${_i%.*}".jpg
        done
        ( mogrify -resize ${percentage}% -path ${d} *.jpg ) || return 1
        [ -e *.xml ] && cp *.xml ${d}/

        cd "${cwd}"

        printf "."

        # Compress and create cbz
        ( cd work/compressed && zip -qr "${cwd}"/compressed/"${name}".cbz * ) || return 1

        mv "${cwd}"/"${f}" "${cwd}"/processed/"${f}"
        echo " done (ratio = ${percentage})"
    done
}

if ! compress
then
    echo failed
    exit 1
fi

rm -fr "${cwd}"/work

