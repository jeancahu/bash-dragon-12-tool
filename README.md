# bash-dragon-12-tool
Dragon 12 plus 2 simple command interface on bash shell, Archlinux.

Depends: screen, wine

## Install:

Run next bash script on repository directory.

    ./config
	
Add ~/.dragon\_12 directory to PATH environment variable.

	PATH=$PATH:$HOME/.dragon_12

Add the next line to your ~/.bashrc file.

	source $HOME/.dragon_12/dragon_12_vars_config.sh
	
Edit your assembler program PATH in dragon\_12\_vars\_config.sh file.

## Uninstall:

Remove script directory:
	rm -ir ~/dragon_12/

Delete all dragon_12 mentions in ~/.bashrc
