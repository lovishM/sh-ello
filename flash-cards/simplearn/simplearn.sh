:

unset learn 2>/dev/null
learn() {

    local totalWordCount
    local capturedWord
    local meaning
    local playedWords

    local name
    local tmp
    local askedWordCount=0

    __getWordsCount() {

        local _baseDir=${HOME}/.dictionary
        local _wordsFile=${_baseDir}/words.txt
        local _tmpFile=${_baseDir}/new

        [ -e ${_wordsFile} ] && echo 0 && return 0

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

    # Get the total word count
    totalWordCount=$( __getWordsCount )

    header "Hello my eager student! I will call you buddhuu"
    log -n "lb" "Press [CTRL-C] to exit\n\n"

    [ ${askedWordCount} -eq ${totalWordCount} ] \
        && log -n "red" "Oops, no words. Use *add* to insert them" && return 0

    # Start asking the questions
    while [ ${askedWordCount} -lt ${totalWordCount} ]
    do
        # Get the captured word
        capturedWord=$( __getOneRandomWord ${totalWordCount} ${playedWords[@]} )

        meaning=$( echo ${capturedWord} | cut -d: -f2 )
        capturedWord=$( echo ${capturedWord} | cut -d: -f1 | tr -d ' ' )

        printf "Remember this word? [$(log -n lb ${capturedWord} )] "
        read tmp
        case ${tmp} in
            "y"|"Y"|"yes"|"Yes"|"YES")
                ;;
            *)
                printf "\n\t :: $( log -n green ${meaning} )\n\n"
                ;;
        esac

        playedWords=( echo ${playedWords[@]} ${capturedWord} ) 
        askedWordCount=$(( askedWordCount + 1 ))
    done

    log -n "blue" "Good luck\n\n"
}

unset add 2>/dev/null
add() {
    
    local basedir=${HOME}/.dictionary
    local dictionary=${basedir}/words.txt

    local text

    # Make sure file exists
    mkdir -p ${basedir}
    touch ${dictionary}

    header "Welcome to dictionary word provider"
    log "lb" "Press [CTRL-C] to exit"

    while :
    do
        echo 
        read -p "Enter a word: " text
        text=$( echo $text | tr -d ' ' )
        [ -z "${text}" ] && text="" && log red "Word cannot be empty" && continue

        cat ${dictionary} | cut -d: -f1 | tr -d ' ' | grep -qx ${text}
        [ $? -eq 0 ] && log "red" "Word already present!" && continue

        printf "%-20s:" ${text} >> ${dictionary}
        read -p "Enter the meaning of [${text}]: " text
        echo " ${text}" >> ${dictionary}
    done
}

log() {
    
    local cmd="echo"
    [ "$1" = "-n" ] && cmd="printf" && shift 1

    local color=$1
    shift 1

    local msg=$*

    tput bold
    case ${color} in 
        "red") tput setaf 1 ;;
        "green") tput setaf 2 ;;
        "yellow") tput setaf 3 ;;
        "blue") tput setaf 4 ;;
        "lb") tput setaf 6 ;;
        *) ;;
    esac

    ${cmd} "${msg}"
    tput sgr0
}

header() {

    {
        tput bold
        tput setaf 4
        msg $*
        tput sgr0
    }
}

msg() {
    
    local _msg="$*"
    local _tag=$( printf "xxx${_msg}xxx" | sed 's.-g' )

printf "
${_tag}
|  ${_msg}  |
${_tag}
"

}
