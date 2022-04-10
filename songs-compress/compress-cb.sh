:

# Lower limit of compression
_lower_limit=${1:-35}
if ! (echo ${_lower_limit} | grep -qxE '[0-9]+')
then
    echo "Wrong Argument. Exiting."
    exit 1
fi
echo "Initialized with lower limit of compression = ${_lower_limit}"

count=0

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
        [ -e "./compressed/${__d}/${name}.cbz" ] && echo "[${count}] File [$f] already compressed" && continue

        [ ${#__d} -gt 2 ] && printf "%-150s " "[${count}] Working on file [.../${__f}]" || printf "%-150s " "[${count}] Working on file [${f}]"

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
        d="$(pwd)/work/compressed"
        __x="$( find ./work -type d | tail -1 )"
        mkdir -p "${d}"
        cd "${__x}"

        _fcount=$( ls | wc -l )
        _per=$(( _total / _fcount ))
        _copy=true

        if [ ${_per} -le 500 ]; then
            _copy=false
        else
            percentage=$(( 50000 / _per ))
            [ ${percentage} -lt ${_lower_limit} ] && percentage=${_lower_limit}
            [ ${percentage} -gt 90 ] && _copy=false
        fi

        if ! $_copy
        then
            mv "${cwd}"/"${f}" "${cwd}"/compressed/"${f}"
            echo " skipped (images already compressed)"
            cd "${cwd}"

            continue
        fi

        # Convert JPG, jpeg to jpg
        for _i in *.JPG *.jpeg
        do
            [ ! -e "${_i}" ] && continue
            mv "${_i}" "${_i%.*}".jpg
        done

        # Convert PNG to png
        for _i in *.PNG
        do
            [ ! -e "${_i}" ] && continue
            mv "${_i}" "${_i%.*}".png
        done

        _jpeg_count=$( find . -name '*.jpg' | wc -l )
        _png_count=$( find . -name '*.png' | wc -l )

        if [ ${_jpeg_count} -gt 0 ]; then
            _ext_files="*.jpg"
        fi
        if [ ${_png_count} -gt 0 ]; then
            _ext_files="${_ext_files} *.png"
        fi

        if [ -z "${_ext_files}" ]; then
            echo " No jpg / png files found"
            return 1
        fi

        ( mogrify -resize ${percentage}% -path "${d}" ${_ext_files} ) || return 1

        [ -e *.xml ] && cp *.xml "${d}"/

        cd "${cwd}"
        printf "."

        # Compress and create cbz
        ( cd work/compressed && zip -qr "${cwd}"/compressed/"${__d}"/"${name}".cbz * ) || return 1
        mkdir -p "${cwd}"/processed/"${__d}"
        mv "${cwd}"/"${f}" "${cwd}"/processed/"${f}"
        echo " done (ratio = ${percentage})"

    done < <( find . -type f -name '*.cb[zr]' -not \( -path './compressed/*' -prune \) -not \( -path './processed/*' -prune \) )
}

if ! compress
then
    echo failed
    exit 1
fi

rm -fr "${cwd}"/work

