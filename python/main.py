import json
from utils import zellowork_api

if __name__=="__main__":

	with open('params.json') as file:
		params = json.load(file)

	username = params['USERNAME']
	password = params['PASSWORD']
	network = params['NETWORK']
	api_key = params['API_KEY']

	api = zellowork_api(api_key, network)
	print(api.get_token())
	print(api.login(username, password))