import json
import random
import string
from utils import zellowork_api


def verify_user(user, json_data) -> bool:
    if len(json_data["users"]) != 1:
        return False
    if json_data['users'][0]['name'] != user:
        return False

    return True


if __name__ == "__main__":

    with open('params.json') as file:
        params = json.load(file)

    username = params['USERNAME']
    password = params['PASSWORD']
    network = params['NETWORK']
    api_key = params['API_KEY']

    api = zellowork_api(api_key, network)
    print(api.get_token())
    print(api.login(username, password))

    user_info = api.get_users()

    user_list = ["api_test_user1", "api_test_user2", "api_test_user3"]
    user_pass = res = ''.join(random.choices(string.ascii_uppercase +
                                             string.digits, k=8))
    for user in user_list:
        add_response = api.add_user(user, user_pass)
        print(json.dumps(add_response, indent=1))

    for user in user_list:
        get_response = api.get_user(user)
        print(json.dumps(get_response, indent=1))
        if verify_user(user, get_response):
            print(f'{user} verified as having been added')

    remove_response = api.remove_users(user_list)

    for user in user_list:
        get_response = api.get_user(user)
        print(get_response)

        if get_response["status"] == "User not found":
            print(f'{user} succesfully deleted')
