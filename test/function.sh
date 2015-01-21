#!/bin/bash
# Script name: Function Check
# By: Gonzalo Gasca Meza, cloudtree.io
# Date: January 2015
#
# More info: To check CURL error codes visit http://curl.haxx.se/libcurl/c/libcurl-errors.html

##########################################################################################################################
trap "rm .f 2> /dev/null; exit" 0 1 3

function arguments {
	if [ $# -gt 3 ]
	then
    		echo "Error in $0 - Invalid Argument Count"
    		echo "Syntax: $0 arguments <Tenant_name>"
   	exit
	fi
	
	if [ $# -eq 2 ]
        then
                FIRST=$(echo "$1")
                SECOND=$(echo "$2")
                echo $FIRST
                echo $SECOND

	elif [ $# -eq 3 ]
	then
        	FIRST=$(echo "$1")
	        SECOND=$(echo "$2")
        	THIRD=$(echo "$3")
        	echo $FIRST
        	echo $SECOND
		echo $THIRD
	exit
	else
		echo "Error in $0 - Invalid Argument Count"
                echo "Syntax: $0 arguments uno dos tres"	
        	exit
	fi
	
		
}

arguments "Gonzalo" "Gasca" "Meza"
