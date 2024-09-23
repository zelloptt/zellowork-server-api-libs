import requests
from hashlib import md5
from urllib.parse import quote


class zellowork_api():

    '''
    Function class for python zellowork api
    '''

    def __init__(self, api_key, network, base_domain="zellowork.com", verifyTls=True):

        self.network = network
        self.base_url = f'https://{self.network}.{base_domain}'
        self.api_key = api_key
        self.session = requests.Session()
        self.session.verify = verifyTls

    def get_token(self):
        '''
        Function to get auth token and session id
        '''
        r = self.session.request(
            'GET', f'{self.base_url}/user/gettoken', headers={}, data={})
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

        r = self.session.request(
            'POST', f'{self.base_url}/user/login?sid={self.sid}', headers={}, data=payload)
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

        r = self.session.request(
            'POST', f'{self.base_url}/analytics/dispatch-metrics?sid={self.sid}', headers={}, data=payload)

        if r.status_code == 200:
            data = r.json()
            if data['code'] == '200':
                print('Successful analytics data pull.')
                return data
        else:
            return f'{r.status_code} status code'

    def get_users(self):
        '''
        Function to get the users of the network
        '''
        r = self.session.request(
            'GET', f'{self.base_url}/user/get?sid={self.sid}', headers={}, data={},)
        if r.status_code == 200:
            print("All users fetched")
            return r.json()
        else:
            f'User fetch fail. {r}'

    def get_user(self, user: str):
        '''
        Function to get a specified user
        '''
        r = self.session.request(
            'GET', f'{self.base_url}/user/get/login/{user}?sid={self.sid}', headers={}, data={}
        )
        if r.status_code == 200:
            print(f"User {user} fetched")
            return r.json()
        else:
            f'User fetch fail. {r}'

    def get_user_limit(self):
        '''
        Gets the user limit for the network
        '''
        r = self.session.request(
            'GET', f'{self.base_url}/user/get/max/1?sid={self.sid}', headers={}, data={})
        print(r.json())

    def add_user(self, name: str,
                 password: str,
                 email: str = "",
                 full_name: str = "",
                 job: str = "",
                 admin: bool = False,
                 limited: bool = False,
                 gateway: bool = False,
                 tags: list = None,
                 add: bool = False):

        if tags is None:
            tags = []

        user_data = {
            "name": name,
            "password": md5(password.encode('utf-8')).hexdigest()
        }
        if email:
            user_data["email"] = email
        if full_name:
            user_data["full_name"] = full_name
        if job:
            user_data["job"] = job
        if admin:
            user_data["admin"] = admin
        if limited:
            user_data["limited"] = limited
        if gateway:
            user_data["gateway"] = gateway
        if tags:
            user_data["tags"] = tags
        if add:
            user_data["add"] = add

        r = self.session.request(
            'POST', f'{self.base_url}/user/save?sid={self.sid}', headers={}, data=user_data)

        if r.status_code == 200:
            data = r.json()
            if data['code'] == '200':
                print('Succesfully added user')
                return data
        else:
            return f'{r.status_code} status code'

    def array_to_POST(self, user_array: []):
        result_string = "login[]=" + user_array[0]
        for user in user_array[1:len(user_array)]:
            result_string += "&login[]=" + quote(user)
        return result_string

    def pretty_print_POST(self, req):
        print('{}\n{}\r\n{}\r\n\r\n{}'.format(
            '-----------START-----------',
            req.method + ' ' + req.url,
            '\r\n'.join('{}: {}'.format(k, v) for k, v in req.headers.items()),
            req.body,
        ))

    def remove_users(self, user_array: []):
        user_string = self.array_to_POST(user_array)
        print(user_string)
        request = requests.Request(
            'POST', f'{self.base_url}/user/delete?sid={self.sid}', headers={"Content-Type": "application/x-www-form-urlencoded"}, data=user_string)
        prepared = request.prepare()
        self.pretty_print_POST(prepared)
        response = self.session.send(prepared)
        if response.status_code == 200:
            print('Succesfully removed users')
        else:
            print('Error removing users')

        return response
