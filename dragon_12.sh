#!/bin/bash

# Programa para realizar distintas tareas sobre la tarjeta dragon-12
# desde ensamblar, quemar, correr y ejecutar debug-12 scripting
#
# Jeancarlo Hidalgo U. <jeancahu@gmail.com>

# Depends: screen, wine, openjdk, python

# FLAGS input, Args

if [ "$USER" == 'root' ] ; then echo 'You can`t use root privileges with this program' >&2 ; exit 7 ; fi

FLAGS=$( echo $* | grep -o '^-[a-zCS]*' )
FLAGS=$FLAGS$( echo $* | grep -o ' -[a-zCS]*' )

## Define flags/modes

HELP=''      #false
FILE=''      #false
LST=''       #false
OBJ=''       #false
ASSEMBLY=''  #false
BURN=''      #false
RUN=''       #false
SENDCHAR=''  #false
SCHARLOOP='' #false
INIT_TTY=''  #false

## Define vars

IFILE=''
OFILE='' # File.asm name
LFILE=''

## Verify flags

if [ "$( echo $FLAGS | grep -o 'h' | head -c 1 )" == "h" ]; then HELP=true      ; fi
if [ "$( echo $FLAGS | grep -o 'f' | head -c 1 )" == "f" ]; then FILE=true      ; fi
if [ "$( echo $FLAGS | grep -o 'l' | head -c 1 )" == "l" ]; then LST=true       ; fi
if [ "$( echo $FLAGS | grep -o 'o' | head -c 1 )" == "o" ]; then OBJ=true       ; fi
if [ "$( echo $FLAGS | grep -o 'g' | head -c 1 )" == "g" ]; then RUN=true       ; fi
if [ "$( echo $FLAGS | grep -o 'a' | head -c 1 )" == "a" ]; then ASSEMBLY=true  ; fi
if [ "$( echo $FLAGS | grep -o 'b' | head -c 1 )" == "b" ]; then BURN=true      ; fi
if [ "$( echo $FLAGS | grep -o 'c' | head -c 1 )" == "c" ]; then SENDCHAR=true  ; fi
if [ "$( echo $FLAGS | grep -o 'C' | head -c 1 )" == "C" ]; then SCHARLOOP=true ; fi
if [ "$( echo $FLAGS | grep -o 'S' | head -c 1 )" == "S" ]; then INIT_TTY=true  ; fi

#echo $ASSEMBLY $BURN $RUN $FILE $OBJ $LST $HELP

## Child process:

if [ $HELP ] || [ -z "$1" ] # HELP
then
    echo 'Usage: '"$( echo $0 | grep -o [a-z0-9A-Z_\.-]*$ )"' [OPTIONS] [ARG] ... [OPTIONS] [ARG]
    Flags interpretation:

    -h				Show this message, help option
    -f		<file.asm>   	Indicate <file>.asm script input
    -l		<file.lst>	Define list file out name 
    -o		<file.s19>	Define objet file out name
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
					      R	      CarrieRetur	
					      E	      Exit loop
    -S				Open TTY serial access to communicate with board through Terminal

Report bugs to: Jeancarlo Hidalgo U. <jeancahu@gmail.com>'
    exit 0
fi

if [ $INIT_TTY ] # Init_TTY
then
    if [ -z "$( ls -al /dev/ttyUSB0 | grep crw.rw.rw. )" ] && [ -z "$( ls -al /dev/ttyUSB0 | grep -o $USER )" ]
    then
	echo "The program need write-read permissions on $DRAGON_SERIAL_PORT
	You could do:
	    $ sudo chmod 0666 $DRAGON_SERIAL_PORT
	    or
	    $ sudo chown $USER $DRAGON_SERIAL_PORT
       	other option is edit your UDEV rules to allow non-root access to serial devices permanently" >&2
	exit 5
    else
	:
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
    IFILE="$( echo $* | grep -o '\-[a-z]\{0,\}f [\#0-9a-zA-Z\.\_\ -]*\.asm' | cut --delimiter=' ' -f 2- )"
    if [ -e "$IFILE" ]
    then
	:
    else
	echo 'File don`t exist or format is not correct.' >&2
	exit 1
    fi

    echo "Input file: $IFILE"
fi

if [ $LST ] # FILE.lst
then
    LFILE="$( echo $* | grep -o '\-[a-z]\{0,\}l [0-9a-zA-Z\.\_\ -]*\.lst' | cut --delimiter=' ' -f 2- )"    

    if [ -z "$LFILE" ]
    then
	echo 'File out list need have .lst suffix.' >&2
	exit 2
    else
	:
    fi

    echo "List file name: $LFILE"
    
fi

if [ $OBJ ] # FILE.s19
then
    OFILE="$( echo $* | grep -o '\-[a-z]\{0,\}o [0-9a-zA-Z\.\_\ -]*\.s19' | cut --delimiter=' ' -f 2- )"    

    if [ -z "$OFILE" ]
    then
	echo 'File out object don`t exist or need have .s19 suffix.' >&2
	exit 3
    else
	:
    fi

    echo "Object file name: $OFILE"
    
fi

## AS12
if [ $ASSEMBLY ] && [ $FILE ] # ASSEMBLY
then
    
    if [ ! -d $DRAGON_AS12_PATH ]
    then
	echo 'No such assembler program, please put your assembler directory in ~/.dragon_12'
	exit 9
    fi
    
    if [ $OBJ ] && [ $LST ]
    then
	:
    elif [ $OBJ ]
    then	
	LFILE=$( echo "$IFILE" | sed s/\.asm/\.lst/ )
    elif [ $LST ]
    then
	OFILE=$( echo "$IFILE" | sed s/\.asm/\.s19/ )	
    else
	LFILE=$( echo "$IFILE" | sed s/\.asm/\.lst/ )
	OFILE=$( echo "$IFILE" | sed s/\.asm/\.s19/ )	
    fi

    export IFILE
    export OFILE
    export LFILE    
    export LOGFILE=$( echo "$IFILE" | sed s/\.asm/\.log/ )    

    echo "$( date )" > $LOGFILE
    echo "
    Assembling with $DRAGON_AS"

    # Call WINE for assembly execution
    nohup bash -c 'bash -c "WINEDEBUG=fixme-all wine $DRAGON_AS12_PATH/$DRAGON_AS $IFILE -L$LFILE -o$OFILE" >> $LOGFILE' > /dev/null 2>&1 < /dev/null

    echo "
    $DRAGON_AS results log: "
    cat $LOGFILE

    if [ -z "$( grep 'Total errors: 0' $LOGFILE )" ] ; then exit 8 ; fi
    
elif [ $ASSEMBLY ]
then
    echo 'You need indicate the .ASM file' >&2
fi
##

## Program need needs at least one tty running
if [ -z "$( screen -ls | grep -v '^No' | grep -o $DRAGON_SESSION_NAME )" ] && [ $BURN$RUN$SENDCHAR$SCHARLOOP ]
then
    echo 'First run on a new bash child process or terminal
    $'" $( echo $0 | grep -o [a-z0-9A-Z_\.-]*$ )"' -S
to create a TTY serial device access' >&2
    exit 6
fi
##


if [ $BURN ] && [ $OFILE ] # Load program on Dragon_12 board
then
    echo '
 +-----------------------------------------------------------------+
 |   Burn Dragon 12 board with '"$OFILE : "'	                   |
 +-----------------------------------------------------------------+'
    screen -S $DRAGON_SESSION_NAME -X stuff 'load\r'
    TAMS19FILE=$( wc $OFILE | sed 's/ * / /g' | cut -f 2 --delimiter=' ' )    
    COUNTERS19=0
    DIRECTION_BEG=0
    DIRECTION_END=0
    for LINES19 in $( cat $OFILE )
    do
	COUNTERS19=$(( $COUNTERS19 + 1 ))
	sleep $DRAGON_WAIT_SEND_LINE
	LINES19_P="$( echo $LINES19 | sed 's/^S./& /g' | sed 's/ ../& /' | sed 's/ [0-9A-F]\{4\}/& /' | sed 's/.\{3\}$/ &/' | sed 's/  / /' )"
	DIRECTION_BEG=$(( 0X"$( echo $LINES19 | head -c 8 | tail -c 4 | tee )" ))
	DIRECTION_END=$(( $DIRECTION_BEG + 0X"$( echo $LINES19 | head -c 4 | tail -c 2 | tee )" - 3 ))	
	if (( $DIRECTION_END > $DRAGON_RAM_END )) || (( $DIRECTION_BEG < $DRAGON_RAM_BEG ))
	then
	    if [ "$( echo $LINES19 | head -c 2 )" == 'S1' ]
	    then
		echo ' +-----------------------------------------------------------------+'
		echo -en '    WARNING: Direction is out of RAM range\n    You really want to flash that space? [yes/NO] '		
		read CMD		
		if [ "$( echo $CMD | tr 'A-Z' 'a-z' )" == 'yes' ]
		then
		    :
		else		    
		    screen -S $DRAGON_SESSION_NAME -X stuff "$( echo S9030000FC )"
		    exit 0 # That is not an error, it is an option, stop burning
		fi
		echo ' +-----------------------------------------------------------------+'
	    fi
	fi

	PERCENT="$( echo ' |'"$(( ${COUNTERS19}00 / $TAMS19FILE ))" | tr -d '\c' )"
	echo -ne '                                                                   |\r'
	echo -n "|    | % => Send : $LINES19_P"	
	echo "$PERCENT"

	echo -ne ' +-----------------------------------------------------------------+\r'
	
	screen -S $DRAGON_SESSION_NAME -X stuff "$( echo $LINES19 | tr -d '\r' )"
    done
    echo ' +-----------------------------------------------------------------+'
    screen -S $DRAGON_SESSION_NAME -X stuff '\n\n\n\n\n' # Send a newline char
elif [ $BURN ]
     then
	 echo "Please use the -o option to indicate the object file
	 \$ $( echo $0 | grep -o [a-z0-9A-Z_\.-]*$ ) -b -o <file.s19>
	 or
	 \$ $( echo $0 | grep -o [a-z0-9A-Z_\.-]*$ ) -bo   <file.s19>" >&2
fi

if [ $RUN ] # Instruction pointer / Program counter
then    
    INITIAL_PC="$( echo $* | grep -o '\-[a-z]\{0,\}g [A-F0-9]\{1,4\}' | cut --delimiter=' ' -f 2 )"    

    if [ -z "$INITIAL_PC" ]
    then
	echo 'You have to insert PC inital value next to the -g flag' >&2
	exit 4
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
	echo " $( echo $TEMP_STRING | sed 's/@/ %CARRIERETURN% /g' | sed 's/S/ %SPACE% /g' ) => $DRAGON_SESSION_NAME"	
    done
fi

if [ $SCHARLOOP ] # Send char to TTYUSBX/ttySX
then
    CHAR=''
    while true	  
    do
    	echo -n "    Insert the string/char => "
	read CHAR
	CHAR=$( echo $CHAR | sed 's/ * / /g' | sed 's/ R /R/g' | tr ' ' 'S' )
	
	if [ "$CHAR" == 'E' ] ; then exit 0 ; fi     

	    for TEMP_STRING in $( echo $CHAR | sed 's/R/@R/g' | tr 'R' '\n' )
	    do
		sleep $DRAGON_WAIT_COMMAND
		screen -S $DRAGON_SESSION_NAME -X stuff "$( echo $TEMP_STRING | tr '@' '\r' | tr 'S' ' ' )"
		echo " $( echo $TEMP_STRING | sed 's/@/ %CARRIERETURN% /g' | sed 's/S/ %SPACE% /g' ) => $DRAGON_SESSION_NAME"	
	    done
    done
fi

## Main process, subcommands

# Implementar como un case

if [ "$( echo $1 | tr 'A-Z' 'a-z' )" == 'simulator' ] # Open simulator
then 
    echo 'Opening simulator'
    cd $DRAGON_SIMULATOR_PATH  # First go where is configuration file
    if [ -f $DRAGON_SIMULATOR ]
    then
	java -jar $DRAGON_SIMULATOR # Then execute simulator
    fi
    cd - # Return
fi

# All is done, and it have no errors
exit 0
