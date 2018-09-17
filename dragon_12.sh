#!/bin/bash

# Program tool to use dragon-12 with bash
# assambly, burn, run and execute debug-12 scripting
#
# Jeancarlo Hidalgo U. <jeancahu@gmail.com>

# Depends: screen, wine, wine-mono, wine_gecko, as12.exe

## Declare configuration variables

declare -l DRAGON_COLOR

source $HOME/.dragon_12/dragon_12_vars_config.sh 2>/dev/null || { echo 'Need configure' ; exit 0 ;}

## Define error codes

declare -ir EACNF=1  # Assambly code not found
declare -ir ELFNE=2  # List file name not specified
declare -ir EOFNNS=3 # Object file name not specified
declare -ir EMPCV=4  # PC initial value missed parameter
declare -ir ESPNWP=5 # Serial port has not write permission
declare -ir ESPNC=6  # Screen session do not exist
declare -ir EIUID=7  # Invalid user ID
declare -ir EASE=8   # Error syntax code
declare -ir EABNE=9  # Assamble program not found
declare -ir EFNR=10  # Flag has not been recognized
declare -ir EWINE=11 # Wine dependencies error
declare -ir ESNF=12  # Screen dependency missed
declare -ir EMSNF=13 # Simulator not found

## Define ANSI colors
if [ "$DRAGON_COLOR" == 'true' ]
   then
       declare -r ANSI_BLUE='\033[1;34m'
       declare -r ANSI_DARK_GREEN='\033[0;32m'
       declare -r ANSI_GREEN='\033[1;32m'
       declare -r ANSI_RED='\033[1;31m'
       declare -r ANSI_DARK_PURPLE='\033[0;35m'
       declare -r ANSI_PURPLE='\033[1;35m'
       declare -r ANSI_YELLOW='\033[1;33m'
       declare -r ANSI_NOCOLOR='\033[0m'
fi

## Define box variables

declare -r TL_COR='\u250F'
declare -r TR_COR='\u2513'
declare -r BL_COR='\u2517'
declare -r BR_COR='\u251B'
declare -r INTE_L='\u2523'
declare -r INTE_R='\u252B'
declare -r INTE_T='\u2533'
declare -r INTE_B='\u253B'
declare -r H_LINE0="$( for N in {0..64} ; do printf '\u2501' ; done )"
declare -r H_LINE1="${H_LINE0:0:3}$INTE_T${H_LINE0:4}"
declare -r H_LINE2="${H_LINE0:0:3}$INTE_B${H_LINE0:4}"
declare -r V_LINE='\u2503'

## Define BASH functions

function echo_error ()
{
    echo -e "$ANSI_RED""ERROR: $1""$ANSI_NOCOLOR" >&2
}

function echo_warning ()
{
    echo -e "$ANSI_YELLOW""WARNING: $1""$ANSI_NOCOLOR" >&2
}

function echo_help ()
{
    echo 'Usage: '"$( basename $0 )"' [OPTIONS] [ARG] ... [OPTIONS] [ARG]
    Flags interpretation:

    -h				Show this message, help option
    -f		<file.asm>   	Indicate <file>.asm script input
    -l		<file.lst>	Define list file name
    -o		<file.s19>	Define objet file name
    -a				Use asm12 to create the object file
    -b				Send the object file to board
    -g		<XXXX>		Indicate program counter initial value and run program on board, 16b HEX

    -c		[STRING]	Send a char/string to serial TTY, this does not permit spaces, all string is
    				concatenated, control chars are:
					      S	      Space
					      R	      CarrieReturn
    -C				Send a char/string to serial TTY, this does permit spaces,
    				control chars are:
					      S	      Space
					      R	      CarrieReturn
					      E	      Exit loop
    -s				Load .s19 file to simulate with. Use -o <file.s19> or/and -af <file.asm> to
    				indicate the object file input
    -S				Open TTY serial access to communicate with board through Terminal

Report bugs to: Jeancarlo Hidalgo U. <jeancahu@gmail.com>'
}

# FLAGS input, Args

if [ "$USER" == 'root' ] ; then echo_error 'You can\x27t use root privileges with this program' ; exit $EIUID ; fi

FLAGS=$( grep -o '^-[a-zA-Z0-9]*' <<< "$*" )
FLAGS=$FLAGS$( grep -o ' -[a-zA-Z0-9]*' <<< "$*" )

## Define flags/modes

declare -l HELP      #false
declare -l FILE      #false
declare -l LST       #false
declare -l OBJ       #false
declare -l ASSEMBLY  #false
declare -l BURN      #false
declare -l RUN       #false
declare -l SENDCHAR  #false
declare -l SCHARLOOP #false
declare -l SIM       #false
declare -l INIT_TTY  #false

## Define vars

declare -x IFILE=''      # Input file path
declare -x OFILE=''      # File.s19 name
declare -x LFILE=''      # File.lst name
declare -x LOGFILE=''    # Log file name

declare -l SUB_COMM="$1" # Sub command

## Verify flags

if (( $( grep -c 'h' <<< "$FLAGS" ) )); then HELP=true      ; fi
if (( $( grep -c 'f' <<< "$FLAGS" ) )); then FILE=true      ; fi
if (( $( grep -c 'l' <<< "$FLAGS" ) )); then LST=true       ; fi
if (( $( grep -c 'o' <<< "$FLAGS" ) )); then OBJ=true       ; fi
if (( $( grep -c 'g' <<< "$FLAGS" ) )); then RUN=true       ; fi
if (( $( grep -c 'a' <<< "$FLAGS" ) )); then ASSEMBLY=true  ; fi
if (( $( grep -c 'b' <<< "$FLAGS" ) )); then BURN=true      ; fi
if (( $( grep -c 'c' <<< "$FLAGS" ) )); then SENDCHAR=true  ; fi
if (( $( grep -c 'C' <<< "$FLAGS" ) )); then SCHARLOOP=true ; fi
if (( $( grep -c 's' <<< "$FLAGS" ) )); then SIM=true       ; fi
if (( $( grep -c 'S' <<< "$FLAGS" ) )); then INIT_TTY=true  ; fi

if [ $( sed 's/[hflogabcCsS-]//g;s/ //g' <<< "$FLAGS" ) ]
then
    echo_error "The expression $( sed 's/[hflogabcCsS]//g;s/- //g' <<< $FLAGS ) has not been recognized"
    exit $EFNR
elif [ $( grep -o '\- ' <<< "$FLAGS" | head -c 1 ) ] || [ $( grep -o '\-$' <<< "$FLAGS" | head -c 1 ) ]
then
    echo_error 'There is a missing flag parameter'
    exit $EFNR
fi

## Child process:

if [ $HELP ] || [ -z "$1" ] # HELP
then
    echo_help
    exit 0
fi

if [ $INIT_TTY ] # Init_TTY
then
    if which screen &>/dev/null
    then
	:
    else
	echo_error '\x27screen\x27 dependency is missed'
	exit $ESNF
    fi

    if [ -r "$DRAGON_SERIAL_PORT" ] && [ -w "$DRAGON_SERIAL_PORT" ]
    then
	:
    else
	echo_error "The program need write-read permissions on $DRAGON_SERIAL_PORT
	You could do:
	    $ sudo chmod 0666 $DRAGON_SERIAL_PORT
	    or
	    $ sudo chown $USER $DRAGON_SERIAL_PORT
       	other option is edit your UDEV rules to allow non-root access to fake serial devices permanently
	You can add your user to Unix-to-Unix devices group too"
	exit $ESPNWP
    fi

    if [ -z "$( screen -ls | grep -v '^No' | grep -o $DRAGON_SESSION_NAME )" ]
    then
	screen -S $DRAGON_SESSION_NAME $DRAGON_SERIAL_PORT $DRAGON_SERIAL_SPEED
	exit 0
    else
	screen -x $DRAGON_SESSION_NAME
	exit 0
    fi
fi

if [ $FILE ] # FILE.asm
then
    IFILE="$( echo $* | grep -o '\-[a-z]\{0,\}f [\#0-9a-zA-Z/\.\_\ -]*\.asm' | sed 's/\\ / /g' | cut --delimiter=' ' -f 2- )"
    if [ -e "${IFILE}" ]
    then
	:
    else
	if [ "${IFILE}" ]; then IFILE="${IFILE} "; fi
	echo_error 'File '"$IFILE"'don\x27t exist or format is not correct, need to have \x27.asm\x27 suffix'
	exit $EACNF
    fi

    echo -e "Input file: $ANSI_GREEN""${IFILE}""$ANSI_NOCOLOR"
fi

if [ $LST ] # FILE.lst
then
    LFILE="$( echo $* | grep -o '\-[a-z]\{0,\}l [\#0-9a-zA-Z/\.\_\ -]*\.lst' | cut --delimiter=' ' -f 2- )"

    if [ -z "$LFILE" ]
    then
	echo_error 'File out list need have \x27.lst\x27 suffix'
	exit $ELFNE
    else
	:
    fi
    echo -e "List file name: $ANSI_GREEN""$LFILE""$ANSI_NOCOLOR"
fi

if [ $OBJ ] # FILE.s19
then
    OFILE="$( echo $* | grep -o '\-[a-z]\{0,\}o [\#0-9a-zA-Z/\.\_\ -]*\.s19' | cut --delimiter=' ' -f 2- )"

    if [ -z "$OFILE" ]
    then
	echo_error 'Object out file need have \x27.s19\x27 suffix'
	exit $EOFNNS
    else
	:
    fi

    echo -e "Object file name: $ANSI_GREEN""$OFILE""$ANSI_NOCOLOR"

fi

## AS12
if [ $ASSEMBLY ] && [ $FILE ] # ASSEMBLY
then

    if [ ! -d $DRAGON_AS12_PATH ] || [ ! -f $DRAGON_AS12_PATH/$DRAGON_AS ]
    then
	echo_warning 'No such assembler program, please put your assembler directory in ~/.dragon_12'
	exit $EABNE
    fi

    if [ $OBJ ] && [ $LST ]
    then
	:
    elif [ $OBJ ]
    then
	LFILE="$( sed s/\.asm/\.lst/ <<< "${IFILE}" )"
    elif [ $LST ]
    then
	OFILE="$( sed s/\.asm/\.s19/ <<< "${IFILE}" )"
    else
	LFILE="$( sed s/\.asm/\.lst/ <<< "${IFILE}" )"
	OFILE="$( sed s/\.asm/\.s19/ <<< "${IFILE}" )"
    fi

    LOGFILE="$( sed s/\.asm/\.log/ <<< "${IFILE}" )"

    echo "$( date )" > $LOGFILE
    echo "
    Assembling with $DRAGON_AS"

    # Call WINE for assembly execution

    nohup bash -c 'bash -c "WINEDEBUG=fixme-all wine $DRAGON_AS12_PATH/$DRAGON_AS $IFILE -L$LFILE -o$OFILE" >> $LOGFILE' > /dev/null 2>&1 < /dev/null

    if (( $( wc -l $LOGFILE | cut -f 1 --delimiter=' ' ) -1 ))
    then
	:
    else
	echo_error 'Wine is not working, resolve dependencies.'
	exit $EWINE
    fi

    echo "
    $DRAGON_AS results log: "
    cat "$LOGFILE"
    echo ''


    if [ -z "$( grep 'Total errors: 0' "$LOGFILE" )" ] ; then exit $EASE ; fi

elif [ $ASSEMBLY ]
then
    echo_error 'You need indicate the .ASM file with -f flag'
fi
##

## Program need needs at least one tty running
if [ -z "$( screen -ls | grep -v '^No' | grep -o $DRAGON_SESSION_NAME )" ] && [ $BURN$RUN$SENDCHAR$SCHARLOOP ]
then
    echo_warning 'First run on a new bash child process or terminal
    $'" $( echo $0 | grep -o [a-z0-9A-Z_\.-]*$ )"' -S
to create a TTY serial device access'
    exit $ESPNC
fi
##

if [ $BURN ] && [ "$OFILE" ] # Load program on Dragon_12 board
then
    echo -e "$ANSI_YELLOW
 $TL_COR$H_LINE0$TR_COR
 $V_LINE   $ANSI_GREEN"'Burn Dragon 12 board with '"$( rev <<< "$OFILE" | cut -f 1 --delimiter='/' | rev ) : $ANSI_YELLOW	                   $V_LINE
 $INTE_L$H_LINE1$INTE_R$ANSI_NOCOLOR"
    screen -S $DRAGON_SESSION_NAME -X stuff 'load\r'
    TAMS19FILE=$( wc "$OFILE" | sed 's/ * / /g' | cut -f 2 --delimiter=' ' )
    COUNTERS19=0
    DIRECTION_BEG=0
    DIRECTION_END=0
    for LINES19 in $( cat "$OFILE" )
    do
	COUNTERS19=$(( $COUNTERS19 + 1 ))
	sleep $DRAGON_WAIT_SEND_LINE
	LINES19_P="$( sed 's/^S./& /g;s/ ../& /;s/ [0-9A-F]\{4\}/& /;s/.\{3\}$/ &/;s/  / /' <<< $LINES19 )"
	if [ "$COUNTERS19" == '1' ] && [ "48" -lt "$( echo "$LINES19_P" | wc -c )" ]
	then
		LINES19_P="${LINES19_P:0:42} ..."
	fi
	DIRECTION_BEG=$(( 0X${LINES19:4:4} ))
	DIRECTION_END=$(( $DIRECTION_BEG + 0X${LINES19:2:2} - 3 ))
	if (( $DIRECTION_END > $DRAGON_RAM_END )) || (( $DIRECTION_BEG < $DRAGON_RAM_BEG ))
	then
	    if [ "${LINES19:0:2}" == 'S1' ]
	    then
		echo -e "$ANSI_YELLOW"' +$H_LINE2+'"$ANSI_NOCOLOR"
		echo -en '    '"$ANSI_YELLOW"'WARNING: Direction is out of RAM range\n    You really want to flash that space? [yes/NO] '"$ANSI_NOCOLOR"
		read CMD
		if [ "${CMD,,}" == 'yes' ]
		then
		    :
		else
		    screen -S $DRAGON_SESSION_NAME -X stuff "$( echo S9030000FC )"
		    exit 0 # That is not an error, it is an option, stop burning
		fi
		echo -e "$ANSI_YELLOW $BL_COR$H_LINE2$BR_COR$ANSI_NOCOLOR"
	    fi
	fi

	PERCENT="$( echo " $V_LINE$(( ${COUNTERS19}00 / $TAMS19FILE ))" | tr -d '\c' )"
	echo -ne '                                                                   '"$ANSI_YELLOW$V_LINE$ANSI_NOCOLOR"'\r'
	echo -ne "$V_LINE    $ANSI_YELLOW$V_LINE$ANSI_NOCOLOR % => $ANSI_PURPLE""Send""$ANSI_NOCOLOR : $ANSI_BLUE""$LINES19_P""$ANSI_NOCOLOR"
	echo -e '\r'"$ANSI_YELLOW""$PERCENT"'\r'

	echo -ne "$ANSI_YELLOW $BL_COR$H_LINE2$BR_COR$ANSI_NOCOLOR"'\r'

	screen -S $DRAGON_SESSION_NAME -X stuff "$( echo $LINES19 | tr -d '\r' )"
    done
    echo -e "$ANSI_YELLOW $BL_COR$H_LINE2$BR_COR$ANSI_NOCOLOR"
    screen -S $DRAGON_SESSION_NAME -X stuff '\n\n\n\n\n' # Send a newline char
elif [ $BURN ]
     then
	 echo_error "Please use the -o option to indicate the object file
	 \$ $( echo $0 | grep -o [a-z0-9A-Z_\.-]*$ ) -b -o <file.s19>
	 or
	 \$ $( echo $0 | grep -o [a-z0-9A-Z_\.-]*$ ) -bo   <file.s19>"
fi

if [ $RUN ] # Instruction pointer / Program counter
then
    INITIAL_PC="$( echo $* | grep -o '\-[a-z]\{0,\}g [A-F0-9]\{1,4\}' | cut --delimiter=' ' -f 2 )"

    if [ -z "$INITIAL_PC" ]
    then
	echo_error 'You have to insert PC inital value next to the -g flag'
	exit $EMPCV
    else
	:
    fi

    screen -S $DRAGON_SESSION_NAME -X stuff "g $INITIAL_PC"'\r'

    echo "
    PC initial value: $INITIAL_PC
    RUNNING
    "

fi

if [ $SENDCHAR ] && [ ! $SCHARLOOP ] # Send char to TTYUSBX/ttySX
then
    CHAR="$( echo $* | grep -o '\-[a-z]\{0,\}c [\.SRa-z0-9]\{1,\}' | cut --delimiter=' ' -f 2- )"

    if [ -z "$CHAR" ]
    then
	echo -n "    Insert the string/char => "
	read CHAR
	CHAR=$( echo $CHAR | sed 's/ * / /g' | sed 's/ R /R/g' | tr ' ' 'S' )
    else
	:
    fi
    for TEMP_STRING in $( echo $CHAR | sed 's/R/@R/g' | tr 'R' '\n' )
    do
	sleep $DRAGON_WAIT_COMMAND
	screen -S $DRAGON_SESSION_NAME -X stuff "$( echo $TEMP_STRING | tr '@' '\r' | tr 'S' ' ' )"
	echo " $( sed 's/@/ %CARRIERETURN% /g' <<< $TEMP_STRING | sed 's/S/ %SPACE% /g' ) => $DRAGON_SESSION_NAME"
    done
fi

if [ $SCHARLOOP ] # Send char to TTYUSBX/ttySX
then
    CHAR=''
    while :
    do
    	echo -n "    Insert the string/char => "
	read CHAR
	CHAR=$( sed 's/ * / /g;s/ R /R/g' <<< $CHAR | tr ' ' 'S' )

	if [ "$CHAR" == 'E' ] ; then exit 0 ; fi

	    for TEMP_STRING in $( sed 's/R/@R/g' <<< $CHAR | tr 'R' '\n' )
	    do
		sleep $DRAGON_WAIT_COMMAND
		screen -S $DRAGON_SESSION_NAME -X stuff "$( echo $TEMP_STRING | tr '@' '\r' | tr 'S' ' ' )"
		echo " $( sed 's/@/ %CARRIERETURN% /g;s/S/ %SPACE% /g' <<< $TEMP_STRING ) => $DRAGON_SESSION_NAME"
	    done
    done
fi

if [ $SIM ]
then
    echo 'Opening simulator'
    if [ "$OFILE" ]
    then
	:
    else
	echo_warning "Warning, no object file specified with -o <file.s19> or -af <file.asm>"
    fi

    if [ -f $DRAGON_SIMULATOR_PATH/$DRAGON_SIMULATOR ]
    then
        which java &>/dev/null && java -jar $DRAGON_SIMULATOR_PATH/$DRAGON_SIMULATOR -s -b $OFILE &# Then execute simulator
        test $? -eq 0 || echo_warning 'Java not found'
    else
        echo_error "Simulator \x27$DRAGON_SIMULATOR_PATH/$DRAGON_SIMULATOR\x27 not found."
	exit $EMSNF
    fi
fi

# Main process, subcommands

case $SUB_COMM in
    simulator) # Open simulator
	echo 'Opening simulator'
	cd $DRAGON_SIMULATOR_PATH  # First go where is configuration file
	if [ -f $DRAGON_SIMULATOR ]
	then
	    which java &>/dev/null && java -jar $DRAGON_SIMULATOR # Then execute simulator
	    test $? -eq 0 || echo_warning 'Java no found'
	fi
	cd - # Return
	;;
    [!-]*)
	echo_help
	;;
esac

# All is done, and it have no errors
exit 0
