#!/bin/bash
# Script name: Create Tenant and VM instance 
# By: Gonzalo Gasca Meza, Cloudtree.io
# Date: January, 2015
# Command Line: openstack_cli.sh
# Purpose: Serve as instance provisioning passing parameters to openstack functions
#
#
# More info: To check CURL error codes visit http://curl.haxx.se/libcurl/c/libcurl-errors.html

##########################################################################################################################
set -x
trap "rm .f 2> /dev/null; exit" 0 1 3
VERSION=0.1
FILE="localrc"

##########################################################################################################################
# * Source Credentials *
function read_configuration {
if [ -f $FILE ]; then
	source $FILE
	echo -e "Processing credentials...from credentials file"
else
	echo "No $FILE exists, please provide valid input"
	exit 1
fi
}

##########################################################################################################################

function get_field {
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
        if [ $ERROR_CODE -eq 409 ]; then
             echo "Error ($ERROR_CODE) Duplicate entry"
        fi
        return 1
    fi
}

##########################################################################################################################
# Provision a new customer

function create_tenant {
	if [ $# -ne 1 ]
	then
    		echo "Error in $0 - Invalid Argument Count"
    		echo "Syntax: $0 create_tenant <Tenant_name>"
   	exit
	fi
    echo "Creating Tenant..."
	TENANT_NAME=$(echo "$1")
	keystone tenant-list
	keystone tenant-create --name=$TENANT_NAME
	check;
    # Associates admin user by default to new tenant so we can manage it
	DEFAULT_USERNAME="admin"
	associate_user_to_tenant $DEFAULT_USERNAME $TENANT_NAME		
}

function associate_user_to_tenant {
	if [ $# -ne 2 ]
        then
                echo "Error in $0 - Invalid Argument Count"
                echo "Syntax: $0 associate_user_to_tenant <username> <tenant_name>"
        exit
    fi

	USERNAME=$(echo "$1")
	TENANT_NAME=$(echo "$2")
    # Get Tenant ID
	TENANT_ID=`get_tenant_id $2`
    # Get Role ID for admin user
	ROLE_ID=`keystone role-list | grep $USERNAME | get_field 1`
	keystone user-role-add --user=$USERNAME --role=$ROLE_ID --tenant-id=$TENANT_ID
	create_user $TENANT_NAME $TENANT_ID
	keystone user-role-add --user=$TENANT_NAME --role=$ROLE_ID --tenant-id=$TENANT_ID 
	check;		
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
        ENABLE_USER=true
        DEFAULT_PASSWORD="M1Nub3"
	   # Creates user create_user "batman" "05bd03f7e39b403eb523f3c1a3fe4dbb" "batman@gotham.gov"
        if [ $# -gt 3 ]
        then
                echo "Error in $0 - Invalid Argument Count"
                echo "Syntax: $0 create_user username tenant_id email"
        exit
        fi
	
        if [ $# -eq 2 ]
        then
                keystone user-create --name=$1 --tenant_id=$2 --pass $DEFAULT_PASSWORD --enabled $ENABLE_USER
                keystone user-list --tenant_id=$2
        elif [ $# -eq 3 ]
        then
                keystone user-create --name=$1 --tenant_id=$2 --email=$3 --pass $DEFAULT_PASSWORD --enabled $ENABLE_USER
                keystone user-list --tenant_id=$2
        else
                echo "Error in $0 - Invalid Argument Count"
                echo "Syntax: $0 create_user <name> <tenantid> <email>"        
                exit
        fi
	
}

# *** Nova Functions ***

# Creates private key for specific tenant  
function create_private_key {
    if [ $# -ne 2 ]
        then
                echo "Error in $0 - Invalid Argument Count"
                echo "Syntax: $0 create_private_key <Tenant_name> <keyName>"
        exit
    fi

    TENANT_NAME=$(echo "$1")
	KEY_NAME=$(echo "$2")	
	#TODO Source tenant credentials
	nova --os-tenant-name $TENANT_NAME keypair-add $KEY_NAME > keys/$KEY_NAME."pem"
	chmod 600 keys/$KEY_NAME."pem"	
	check;
    #TODO Move Keys to Safe location at creation time    
}

# Will insert user record into DB
function insert_user_record {
	if [ $# -gt 3 ]
        then
                echo "Error in $0 - Invalid Argument Count"
                echo "Syntax: $0 insert_user_record "username" "password" "role" <Name>"
        exit
    fi
}

# Create security group 
function create_security_group {
	if [ $# -gt 3 ]
        then
                echo "Error in $0 - Invalid Argument Count"
                echo "Syntax: $0 create_security_group <Name>"
        exit
    fi

    TENANT_NAME=$(echo "$1")
    SEC_GROUP_NAME=$(echo "$2")

    if [ $# -eq 2 ]
        then
        nova --os-tenant-name $TENANT_NAME secgroup-create $SEC_GROUP_NAME
        check;
    elif [ $# -eq 3 ]
        then
        DESCRIPTION=$(echo "$3")
        nova --os-tenant-name $TENANT_NAME secgroup-create $SEC_GROUP_NAME "$DESCRIPTION"
        check;    
    else
                echo "Error in $0 - Invalid Argument Count"
                echo "Syntax: $0 create_security_group <Tenant> <Name> <Description>"        
                exit
    fi

    
    echo "Printing " . $SEC_GROUP_NAME . " security rules:"
	nova --os-tenant-name $TENANT_NAME secgroup-list-rules $SEC_GROUP_NAME
}

function add_default_security_group_rules {
	if [ $# -ne 2 ]
        then
                echo "Error in $0 - Invalid Argument Count"
                echo "Syntax: $0 create_security_group <Name>"
        exit
    fi
    TENANT_NAME=$(echo "$1")
    SEC_GROUP_NAME=$(echo "$2")    
    nova --os-tenant-name $TENANT_NAME secgroup-add-rule $SEC_GROUP_NAME tcp 22 22 0.0.0.0/0
    nova --os-tenant-name $TENANT_NAME secgroup-add-rule $SEC_GROUP_NAME tcp 80 80 0.0.0.0/0
    nova --os-tenant-name $TENANT_NAME secgroup-add-rule $SEC_GROUP_NAME tcp 8080 8080 0.0.0.0/0
    nova --os-tenant-name $TENANT_NAME secgroup-add-rule $SEC_GROUP_NAME tcp 443 443 0.0.0.0/0
    nova --os-tenant-name $TENANT_NAME secgroup-add-rule $SEC_GROUP_NAME icmp -1 -1 0.0.0.0/0
}

function get_image_id {
    # Returns image ID, do not validate if IMAGE is loaded or not
    if [ $# -ne 1 ]
        then
                echo "Error in $0 - Invalid Argument Count"
                echo "Syntax: $0 get_image_id <Image name>"
        exit
    fi
    #echo "Displaying Tenant list for customers..."
    IMAGE_ID=`glance --os-image-api-version 2 image-list | grep $1 | get_field 1`
    if [ -n $IMAGE_ID ]
        then
        #Verify is active
        ACTIVE=`glance --os-image-api-version 2 image-list | grep $1 | get_field 6`        
    fi
    echo $IMAGE_ID
    
}

function get_network_id {
    # Returns network ID, do not validate if network is loaded or not
    if [ $# -ne 1 ]
        then
                echo "Error in $0 - Invalid Argument Count"
                echo "Syntax: $0 get_network_id <Network name>"
        exit
    fi
    #echo "Displaying Tenant list for customers..."
    NETWORK_ID=`nova net-list | grep $1 | get_field 1`
    if [ -n $NETWORK_ID ]
        then
        #Verify is active
        echo $NETWORK_ID
    fi
    return
    
}
function display_network_details {
    # Returns image ID, do not validate if IMAGE is loaded or not
    if [ $# -ne 1 ]
        then
                echo "Error in $0 - Invalid Argument Count"
                echo "Syntax: $0 display_network_details <Image name>"
        exit
    fi
    NETWORK_NAME=$(echo "$1")
    nova network-show $NETWORK_NAME

}

function get_flavor {
    # Returns image ID, do not validate if IMAGE is loaded or not
    if [ $# -ne 1 ]
        then
                echo "Error in $0 - Invalid Argument Count"
                echo "Syntax: $0 get_flavor <Image name>"
        exit
    fi
    nova flavor-list | get_field 1
}

function create_virtual_machine {
    
    # Availability zone
    # Instance Name
    # Flavor
    # Instance Count
    # Instance boot source
    #   Image name:  Default: cirros OS
    #   Device size: Default: 20 GB
    #   Device name: Default: vda
    # Access Security
    #   Private key
    #   Security group
    # Networking    
    # Post creation
    # Check status
    if [ $# -ne 6 ]
        then
                echo "Error in $0 - Invalid Argument Count"
                echo "Syntax: $0 create_virtual_machine <flavor> <image> <nic> <security-group> <key-name> <name>"
        exit
    fi
    FLAVOR=$(echo "$1")
    IMAGE_NAME=$(echo "$2")    
    NETWORK_NAME=$(echo "$3") 
    SEC_GROUP_NAME=$(echo "$4") 
    KEY_NAME=$(echo "$5") 
    INSTANCE_NAME=$(echo "$6") 
    nova boot --flavor $FLAVOR --image $IMAGE_NAME --nic $NETWORK_NAME --security-group $SEC_GROUP_NAME --key-name $KEY_NAME $INSTANCE_NAME
    check;

}

# If something went terribly wrong roll back depending where things failed...
function revert_changes {
    if [ $# -ne 1 ]
        then
                echo "Error in $0 - Invalid Argument Count"
                echo "Syntax: $0 revert_changes <option>"
        exit
    fi

}

####################################################################################

read_configuration;
TENANT_NAME="twilio"
USER="admin"
EMAIL="jeff@twilio.com"
create_tenant $TENANT_NAME;

TENANT_ID=`get_tenant_id $TENANT_NAME`;

#create_user $USER $TENANT_ID $EMAIL;
#create_private_key $TENANT_NAME $TENANT_NAME;
#create_security_group $TENANT_NAME $TENANT_NAME "Allow Web traffic default";
#add_default_security_group_rules $TENANT_NAME $TENANT_NAME;
