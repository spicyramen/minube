# minube
This application allows to create Virtual machines using REST API using Python or shell scripts
Use it as reference to create or automate Virtual machine creation

## Instructions

### Twilio and Openstack demo
This application allows to create Virtual machines via SMS

Replace Controller IP Address| get_token credentials|Image name,key information
```
controller = '162.243.123.57'
```

Replace your Openstack authentication information
```
data = {"auth":{"tenantName": tenant,
				 	"passwordCredentials": { "username": "admin","password": "M1Nub3"} 
					}
			}
```
Replace your Openstack image information
```
launch_instance function
```

### Twilio
Replace Twilio Key and Twilio URL in Twilio Dashboard|From Phone