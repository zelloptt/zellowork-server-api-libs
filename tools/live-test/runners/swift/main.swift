import Foundation

func emit(scenario: String, ok: Bool, error: String?) {
  var obj: [String: Any] = [
    "lang": "swift",
    "scenario": scenario,
    "ok": ok
  ]
  if let error = error, !error.isEmpty {
    obj["error"] = error
  }
  if let data = try? JSONSerialization.data(withJSONObject: obj, options: []),
     let line = String(data: data, encoding: .utf8) {
    print(line)
  }
}

func waitFor(_ block: (@escaping () -> Void) -> Void) {
  var finished = false
  block {
    finished = true
    CFRunLoopStop(CFRunLoopGetMain())
  }
  let deadline = Date().addingTimeInterval(60)
  while !finished && Date() < deadline {
    RunLoop.current.run(mode: .default, before: Date().addingTimeInterval(0.05))
  }
}

func env(_ key: String) -> String? {
  let v = ProcessInfo.processInfo.environment[key]
  if v == nil || v!.isEmpty { return nil }
  return v
}

guard let host = env("ZW_HOST"),
      let username = env("ZW_USERNAME"),
      let apiKeyEnv = env("ZW_API_KEY"),
      let passwordEnv = env("ZW_PASSWORD"),
      let scenarioPath = env("ZW_SCENARIO") else {
  emit(scenario: "unknown", ok: false, error: "missing ZW_HOST, ZW_USERNAME, ZW_API_KEY, ZW_PASSWORD, or ZW_SCENARIO")
  exit(1)
}

guard let data = try? Data(contentsOf: URL(fileURLWithPath: scenarioPath)),
      let scenario = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
      let steps = scenario["steps"] as? [[String: Any]] else {
  emit(scenario: "unknown", ok: false, error: "failed to parse scenario JSON")
  exit(1)
}

let scenarioId = (scenario["id"] as? String) ?? URL(fileURLWithPath: scenarioPath).deletingPathExtension().lastPathComponent
let expectSuccess = (scenario["expect_success"] as? Bool) ?? true

var api: ZelloAPI?
var stepsOk = true
var error: String?

for step in steps {
  guard let op = step["op"] as? String else {
    stepsOk = false
    error = "missing op"
    break
  }

  if op == "authenticate" {
    let key = (step["api_key"] as? String) ?? apiKeyEnv
    let pass = (step["password"] as? String) ?? passwordEnv
    let legacy = (step["legacy_auth"] as? Bool) ?? false
    let client = ZelloAPI(host: host, apiKey: key)
    client.useLegacyAuth = legacy
    api = client

    var authOk = false
    var authErr: String?
    waitFor { done in
      client.authenticate(username, password: pass) { success, response, err in
        authOk = success
        if !success {
          if let err = err {
            authErr = err.localizedDescription
          } else if let response = response {
            authErr = String(describing: response)
          } else {
            authErr = "authenticate failed"
          }
        }
        done()
      }
    }
    if !authOk {
      stepsOk = false
      error = authErr
      break
    }
  } else if op == "get_users" {
    guard let client = api else {
      stepsOk = false
      error = "no api"
      break
    }
    var callOk = false
    var callErr: String?
    waitFor { done in
      client.getUsers(completionHandler: { success, response, err in
        callOk = success
        if !success {
          callErr = err?.localizedDescription ?? String(describing: response)
        }
        done()
      })
    }
    if !callOk {
      stepsOk = false
      error = callErr
      break
    }
  } else if op == "logout" {
    guard let client = api else {
      stepsOk = false
      error = "no api"
      break
    }
    var callOk = false
    var callErr: String?
    waitFor { done in
      client.logout { success, response, err in
        callOk = success
        if !success {
          callErr = err?.localizedDescription ?? String(describing: response)
        }
        done()
      }
    }
    if !callOk {
      stepsOk = false
      error = callErr
      break
    }
  } else {
    stepsOk = false
    error = "unknown op: \(op)"
    break
  }
}

let ok = stepsOk == expectSuccess
if !ok && error == nil {
  error = expectSuccess ? "steps failed" : "expected failure but steps succeeded"
}
emit(scenario: scenarioId, ok: ok, error: ok ? nil : error)
exit(ok ? 0 : 1)
