using System;
using System.IO;
using System.Text.Json;
using System.Threading.Tasks;
using Zello.API;

class Program
{
	static void Emit(string scenario, bool ok, string error)
	{
		using (var stream = new MemoryStream())
		{
			using (var writer = new Utf8JsonWriter(stream))
			{
				writer.WriteStartObject();
				writer.WriteString("lang", "csharp");
				writer.WriteString("scenario", scenario);
				writer.WriteBoolean("ok", ok);
				if (!string.IsNullOrEmpty(error))
				{
					writer.WriteString("error", error);
				}
				writer.WriteEndObject();
			}
			Console.WriteLine(System.Text.Encoding.UTF8.GetString(stream.ToArray()));
		}
	}

	static async Task<int> Main()
	{
		string host = Environment.GetEnvironmentVariable("ZW_HOST");
		string username = Environment.GetEnvironmentVariable("ZW_USERNAME");
		string apiKey = Environment.GetEnvironmentVariable("ZW_API_KEY");
		string password = Environment.GetEnvironmentVariable("ZW_PASSWORD");
		string scenarioPath = Environment.GetEnvironmentVariable("ZW_SCENARIO");

		if (string.IsNullOrEmpty(host) || string.IsNullOrEmpty(username) ||
		    string.IsNullOrEmpty(apiKey) || string.IsNullOrEmpty(password) ||
		    string.IsNullOrEmpty(scenarioPath))
		{
			Emit("unknown", false, "missing ZW_HOST, ZW_USERNAME, ZW_API_KEY, ZW_PASSWORD, or ZW_SCENARIO");
			return 1;
		}

		string raw = File.ReadAllText(scenarioPath);
		using (JsonDocument doc = JsonDocument.Parse(raw))
		{
			JsonElement root = doc.RootElement;
			string scenarioId = root.TryGetProperty("id", out JsonElement idEl)
				? idEl.GetString()
				: Path.GetFileNameWithoutExtension(scenarioPath);
			bool expectSuccess = !root.TryGetProperty("expect_success", out JsonElement expectEl) || expectEl.GetBoolean();

			ZelloAPI api = null;
			bool stepsOk = true;
			string error = null;

			try
			{
				foreach (JsonElement step in root.GetProperty("steps").EnumerateArray())
				{
					string op = step.GetProperty("op").GetString();
					if (op == "authenticate")
					{
						string key = step.TryGetProperty("api_key", out JsonElement keyEl) ? keyEl.GetString() : apiKey;
						string pass = step.TryGetProperty("password", out JsonElement passEl) ? passEl.GetString() : password;
						bool legacy = step.TryGetProperty("legacy_auth", out JsonElement legacyEl) && legacyEl.GetBoolean();
						api = new ZelloAPI(host, key);
						api.UseLegacyAuth = legacy;
						ZelloAPIResult result = await api.Authenticate(username, pass).ConfigureAwait(false);
						if (!result.Success)
						{
							stepsOk = false;
							error = result.Exception != null ? result.Exception.Message : "authenticate failed";
							if (result.Response != null && result.Response.ContainsKey("status"))
							{
								error = Convert.ToString(result.Response["status"]);
							}
							break;
						}
					}
					else if (op == "get_users")
					{
						if (api == null)
						{
							stepsOk = false;
							error = "no api";
							break;
						}
						ZelloAPIResult result = await api.GetUsers(null, false, null, null, null).ConfigureAwait(false);
						if (!result.Success)
						{
							stepsOk = false;
							error = result.Exception != null ? result.Exception.Message : "get_users failed";
							break;
						}
					}
					else if (op == "logout")
					{
						if (api == null)
						{
							stepsOk = false;
							error = "no api";
							break;
						}
						ZelloAPIResult result = await api.Logout().ConfigureAwait(false);
						if (!result.Success)
						{
							stepsOk = false;
							error = result.Exception != null ? result.Exception.Message : "logout failed";
							break;
						}
					}
					else
					{
						stepsOk = false;
						error = "unknown op: " + op;
						break;
					}
				}
			}
			catch (Exception ex)
			{
				stepsOk = false;
				error = ex.Message;
			}

			bool ok = stepsOk == expectSuccess;
			if (!ok && error == null)
			{
				error = expectSuccess ? "steps failed" : "expected failure but steps succeeded";
			}
			Emit(scenarioId, ok, ok ? null : error);
			return ok ? 0 : 1;
		}
	}
}
