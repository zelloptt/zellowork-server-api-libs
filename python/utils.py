import requests
from hashlib import md5

class zellowork_api():
	
	'''
	Function class for python zellowork api
	'''

	def __init__(self, api_key, network):

		self.network = network
		self.base_url = f'https://{self.network}.zellowork.com'
		self.api_key = api_key


	def get_token(self):
		
		'''
		Function to get auth token and session id
		'''

		r = requests.request('GET', f'{self.base_url}/user/gettoken', headers={}, data={})
		response = r.json()
		if r.status_code == 200:
			self.token = response['token']
			self.sid = response['sid']
			return 'Authentication successful!'
		else:
			return f'Authentication not successful. {r}'

	def login(self, username, password):

		'''
		Function to login user to console

		Requires username and password
		'''

		payload = {
			'username': username,
			'password': md5((md5(password.encode('utf-8')).hexdigest() + self.token + self.api_key).encode('utf-8')).hexdigest()
		}

		r = requests.request('POST', f'{self.base_url}/user/login?sid={self.sid}', headers={}, data=payload)

		if r.status_code == 200:
			data = r.json()
			if data['code'] == '200':
				return 'Login successful!'
		else:
			return f'Login not successful. {r}'

	def get_analytics(self, start_time=1660712400, end_time=1660798799):

		'''
		Function to get analytics json based
		on start and end time
		'''

		payload = {
			'startTs': start_time,
			'endTs': end_time,
			'utcOffsetMinutes': 300,
			'context': 1
		}

		r = requests.request('POST', f'{base_url}/analytics/dispatch-metrics?sid={self.sid}', headers={}, data=payload)

		if r.status_code == 200:
			data = r.json()
			if data['code'] == '200':
				print('Successful analytics data pull.')
				return data
		else:
			return f'{r.status_code} status code'  