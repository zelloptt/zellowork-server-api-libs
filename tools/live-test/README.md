# Live-test suite (Mac)

Exercises each Management API client library against a real network: new `/user/auth`, legacy `user/login`, a post-auth `getUsers` call, and expected auth failures.

## Requirements

- Mac with Docker Desktop (for PHP, Java, C#)
- `python3` for the Python runner (`run.sh` creates `tools/live-test/.venv` and installs `requests` on first use)
- Xcode command-line tools (`swiftc`, `clang`) for Swift and Objective-C

## Credentials

| Input | Source |
|-------|--------|
| Host | `--host` |
| Username | `--username` |
| API key | `ZW_API_KEY` env |
| Password | `ZW_PASSWORD` env |

## Run

```bash
export ZW_API_KEY='...'
export ZW_PASSWORD='...'

./tools/live-test/run.sh \
  --host 'https://your-network.zellowork.com' \
  --username 'admin'
```

Optional filters:

```bash
./tools/live-test/run.sh \
  --host 'https://your-network.zellowork.com' \
  --username 'admin' \
  --langs php,python \
  --scenarios auth-new,auth-bad-password
```

## Scenarios

| id | What it checks |
|----|----------------|
| `auth-new` | Default `/user/auth` + logout |
| `auth-legacy` | MD5 `user/login` + logout. May fail on cloud networks that no longer accept legacy login. |
| `session-get-users` | New auth, then `getUsers` with the session id |
| `auth-bad-password` | Wrong password must fail (`expect_success: false`) |
| `auth-bad-api-key` | Wrong API key must fail on the new auth path |

Each runner prints one JSON line: `{"lang","scenario","ok","error?"}` and exits non-zero when the outcome does not match `expect_success`.

## Layout

- Docker: `runners/php`, `runners/java`, `runners/csharp` (compose services)
- Host: `runners/python`, `runners/swift`, `runners/objc`
- Canonical library sources under `php/`, `python/`, `java/`, `csharp/`, `swift/`, `objective-c/` are mounted or compiled as-is

## Adding a scenario

Drop a JSON file in `scenarios/` with `id`, optional `expect_success`, and `steps` (`authenticate`, `get_users`, `logout`). Authenticate steps may set `legacy_auth`, `password`, or `api_key` overrides.
