#!/usr/bin/env python3
import json
import os
import sys
from urllib.parse import urlparse

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", "..", "..", ".."))
sys.path.insert(0, os.path.join(ROOT, "python"))

from utils import zellowork_api  # noqa: E402


def emit(scenario, ok, error=None):
    out = {"lang": "python", "scenario": scenario, "ok": ok}
    if error:
        out["error"] = error
    print(json.dumps(out), flush=True)


def parse_host(host):
    """Map ZW_HOST into (network, base_domain) for zellowork_api."""
    raw = host.strip()
    if "://" not in raw:
        raw = "https://" + raw
    parsed = urlparse(raw)
    hostname = parsed.hostname or ""
    parts = hostname.split(".")
    if len(parts) < 2:
        raise ValueError("ZW_HOST must look like https://network.zellowork.com")
    network = parts[0]
    base_domain = ".".join(parts[1:])
    return network, base_domain


def login_ok(api, username, password):
    token_result = api.get_token()
    if not isinstance(token_result, str) or not token_result.startswith("Authentication successful"):
        return False, token_result
    result = api.login(username, password)
    if result == "Login successful!":
        return True, None
    return False, result if result else "login failed"


def get_users_ok(api):
    data = api.get_users()
    if isinstance(data, dict) and str(data.get("code")) == "200":
        return True, None
    if isinstance(data, dict) and data.get("status") == "OK":
        return True, None
    return False, str(data)


def logout_ok(api):
    r = api.session.request("GET", f"{api.base_url}/user/logout?sid={api.sid}")
    if r.status_code != 200:
        return False, f"logout HTTP {r.status_code}"
    try:
        data = r.json()
    except Exception as e:
        return False, str(e)
    if str(data.get("code")) == "200" or data.get("status") == "OK":
        return True, None
    return False, str(data)


def main():
    host = os.environ.get("ZW_HOST")
    username = os.environ.get("ZW_USERNAME")
    api_key = os.environ.get("ZW_API_KEY")
    password = os.environ.get("ZW_PASSWORD")
    scenario_path = os.environ.get("ZW_SCENARIO")

    if not all([host, username, api_key, password, scenario_path]):
        emit("unknown", False, "missing ZW_HOST, ZW_USERNAME, ZW_API_KEY, ZW_PASSWORD, or ZW_SCENARIO")
        return 1

    with open(scenario_path) as f:
        scenario = json.load(f)

    scenario_id = scenario.get("id", os.path.splitext(os.path.basename(scenario_path))[0])
    expect_success = scenario.get("expect_success", True)

    api = None
    steps_ok = True
    error = None

    try:
        network, base_domain = parse_host(host)
        for step in scenario["steps"]:
            op = step["op"]
            if op == "authenticate":
                key = step.get("api_key", api_key)
                passwd = step.get("password", password)
                legacy = bool(step.get("legacy_auth", False))
                api = zellowork_api(
                    key, network, base_domain=base_domain, use_legacy_auth=legacy
                )
                ok, err = login_ok(api, username, passwd)
                if not ok:
                    steps_ok = False
                    error = err
                    break
            elif op == "get_users":
                if api is None:
                    steps_ok = False
                    error = "no api"
                    break
                ok, err = get_users_ok(api)
                if not ok:
                    steps_ok = False
                    error = err
                    break
            elif op == "logout":
                if api is None:
                    steps_ok = False
                    error = "no api"
                    break
                ok, err = logout_ok(api)
                if not ok:
                    steps_ok = False
                    error = err
                    break
            else:
                steps_ok = False
                error = f"unknown op: {op}"
                break
    except Exception as e:
        steps_ok = False
        error = str(e)

    ok = steps_ok == expect_success
    if not ok and error is None:
        error = "steps failed" if expect_success else "expected failure but steps succeeded"
    emit(scenario_id, ok, None if ok else error)
    return 0 if ok else 1


if __name__ == "__main__":
    sys.exit(main())
