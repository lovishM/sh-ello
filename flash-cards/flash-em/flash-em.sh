#/usr/bin/env bash

export COLS=$( tput cols )
export LINES=$( tput lines )

[ ${LINES} -lt 5 ] && echo "Error: Screen resolution too low" && exit 1

main() {

    # Make sure file is always created
    mkdir -p ${HOME}/.dictionary

    # Get the total word count
    local totalWordCount=$( __getWordsCount )

    learn ${totalWordCount}
}

__getWordsCount() {

    local _wordsFile=${HOME}/.dictionary/words.txt
    local _tmpFile=/tmp/new

    # Create the file in any case
    touch ${_wordsFile}

    cat ${_wordsFile} \
        | grep -v '^[ 	]*$' \
        | sed 's^[ 	]*\(.*\)[ 	]*$\1g' > ${_tmpFile}

    mv ${_tmpFile} ${_wordsFile}

    cat ${_wordsFile} | wc -l
}

__getOneRandomWord() {
    
    local _wordsFile=${HOME}/.dictionary/words.txt

    local _totalWordsCount=${1} && shift 1
    local _ignoreList=( $* )

    local _generatedWord
    local _random

    while [ -z "${_generatedWord}" ]
    do
        _random=$(( ( ${RANDOM} % ${_totalWordsCount} ) + 1))
        [ ${_random} -gt ${_totalWordsCount} ] && _random=$(( _random -1 ))

        _generatedWord=$( cat ${_wordsFile} | sed -n "${_random}p" )
        echo ${_ignoreList[@]} | tr ' ' '\n' | grep -xq $( echo ${_generatedWord} | cut -d: -f1 | tr -d ' ' )

        [ $? -eq 0 ] && _generatedWord=""
    done

    echo ${_generatedWord}
}

__search() {
    
    local _wordsFile=${HOME}/.dictionary/words.txt
    local _searchWord=$1

    cat ${_wordsFile} | grep -i "^[ 	]*${_searchWord}[ 	]*:"
}

unset add 2>/dev/null
add() {
    
    local dictionary=${HOME}/.dictionary/words.txt

    local word=$1
    shift 1
    local text=$*

    # Make sure file exists
    touch ${dictionary}

    printf "%-20s: ${text}\n" ${word} | tee -a ${dictionary}
}

unset learn 2>/dev/null
learn() {

    local totalWordCount=$1

    local capturedWord
    local meaning
    local playedWords

    local tmp text
    local askedWordCount=0
    local cursor=0
    local toGenerate=0

    tput smcup

    # Start asking the questions
    while [ ${askedWordCount} -lt ${totalWordCount} ]
    do
        # Get the captured word
        [ $toGenerate -eq 0 ] \
            && capturedWord=$( __getOneRandomWord ${totalWordCount} ${playedWords[@]} ) \
            && askedWordCount=$(( askedWordCount + 1 ))

        toGenerate=1

        paint "${cursor}" "${capturedWord}"

        while read -rsn1 ui; do
            case "$ui" in
                $'\x1b')
                    read -rsn1 -t 0.1 tmp
                    if [[ "${tmp}" == "[" ]]; then
                        read -rsn1 -t 0.1 tmp
                        case "$tmp" in
                            "D") toGenerate=0; break ;;
                            "C") toGenerate=0; cursor=0; break ;;
                            "B"|"A")
                                [ $cursor -eq 0 ] && cursor=1 || cursor=0
                                break;
                        esac
                    fi
                    read -rsn5 -t 0.1
                    ;;
                q)  tput rmcup
                    exit;;
                s)  
                    tmp=""
                    while [ -z "${tmp}" ]
                    do
                        tput cup $(( LINES - 2 )) 0
                        read -p "Enter a word you wish to search for: " tmp
                        tmp=$( echo $tmp | tr -d ' ' )
                        tput cup $(( LINES - 2 )) 0
                        [ -z "${tmp}" ] && echo "Enter a proper word" && sleep 2
                    done
                    tmp=$( __search "${tmp}" )
                    [ $? -ne 0 ] && echo "Sorry, no such word in the dictionary" && continue
                    capturedWord=${tmp}
                    break
                    ;;
                l)
                    [ $cursor -eq 0 ] \
                        && tmp=$( echo ${capturedWord} | cut -d: -f1 ) \
                        || tmp=$( echo ${capturedWord} | cut -d: -f2- ) \

                    echo $tmp | espeak
                    break;
                    ;;
                a)
                    tmp=""
                    while [ -z "${tmp}" ]
                    do
                        tput cup $(( LINES - 2 )) 0
                        read -p "Enter a word you wish to add to the dictionary: " tmp
                        tmp=$( echo $tmp | tr -d ' ' )
                        printf ' %.0s' $(eval "echo {1.."$(($COLS))"}")
                        tput cup $(( LINES - 2 )) 0
                        [ -z "${tmp}" ] && echo "Enter a proper word" && sleep 2
                    done
                    text=$( __search "${tmp}" )
                    [ $? -eq 0 ] && echo "Already present in the dictionary" && continue
                    capturedWord=${tmp}
                    read -p "Enter the word's meaning: " tmp
                    capturedWord=$( add ${capturedWord} ${tmp} )
                    break
                    ;;
                h)  tput cup $(( LINES - 1 )) 0
                    echo "q (quit), ← (previous word), → (next word), ↑ or ↓ (flip card), s (search)"
                    read -rsn1 tmp
                    break
                    ;;
            esac
        done

        playedWords=( echo ${playedWords[@]} ${capturedWord} ) 
    done
    tput rmcup

    printf "Good luck\n\n"
}

# Paint the slides
paint() {

    # Main arguments
    local panel=$1
    shift 1
    local printed=0

    local capturedWord=$*
    local meaning=$( echo ${capturedWord} | cut -d: -f2 )
    local capturedWord=$( echo ${capturedWord} | cut -d: -f1 | tr -d ' ' )

    local top_padding=$(( LINES / 6 ))
    local side_padding=$(( COLS / 3 ))

    local total_cols=$(( COLS - (side_padding * 2) ))
    #[ ${total_cols} -gt 50 ] && total_cols=50

    local _row=$(( ${top_padding} - 5 ))
    local _col=$(( (COLS - total_cols)/2))

    local _tmp
    local max_length=$(( total_cols - 5 ))

    # Create the next line to be painted
    nextLine() {

        local delim="|"
        local outsideBox
        local center

        while :
        do
            case $1 in
                "-o") [ ! -z "${delim}" ] && delim="#"; shift 1 ;;
                "-d") delim=""; shift 1 ;;
                "-c") center="-c"; shift 1 ;;
                *) break ;;
            esac
        done

        local _message="$*"
        local _length=${#_message}
        local _temp

        tput cup ${_row} ${_col}
        if [ ! -z "$center" ]; then
            _temp=$(( (total_cols + _length)/2 ))
            printf -- "${delim}%${_temp}s " "${_message}"
            printf -- "%$(( total_cols - _temp))s\n" "${delim}"
        else
            printf -- "${delim}%-${total_cols}s${delim}\n" "${_message}"
        fi

        _row=$(( _row + 1 ))
    }

    # Block to be printed on the screen
    {
        tput clear
        tput bold
        tput setaf 4
        nextLine -d -c $( printf -- '-%.0s' {1..21} )
        nextLine -d -c "|   Flash Cards   |"
        nextLine -d -c $( printf -- '-%.0s' {1..21} )
        nextLine -d -c ""
        nextLine -d -c ""
        [ ${cursor} -eq 0 ] && tput setaf 6 || tput setaf 2
        nextLine -o $( printf '=%.0s' $(eval "echo {1.."$(($total_cols))"}"))
        [ ${cursor} -eq 0 ] && nextLine -o -c "WORD"

        [ ${cursor} -eq 1 ] && nextLine -o -c "MEANING"

        nextLine -o $( printf '=%.0s' $(eval "echo {1.."$(($total_cols))"}"))

        [ ${cursor} -eq 0 ] && tput setaf 2 || tput setaf 6
        _tmp=${top_padding}
        while [ ${_tmp} -gt 0 ]; do nextLine ""; _tmp=$(( _tmp -1 )); done;

        if [ ${cursor} -eq 0 ]; then
            nextLine -c "$( printf "   %s" "${capturedWord}")"
        else
            if [ ${#meaning} -gt ${max_length} ]; then
                while [ ${printed} -lt ${#meaning} ]
                do
                    if [ $(( ${#meaning} - printed )) -lt ${max_length} ]; then
                        max_length=$(( ${#meaning} - printed ))

                        nextLine -c "$( printf "   %s" "${meaning:${printed}:${max_length}}")"
                    else
                        nextLine -c "$( printf "   %s" "${meaning:${printed}:${max_length}}-")"
                    fi
                    printed=$(( printed + max_length ))
                done
            else
                nextLine -c "$( printf "   %s" "${meaning}")"
            fi
        fi

        _tmp=${top_padding}
        while [ ${_tmp} -gt 0 ]; do nextLine ""; _tmp=$(( _tmp -1 )); done;

        [ ${cursor} -eq 0 ] && tput setaf 6 || tput setaf 2
        nextLine -o $( printf -- '=%.0s' $(eval "echo {1.."$(($total_cols))"}"))
        tput sgr0
    } >&2
}

# -----------------
# Main method call
# -----------------
main $*
