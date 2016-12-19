#!/usr/bin/env bash

#---------------------------------------------------------------------------------
# Author    : Lovish
# Email     : lovish.mittal@gmail.com
# Script    : se-util.sh
#---------------------------------------------------------------------------------
# Purpose   : Searching utility using 'find' and 'grep' for easier file searching
#             The command 'se' stands for [S]earch [E]xtension. It is a basic
#             command to fasten your searching, and contains all the benefits of
#             a normal find command.
#---------------------------------------------------------------------------------
# Setup     : Add the following steps in your .profile/.bash_profile and enjoy
# 
# source <script file path>
#        OR
# . <script file path>
#
#---------------------------------------------------------------------------------
# In case of any bugs, please raise an issue with screenshots/output
# You are free to use this script in your daily searching needs ;)
#---------------------------------------------------------------------------------

# Removing the previously set commands with 'se'
unset se 2>/dev/null
unalias se 2>/dev/null
se () {

    # Declare all the variables to be used
    local __find __searchToken __searchWith __result

    # If the usage is incorrect, print usage
	[ $# -lt 1 ] \
		&& echo "se <--|search word> <file extension> [find args]" \
        && echo "Default extension is 'java'" \
		&& return 1

    # Check the existence of find command
	__find=`which find`
	[ -z "${__find}" ] && echo "'find' command not found" && return 1

    # Make sure search token is set, default is 'java'
	__searchToken="$1"
    [ ! -z "$2" ] && __searchWith="$2" && shift 1 || __searchWith='java'
	shift 1

    # On basis of search token, conduct the search of an extension
	case ${__searchToken} in
		"--")
			__result=$( ${__find} $* -name "*.${__searchWith}" -type f )
			[ -z "${__result}" ] \
				&& return 1 \
				|| echo ${__result} | tr ' ' '\n'
			;;
		*)
			${__find} $* -iname "*${__searchToken}*.${__searchWith}"
			;;
	esac

    # Make sure to return correct status
	return $?
}
