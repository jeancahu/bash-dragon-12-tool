# bash-dragon-12-tool
Dragon 12 plus 2 simple command interface on bash shell, Archlinux.

Recommended: bash 4.4+

Depends: screen, wine

## Install:

First clone the repository directory.

    git clone https://github.com/jeancahu/bash-dragon-12-tool.git ~/.dragon_12
	
Add ~/.dragon\_12 directory to PATH environment variable.

	PATH=$PATH:$HOME/.dragon_12
	
Edit your assembler program PATH in dragon\_12\_vars\_config.sh file.

## Uninstall:

Remove script directory:

	rm -ir ~/.dragon_12/

## How to use:
| Flag | Interpretation |
| ------ | ------ |
| -h     | Show this message, help option. |
|  -f <file.asm> | Indicate <file>.asm script input. |
| -l		<file.lst> | Define list file out name. |
| -o <file.s19> | Define object file out name. |
| -a | Use asm12 to create the object file. |
| -b | Send the object file to board. |
|-g		<XXXX>| Indicate program counter initial value and run program on board, 16b HEX. |
|-c		[STRING]| Send a char/string to serial TTY. This does not permit spaces, all string is concatenated. <br/> Control chars are: <br/>-S Space <br/> -R CarrieReturn|
|-C|Send a char/string to serial TTY. This does permit spaces. <br/>Control chars are: <br/>-S Space <br/>-R CarrieReturn <br/> -E Exit loop|
| -S |	Open TTY serial access to communicate with board through Terminal|
First, open a terminal to communicate over RS232 with the board.

    dragon_12.sh -S
