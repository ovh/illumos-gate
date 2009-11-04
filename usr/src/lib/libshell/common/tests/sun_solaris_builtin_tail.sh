#
# CDDL HEADER START
#
# The contents of this file are subject to the terms of the
# Common Development and Distribution License (the "License").
# You may not use this file except in compliance with the License.
#
# You can obtain a copy of the license at usr/src/OPENSOLARIS.LICENSE
# or http://www.opensolaris.org/os/licensing.
# See the License for the specific language governing permissions
# and limitations under the License.
#
# When distributing Covered Code, include this CDDL HEADER in each
# file and include the License file at usr/src/OPENSOLARIS.LICENSE.
# If applicable, add the following below this CDDL HEADER, with the
# fields enclosed by brackets "[]" replaced with your own identifying
# information: Portions Copyright [yyyy] [name of copyright owner]
#
# CDDL HEADER END
#

#
# Copyright 2009 Sun Microsystems, Inc.  All rights reserved.
# Use is subject to license terms.
#

#
# Test whether the ksh93/libcmd tail builtin is compatible to
# Solaris/SystemV { /usr/bin/tail, /usr/xpg4/bin/tail } and
# POSIX "tail"
#

# test setup
function err_exit
{
	print -u2 -n "\t"
	print -u2 -r ${Command}[$1]: "${@:2}"
	(( Errors++ ))
}
alias err_exit='err_exit $LINENO'

set -o nounset
Command=${0##*/}
integer Errors=0

# common functions
function isvalidpid
{
        kill -0 ${1} 2>/dev/null && return 0
        return 1
}

function waitpidtimeout
{
	integer pid=$1
	float timeout=$2
	float i
	float -r STEP=0.5 # const

	(( timeout=timeout/STEP ))
	
	for (( i=0 ; i < timeout ; i+=STEP )) ; do
		isvalidpid ${pid} || break
		sleep ${STEP}
	done
	
	return 0
}

function myintseq
{
        integer i
	float arg1=$1
	float arg2=$2
	float arg3=$3

        case $# in
                1)
                        for (( i=1 ; i <= arg1 ; i++ )) ; do
                                printf "%d\n" i
                        done
                        ;;
                2)
                        for (( i=arg1 ; i <= arg2 ; i++ )) ; do
                                printf "%d\n" i
                        done
                        ;;
                3)
                        for (( i=arg1 ; i <= arg3 ; i+=arg2 )) ; do
                                printf "%d\n" i
                        done
                        ;;
                *)
                        print -u2 -f "%s: Illegal number of arguments %d\n" "$0" $#
			return 1
                        ;;
        esac
        
        return 0
}

# quote input string but use double-backslash that "err_exit" prints
# the strings correctly
function doublebackslashquote
{
	typeset s
	s="$(printf "%q\n" "$1")"
	s="${s//\\/\\\\}"
	print -r "$s"
	return 0
}


# main
builtin mktemp || err_exit "mktemp builtin not found"
builtin rm || err_exit "rm builtin not found"
builtin tail || err_exit "tail builtin not found"

typeset ocwd
typeset tmpdir

# create temporary test directory
ocwd="$PWD"
tmpdir="$(mktemp -d "test_sun_solaris_builtin_tail.XXXXXXXX")" || err_exit "Cannot create temporary directory"

cd "${tmpdir}" || err_exit "cd ${tmpdir} failed."


# run tests:

# test1: basic tests
compound -a testcases=(
	(
		name="reverse_n"
		input=$'hello\nworld'
		compound -A tail_args=(
			[legacy]=(   argv=( "-r"  ) )
		)
		expected_output=$'world\nhello'
	)
	(
		name="revlist0n"
		input=$'1\n2\n3\n4'
		compound -A tail_args=(
			[legacy]=(   argv=( "-0"	 ) )
			[std_like]=( argv=( "-n" "0" ) ) 
		)
		expected_output=$''
	)
	(
		name="revlist0nr"
		input=$'1\n2\n3\n4'
		compound -A tail_args=(
			[legacy]=(       argv=( "-0r"	      ) )
			[std_like]=(     argv=( "-n" "0" "-r" ) )
			[long_options]=( argv=( "--lines" "0" "--reverse" ) )
		)
		expected_output=$'' )
	(
		name="revlist1n"
		input=$'1\n2\n3\n4'
		compound -A tail_args=(
			[legacy]=(       argv=( "-1"     ) )
			[std_like]=(     argv=( "-n" "1" ) )
			[long_options]=( argv=( "--lines" "1" ) )
		)
		expected_output=$'4' )
	(
		name="revlist1nr"
		input=$'1\n2\n3\n4'
		compound -A tail_args=(
			[legacy]=(       argv=( "-1r" ) )
			[std_like]=(     argv=( "-n" "1" "-r" ) )
			[long_options]=( argv=( "--lines" "1" "--reverse" ) )
		)
		expected_output=$'4'
	)
	(
		name="revlist2n"
		input=$'1\n2\n3\n4'
		compound -A tail_args=(
			[legacy]=(   argv=( "-2"  ) )
			[std_like]=( argv=( "-n" "2" ) )
		)
		expected_output=$'3\n4'
	)
	(
		name="revlist2nr"
		input=$'1\n2\n3\n4'
		compound -A tail_args=(
			[legacy]=(   argv=( "-2r" ) )
			[std_like]=( argv=( "-n" "2" "-r" ) )
			)
		expected_output=$'4\n3'
	)
	(
		name="revlist3nr"
		input=$'1\n2\n3\n4'
		compound -A tail_args=(
			[legacy]=(   argv=( "-3r" ) )
			[std_like]=( argv=( "-n" "3" "-r" ) )
		)
		expected_output=$'4\n3\n2'
	)
	(
		name="revlist2p"
		input=$'1\n2\n3\n4'
		compound -A tail_args=(
			[legacy]=(   argv=( "+2"  ) )
			[std_like]=( argv=( "-n" "+2" ) )
			)
		expected_output=$'2\n3\n4'
	)
	(
		name="revlist2pr"
		input=$'1\n2\n3\n4'
		compound -A tail_args=(
			[legacy]=(   argv=( "+2r" ) )
			[std_like]=( argv=( "-n" "+2" "-r" ) )
		)
		expected_output=$'4\n3\n2'
	)
	(
		name="revlist3p"
		input=$'1\n2\n3\n4'
		compound -A tail_args=(
			[legacy]=(   argv=( "+3"  ) )
			[std_like]=( argv=( "-n" "+3"  ) )
		)
		expected_output=$'3\n4'
	)
	(
		name="revlist3pr"
		input=$'1\n2\n3\n4'
		compound -A tail_args=(
			[legacy]=(   argv=( "+3r" ) )
			[std_like]=( argv=( "-n" "+3" "-r" ) )
		)
		expected_output=$'4\n3'
	)
	(
		name="revlist4p"
		input=$'1\n2\n3\n4'
		compound -A tail_args=(
			[legacy]=(   argv=( "+4"  ) )
			[std_like]=( argv=( "-n" "+4"  ) )
		)
		expected_output=$'4'
	)
	(
		name="revlist4pr"
		input=$'1\n2\n3\n4'
		compound -A tail_args=(
			[legacy]=(   argv=( "+4r" ) )
			[std_like]=( argv=( "-n" "+4" "-r" ) )
		)
		expected_output=$'4'
	)
	(
		name="revlist5p"
		input=$'1\n2\n3\n4'
		compound -A tail_args=(
			[legacy]=(   argv=( "+5"  ) )
			[std_like]=( argv=( "-n" "+5"  ) )
		)
		expected_output=$''
	)
	(
		name="revlist5pr"
		input=$'1\n2\n3\n4'
		compound -A tail_args=(
			[legacy]=(   argv=( "+5r" ) )
			[std_like]=( argv=( "-n" "+5" "-r" ) )
		)
		expected_output=$''
	)
)

for testid in "${!testcases[@]}" ; do
	nameref tc=testcases[${testid}]

	for argv_variants in "${!tc.tail_args[@]}" ; do
		nameref argv=tc.tail_args[${argv_variants}].argv
		output=$(
				#set -o pipefail
	          		print -r -- "${tc.input}" | tail "${argv[@]}"
			) || err_exit "test ${tc.name}/${argv_variants}: command failed with exit code $?"
	
		[[ "${output}" == "${tc.expected_output}" ]] || err_exit "test ${tc.name}/${argv_variants}: Expected $(doublebackslashquote "${tc.expected_output}"), got $(doublebackslashquote "${output}")"
	done
done


# test2: test "tail -r </etc/profile | rev -l" vs. "cat </etc/profile"
[[ "$(tail -r </etc/profile | rev -l)" == "$( cat /etc/profile )" ]] || err_exit "'tail -r </etc/profile | rev -l' output does not match 'cat /etc/profile'" 


# test 3: ast-ksh.2009-05-05 "tail" builtin may crash if we pass unsupported long options
$SHELL -o errexit -c 'builtin tail ; print "hello" | tail --attack_of_chicken_monsters' >/dev/null 2>&1
(( $? == 2 )) || err_exit "expected exit code 2 for unsupported long option, got $?" 


# test 4: FIFO tests

# FIFO test functions
# (we use functions here to do propper garbage collection)
function test_tail_fifo_1
{
	typeset tail_cmd="$1"
	integer i
	integer tail_pid=-1
	
	# cleanup trap
	trap "rm -f tailtestfifo tailout" EXIT

	# create test FIFO
	mkfifo tailtestfifo

	${tail_cmd} -f <tailtestfifo >tailout &
	tail_pid=$!

	myintseq 20 >tailtestfifo

	waitpidtimeout ${tail_pid} 5

	if isvalidpid ${tail_pid} ; then
		err_exit "test_tail_fifo_1: # tail hung (not expected)"
		kill -KILL ${tail_pid}
	fi

	wait || err_exit "tail child returned non-zero exit code=$?"
	
	[[ "$(cat tailout)" == $'11\n12\n13\n14\n15\n16\n17\n18\n19\n20' ]] || err_exit "test_tail_fifo_1: Expected $(doublebackslashquote '11\n12\n13\n14\n15\n16\n17\n18\n19\n20'), got $(doublebackslashquote "$(cat tailout)")"

	return 0
}

function test_tail_fifo_2
{
	typeset tail_cmd="$1"
	integer i
	integer tail_pid=-1
	
	# cleanup trap
	trap "rm -f tailtestfifo tailout" EXIT

	# create test FIFO
	mkfifo tailtestfifo

	${tail_cmd} -f tailtestfifo >tailout &
	tail_pid=$!

	myintseq 14 >tailtestfifo

	waitpidtimeout ${tail_pid} 5

	if isvalidpid ${tail_pid} ; then
		[[ "$(cat tailout)" == $'5\n6\n7\n8\n9\n10\n11\n12\n13\n14' ]] || err_exit "test_tail_fifo_2: Expected $(doublebackslashquote $'5\n6\n7\n8\n9\n10\n11\n12\n13\n14'), got $(doublebackslashquote "$(cat tailout)")"

		myintseq 15 >>tailtestfifo

		waitpidtimeout ${tail_pid} 5

		if isvalidpid ${tail_pid} ; then
			kill -KILL ${tail_pid}
		else
			err_exit "test_tail_fifo_2: # tail exit with return code $? (not expected)"
		fi
	fi

	wait || err_exit "tail child returned non-zero exit code=$?"
	
	[[ "$(cat tailout)" == $'5\n6\n7\n8\n9\n10\n11\n12\n13\n14\n1\n2\n3\n4\n5\n6\n7\n8\n9\n10\n11\n12\n13\n14\n15' ]] || err_exit "test_tail_fifo_2: Expected $(doublebackslashquote $'5\n6\n7\n8\n9\n10\n11\n12\n13\n14\n1\n2\n3\n4\n5\n6\n7\n8\n9\n10\n11\n12\n13\n14\n15'), got $(doublebackslashquote "$(cat tailout)")"

	return 0
}

# fixme: This should test /usr/bin/tail and /usr/xpg4/bin/tail in Solaris
test_tail_fifo_1 "tail"
test_tail_fifo_2 "tail"


# test 5: "tail -f" tests
function followtest1
{
	typeset -r FOLLOWFILE="followfile.txt"
	typeset -r OUTFILE="outfile.txt"

	typeset title="$1"
	typeset testcmd="$2"
	typeset usenewline=$3
	typeset followstr=""
	typeset newline=""
	integer i
	integer tailchild=-1

	if ${usenewline} ; then
		newline=$'\n'
	fi
	
	rm -f "${FOLLOWFILE}" "${OUTFILE}"
	print -n "${newline}" > "${FOLLOWFILE}"

	${testcmd} -f "${FOLLOWFILE}" >"${OUTFILE}" &
	(( tailchild=$! ))

	for (( i=0 ; i < 10 ; i++)) ; do
		followstr+="${newline}${i}"
		print -n "${i}${newline}" >>"${FOLLOWFILE}"
		sleep 2

		[[ "$( < "${OUTFILE}")" == "${followstr}" ]] || err_exit "${title}: Expected $(doublebackslashquote "${followstr}"), got "$(doublebackslashquote "$( < "${OUTFILE}")")""
	done

	#kill -TERM ${tailchild} 2>/dev/null
	kill -KILL ${tailchild} 2>/dev/null
	waitpidtimeout ${tailchild} 5
	
	if isvalidpid ${tailchild} ; then
		err_exit "${title}: tail pid=${tailchild} hung."
		kill -KILL ${tailchild} 2>/dev/null
	fi
	
	wait ${tailchild} 2>/dev/null
	
	rm -f "${FOLLOWFILE}" "${OUTFILE}"

	return 0
}

followtest1 "test5a" "tail" true
# fixme: later we should test this, too:
#followtest1 "test5b" "tail" false
#followtest1 "test5c" "/usr/xpg4/bin/tail" true
#followtest1 "test5d" "/usr/xpg4/bin/tail" false
#followtest1 "test5e" "/usr/bin/tail" true
#followtest1 "test5f" "/usr/bin/tail" false


# cleanup
cd "${ocwd}"
rmdir "${tmpdir}" || err_exit "Cannot remove temporary directory ${tmpdir}".


# tests done
exit $((Errors))