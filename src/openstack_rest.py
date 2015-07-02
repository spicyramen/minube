#
# Gonzalo Gasca Meza 2015
# Twilio and Openstack demo
# This application allows to create Virtual machines via SMS
# Replace Twilio Key and Twilio URL in Twilio Dashboard|From Phone
# Replace Controller IP Address| get_token credentials|Image name,key information

from flask import Flask, request, redirect
import twilio.twiml
import requests,json

callers = {
    "+14082186575": "Gonzalo Gasca Meza",
}
controller = '162.243.123.57'
token_id = ''
tenant_id = ''
siplb_instance = 1
ccp_instance = 1
mds_instance = 1

app = Flask(__name__)

@app.route("/", methods=['GET', 'POST'])
def ack_message():
    #Respond to incoming calls with a simple text message.
    from_number = request.values.get('From', None)
    body = request.values.get('Body',None)

    # Remove white spaces   
    body = body.strip()
    print body
    resp = twilio.twiml.Response()
    # Process_sms body
    if process_sms_body(body):
    	resp.message('The server has been created succesfully')
    else:
    	resp.message('Request failed')
    
    return str(resp)
    
# Openstack operations
def get_token(tenant):

	data = {"auth":{"tenantName": tenant,
				 	"passwordCredentials": { "username": "admin","password": "M1Nub3"} 
					}
			}

	headers = {'Content-type': 'application/json', 'Accept': 'text/plain'}
	token = ''
	global tenant_id
	url = 'http://' + controller + ':5000/v2.0/tokens'
	import requests
	import json

	# Send POST
	response = requests.post(url,data=json.dumps(data),headers=headers)
	# Verify we get 200
	print response.status_code
	# If all is good
	if response.status_code==200:
		# Process JSON data into a dictionary		
		json_data = json.loads(response.text)
		# Get token information
		#print json_data
		try:
			token = json_data['access']['token']['id']
			tenant_id = json_data['access']['token']['tenant']['id']
		except Exception,e:
			print 'Invalid key'
			return
	else:
		# Send a message system Openstack is down
		return
	return token

def get_flavors(token='',tenant='',identifier='',**kwargs):
	flavors = ''
	print token,tenant,identifier
	if token:
		headers = {'Content-type': 'application/json', 'Accept': 'text/plain','X-Auth-Token': token}
		if identifier:
			url = 'http://' + controller + ':8774/v2/' + tenant +'/flavors/' + str(identifier)
		else:
			url = 'http://' + controller + ':8774/v2/' + tenant +'/flavors'
	else:
		return

	# Send GET
	response = requests.get(url,headers=headers)
	print response.status_code
	# If all is good
	if response.status_code==200:
		# Process JSON data into a dictionary		
		json_data = json.loads(response.text)
		# Get flavor information
		flavors = json_data
	else:
		# Send a message system Openstack is down
		return
	return flavors

def process_flavors(flavors,id):
	try:
		# Read dictionary and then obtain id
		if len(flavors['flavors'])>0:
			for flavor in flavors['flavors']:
				if flavor['name'] == id:
					print flavor['id'],flavor['name']
					return flavor['id']
		else:
			print 'No flavors'
			return
	# We handle no flavors key or no elements
	except Exception,e:
		return

def get_images(token='',tenant='',identifier='',**kwargs):
	images = ''
	print token,tenant,identifier
	if token:
		headers = {'Content-type': 'application/json', 'Accept': 'text/plain','X-Auth-Token': token}
		if identifier:
			url = 'http://' + controller + ':8774/v2/' + tenant +'/images/' + str(identifier)
		else:
			url = 'http://' + controller + ':8774/v2/' + tenant +'/images'
	else:
		return

	# Send GET
	response = requests.get(url,headers=headers)
	print response.status_code
	# If all is good
	if response.status_code==200:
		# Process JSON data into a dictionary		
		json_data = json.loads(response.text)
		# Get images information
		images = json_data
	else:
		# Send a message system Openstack is down
		return
	return images

def process_images(images,id):
	try:
		# Read dictionary and then obtain id
		if len(images['images'])>0:
			for image in images['images']:
				if image['name'] == id:
					print image['id'],image['name']
					return image['id']
		else:
			print 'No images'
			return
	# We handle no flavors key or no elements
	except Exception,e:
		print 'Invalid key'
		return


def get_networks(token):
	#http://162.243.123.57:9696/v2.0/networks
	images = ''
	print token
	if token:
		headers = {'Content-type': 'application/json', 'Accept': 'text/plain','X-Auth-Token': token}
		url = 'http://' + controller + ':9696/v2.0/networks'
	else:
		return

	# Send GET
	response = requests.get(url,headers=headers)
	print response.status_code
	# If all is good
	if response.status_code==200:
		# Process JSON data into a dictionary		
		json_data = json.loads(response.text)
		# Get networks information
		networks = json_data
	else:
		# Send a message system Openstack is down
		return
	return networks

def process_networks(networks,id):
	try:
		# Read dictionary and then obtain id
		if len(networks['networks']) > 0:
			for network in networks['networks']:
				if network['name'] == id:
					print network['id'],network['name']
					return network['id']
		else:
			print 'No networks'
			return
	# We handle no networks key or no elements
	except Exception,e:
		print 'Invalid key'
		return

def get_security_groups(token='',tenant='',identifier='',**kwargs):
	#http://162.243.123.57:8774/v2/356d150b03174f3fa4e7fb2c6a423cf2/os-security-groups
	security_groups = ''
	print token,tenant
	if token:
		headers = {'Content-type': 'application/json', 'Accept': 'text/plain','X-Auth-Token': token}
		if identifier:
			url = 'http://' + controller + ':8774/v2/' + tenant +'/os-security-groups/' + str(identifier)
		else:
			url = 'http://' + controller + ':8774/v2/' + tenant +'/os-security-groups'
	else:
		return

	# Send GET
	response = requests.get(url,headers=headers)
	print response.status_code
	# If all is good
	if response.status_code == 200:
		# Process JSON data into a dictionary		
		json_data = json.loads(response.text)
		# Get security_group information
		security_groups = json_data
	else:
		# Send a message system Openstack is down
		return
	return security_groups

def process_security_groups(security_groups,id):
	try:
		# Read dictionary and then obtain id
		if len(security_groups['security_groups']) > 0:
			for security_group in security_groups['security_groups']:
				if security_group['name'] == id:
					print security_group['id'],security_group['name']
					return security_group['id']
		else:
			print 'No security_groups'
			return
	# We handle no security_groups key or no elements
	except Exception,e:
		print 'Invalid key'
		return


def get_keypairs(token='',tenant='',identifier='',**kwargs):
	#http://162.243.123.57:8774/v2/356d150b03174f3fa4e7fb2c6a423cf2/os-keypairs
	key_pairs = ''
	print token,tenant,identifier
	if token:
		headers = {'Content-type': 'application/json', 'Accept': 'text/plain','X-Auth-Token': token}
		if identifier:
			url = 'http://' + controller + ':8774/v2/' + tenant +'/os-keypairs/' + str(identifier)
		else:
			url = 'http://' + controller + ':8774/v2/' + tenant +'/os-keypairs'
	else:
		return

	# Send GET
	response = requests.get(url,headers=headers)
	print response.status_code
	# If all is good
	if response.status_code == 200:
		# Process JSON data into a dictionary		
		json_data = json.loads(response.text)
		# Get key_pairs information
		key_pairs = json_data
	else:
		# Send a message system Openstack is down
		return
	return key_pairs

def process_keypairs(keypairs,name):
	try:
		# Read dictionary and then obtain id
		if len(keypairs['keypairs']) > 0:
			for keypair in keypairs['keypairs']:
				print keypair['keypair']['name'],keypair['keypair']['fingerprint']				
		else:
			print 'No keypairs'
			return
	# We handle no security_groups key or no elements
	except Exception,e:
		print 'Invalid key'
		return

def create_vm(token,tenant,name,image_ref,flavor_ref,security_group,keypair_name,max,min):
	#http://162.243.123.57:8774/v2/356d150b03174f3fa4e7fb2c6a423cf2/servers
	#{"server": {"name": "siplb1", "imageRef": "a68c5903-a544-479d-b3e8-2528db51bf93", "security_group": "1bada70e-85a6-47ff-8f5f-24437fc745c2","key_name": "siplb", "flavorRef": "1", "max_count": 1, "min_count": 1}}'

	data = {"server":{"name": name,
				 	  "imageRef": image_ref,
				 	  "security_group": security_group,
				 	  "key_name":keypair_name,
				 	  "flavorRef": flavor_ref,
				 	  "max_count": 1, 
				 	  "min_count": 1
					}
			}

	headers = {'Content-type': 'application/json', 'Accept': 'text/plain','X-Auth-Token': token}
	url = 'http://' + controller + ':8774/v2/' + tenant + '/servers'
	import requests
	import json

	# Send POST
	print json.dumps(data)
	response = requests.post(url,data=json.dumps(data),headers=headers)
	# Verify we get 200
	print response.status_code
	# If all is good
	if response.status_code == 200:
		# Process JSON data into a dictionary		
		json_data = json.loads(response.text)
		# Get token information
		#print json_data
		try:
			print json_data
		except Exception,e:
			print 'Invalid key'
			return
	else:
		# Send a message system Openstack is down
		return	

"""
Twilio information
"""
def send_sms(destination,message):
	from twilio.rest import TwilioRestClient
	account_sid = "XXXXXX"
	auth_token  = "YYYYYY"
	client = TwilioRestClient(account_sid, auth_token)	
 	if message:
		sms = client.sms.messages.create(body=message,
    	to=destination,
	    from_="+14088053951")
		print sms.sid
	else:
		print 'Message is empty'

def process_sms_body(code):
	global siplb_instance,ccp_instance,mds_instance

	if code=='1':		
		siplb_instance +=1
		launch_instance(1,'siplb' + str(siplb_instance))
	elif code=='2':
		#create ccp
		ccp_instance +=1
		launch_instance(2,'ccp' + str(ccp_instance))
	elif code=='3':
		mds_instance +=1
		launch_instance(3,'mds' + str(mds_instance))
	else:
		print 'process_sms() Invalid code' + str(code)
		return False

	return True		


def launch_instance(id,name):
	if id == 1:
		key_pair = 'siplb'
	if id == 2:
		key_pair = 'ccp'
	if id == 3:
		key_pair = 'mds'

	# Get TokenId
	token_id = get_token('twilio')

	# Get Flavors
	flavors = get_flavors(token=token_id,tenant=tenant_id)
	flavor_id = process_flavors(flavors,'m1.tiny')

	# Get Images
	images = get_images(token=token_id,tenant=tenant_id)
	image_id = process_images(images,'cirros-0.3.2-x86_64-uec')

	# Get Networks
	networks = get_networks(token_id)
	network_id = process_networks(networks,'')

	# Get Security groups
	security_groups = get_security_groups(token=token_id,tenant=tenant_id)
	security_group_id = process_security_groups(security_groups,key_pair)

	# Get Key pairs
	keypairs = get_keypairs(token=token_id,tenant=tenant_id)
	process_keypairs(keypairs,'')
	# Create VM
	#create_vm(token,tenant,name,image_ref,flavor_ref,security_group,keypair_name,max,min):
	create_vm(token_id,tenant_id,name,image_id,flavor_id,security_group_id,key_pair,1,1)

if __name__ == "__main__":
    app.run(host='0.0.0.0', port=7070,debug=True)