#!/bin/bash
# Script name: Create Tenant and VM instance 
# By: Gonzalo Gasca Meza, Cloudtree.io
# Date: January, 2015
# Command Line: init.sh
# Purpose: Serve as instance provisioning passing parameters to openstack functions
#
#
# More info: To check CURL error codes visit http://curl.haxx.se/libcurl/c/libcurl-errors.html

##########################################################################################################################
set -x
trap "rm .f 2> /dev/null; exit" 0 1 3
VERSION=0.1
FILE="localrc"

function init {
if [ -f $FILE ]; then
	source $FILE
	echo -e "Processing credentials..."
else
	echo "No $FILE exists, please provide valid input"
	exit 1
fi
}

##########################################################################################################################

function get_field() {
    while read data; do
        if [ "$1" -lt 0 ]; then
            field="(\$(NF$1))"
        else
            field="\$$(($1 + 1))"
        fi
        echo "$data" | awk -F'[ \t]*\\|[ \t]*' "{print $field}"
    done
}

function check {
         ERROR_CODE=$(echo "$?")
     if [ $ERROR_CODE -ne 0 ]; then
         echo "Error ($ERROR_CODE) occurred"
         #      alarm $ERROR_CODE
         if [ $ERROR_CODE -eq 6 ]; then
             echo "Error ($ERROR_CODE) Unable to resolve host"
         fi
         if [ $ERROR_CODE -eq 7 ]; then
             echo "Error ($ERROR_CODE) Unable to connect to host"
         fi
         return 1
     fi
}

##########################################################################################################################

function create_tenant {
	if [ $# -ne 1 ]
	then
    		echo "Error in $0 - Invalid Argument Count"
    		echo "Syntax: $0 create_tenant <Tenant_name>"
   	exit
	fi
	TENANT_NAME=$(echo "$1")
	keystone tenant-list
	keystone tenant-create --name=$TENANT_NAME
	check;
	create_adminuser_tenant $TENANT_NAME		
}

function create_adminuser_tenant {
	if [ $# -ne 1 ]
        then
                echo "Error in $0 - Invalid Argument Count"
                echo "Syntax: $0 create_tenant <Tenant_name>"
        exit
        fi
	#TODO Create admin user for each new tenant and store credentials in database
		
}

function get_tenant_id {
	# Returns tenant ID, do not validate if TENANT is enabled or not
	if [ $# -ne 1 ]
        then
                echo "Error in $0 - Invalid Argument Count"
                echo "Syntax: $0 get_tenant_id <Tenant_name>"
        exit
	fi
	#echo "Displaying Tenant list for customers..."
	TENANT_ID=`keystone tenant-list | grep $1 | get_field 1`
	echo $TENANT_ID
}

function create_user {
	# Creates user create_user "batman" "05bd03f7e39b403eb523f3c1a3fe4dbb" "batman@gotham.gov"
        if [ $# -gt 3 ]
        then
                echo "Error in $0 - Invalid Argument Count"
                echo "Syntax: $0 create_user username tenant_id email"
        exit
        fi
	keystone user-create --name=$1 \
			--tenant_id=$2 \
                     --email=$3	
	keystone user-list --tenant_id=$2	
}

# Nova Functions

function create_key {
        # Creates private key for specific tenant
	if [ $# -ne 1 ]
        then
                echo "Error in $0 - Invalid Argument Count"
                echo "Syntax: $0 create_key <Tenant_name>"
        exit
        fi	
	KEY_NAME=$(echo "$1")	
	#TODO Source tenant credentials
	nova keypair-add $KEYNAME > keys/$KEYNAME."pem"
	#TODO Move Keys to Safe location at creation time
	check;	
}

function create_security_group {
        # Create security group
	if [ $# -gt 2 ]
        then
                echo "Error in $0 - Invalid Argument Count"
                echo "Syntax: $0 create_security_group <Name>"
        exit
        fi
        SEC_GROUP=$(echo "$1")
	DESCRIPTION=$(echo "$2")
        nova secgroup-create $SEC_GROUP "$DESCRIPTION"
        check;
	echo "Printing " . $SEC_GROUP . " security rules"
	nova secgroup-list-rules $SEC_GROUP
}

############

init;
#create_tenant "yahoo";
#TENANT_ID=`get_tenant_id "yahoo"`;
#sleep 10
#create_user "joker" $TENANT_ID "joker@gotham.gov";
#create_key "yahoo";
create_security_group "voice" "Allow SIP and RTP traffic"