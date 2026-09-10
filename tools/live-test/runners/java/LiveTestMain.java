import com.zellowork.apiwrapper.ResultCompletionHandler;
import com.zellowork.apiwrapper.ZelloAPI;
import org.json.JSONArray;
import org.json.JSONObject;

import java.nio.charset.StandardCharsets;
import java.nio.file.Files;
import java.nio.file.Paths;
import java.util.concurrent.CountDownLatch;
import java.util.concurrent.atomic.AtomicBoolean;
import java.util.concurrent.atomic.AtomicReference;

public class LiveTestMain {
	static void emit(String scenario, boolean ok, String error) {
		JSONObject out = new JSONObject();
		out.put("lang", "java");
		out.put("scenario", scenario);
		out.put("ok", ok);
		if (error != null && !error.isEmpty()) {
			out.put("error", error);
		}
		System.out.println(out.toString());
	}

	static boolean await(ZelloAPI api, ThrowingCall call) throws Exception {
		CountDownLatch latch = new CountDownLatch(1);
		AtomicBoolean ok = new AtomicBoolean(false);
		AtomicReference<String> err = new AtomicReference<String>(null);
		call.run(new ResultCompletionHandler() {
			@Override
			public void onResult(boolean success, JSONObject response, Exception exception) {
				ok.set(success);
				if (!success) {
					if (exception != null) {
						err.set(exception.getMessage());
					} else if (response != null) {
						err.set(response.toString());
					} else {
						err.set("request failed");
					}
				}
				latch.countDown();
			}
		});
		latch.await();
		if (!ok.get() && err.get() != null) {
			throw new StepFailedException(err.get());
		}
		return ok.get();
	}

	interface ThrowingCall {
		void run(ResultCompletionHandler handler) throws Exception;
	}

	static class StepFailedException extends Exception {
		StepFailedException(String message) {
			super(message);
		}
	}

	public static void main(String[] args) throws Exception {
		String host = System.getenv("ZW_HOST");
		String username = System.getenv("ZW_USERNAME");
		String apiKey = System.getenv("ZW_API_KEY");
		String password = System.getenv("ZW_PASSWORD");
		String scenarioPath = System.getenv("ZW_SCENARIO");

		if (host == null || username == null || apiKey == null || password == null || scenarioPath == null) {
			emit("unknown", false, "missing ZW_HOST, ZW_USERNAME, ZW_API_KEY, ZW_PASSWORD, or ZW_SCENARIO");
			System.exit(1);
		}

		String raw = new String(Files.readAllBytes(Paths.get(scenarioPath)), StandardCharsets.UTF_8);
		JSONObject scenario = new JSONObject(raw);
		String scenarioId = scenario.optString("id", Paths.get(scenarioPath).getFileName().toString().replace(".json", ""));
		boolean expectSuccess = !scenario.has("expect_success") || scenario.getBoolean("expect_success");
		JSONArray steps = scenario.getJSONArray("steps");

		ZelloAPI api = null;
		boolean stepsOk = true;
		String error = null;

		try {
			for (int i = 0; i < steps.length(); i++) {
				JSONObject step = steps.getJSONObject(i);
				String op = step.getString("op");
				if ("authenticate".equals(op)) {
					String key = step.has("api_key") ? step.getString("api_key") : apiKey;
					String pass = step.has("password") ? step.getString("password") : password;
					api = new ZelloAPI(host, key);
					api.useLegacyAuth = step.optBoolean("legacy_auth", false);
					final ZelloAPI authApi = api;
					final String authUser = username;
					final String authPass = pass;
					try {
						await(api, new ThrowingCall() {
							@Override
							public void run(ResultCompletionHandler handler) {
								authApi.authenticate(authUser, authPass, handler);
							}
						});
					} catch (StepFailedException e) {
						stepsOk = false;
						error = e.getMessage();
						break;
					}
				} else if ("get_users".equals(op)) {
					if (api == null) {
						stepsOk = false;
						error = "no api";
						break;
					}
					final ZelloAPI usersApi = api;
					try {
						await(api, new ThrowingCall() {
							@Override
							public void run(ResultCompletionHandler handler) {
								usersApi.getUsers(null, null, null, null, null, handler);
							}
						});
					} catch (StepFailedException e) {
						stepsOk = false;
						error = e.getMessage();
						break;
					}
				} else if ("logout".equals(op)) {
					if (api == null) {
						stepsOk = false;
						error = "no api";
						break;
					}
					final ZelloAPI logoutApi = api;
					try {
						await(api, new ThrowingCall() {
							@Override
							public void run(ResultCompletionHandler handler) {
								logoutApi.logout(handler);
							}
						});
					} catch (StepFailedException e) {
						stepsOk = false;
						error = e.getMessage();
						break;
					}
				} else {
					stepsOk = false;
					error = "unknown op: " + op;
					break;
				}
			}
		} catch (Exception e) {
			stepsOk = false;
			error = e.getMessage();
		}

		boolean ok = stepsOk == expectSuccess;
		if (!ok && error == null) {
			error = expectSuccess ? "steps failed" : "expected failure but steps succeeded";
		}
		emit(scenarioId, ok, ok ? null : error);
		System.exit(ok ? 0 : 1);
	}
}
