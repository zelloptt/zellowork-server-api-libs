using System;
using System.Collections.Generic;
using System.Text.Json;

namespace System.Web.Script.Serialization
{
	/// <summary>
	/// Minimal smoke-test shim so net8 can compile the Framework-era ZelloAPI.cs.
	/// </summary>
	public class JavaScriptSerializer
	{
		public string Serialize(object obj)
		{
			return JsonSerializer.Serialize(obj);
		}

		public object DeserializeObject(string input)
		{
			using (JsonDocument doc = JsonDocument.Parse(input))
			{
				return ConvertElement(doc.RootElement);
			}
		}

		static object ConvertElement(JsonElement el)
		{
			switch (el.ValueKind)
			{
				case JsonValueKind.Object:
					var dict = new Dictionary<string, object>();
					foreach (JsonProperty prop in el.EnumerateObject())
					{
						dict[prop.Name] = ConvertElement(prop.Value);
					}
					return dict;
				case JsonValueKind.Array:
					var list = new List<object>();
					foreach (JsonElement item in el.EnumerateArray())
					{
						list.Add(ConvertElement(item));
					}
					return list;
				case JsonValueKind.String:
					return el.GetString();
				case JsonValueKind.Number:
					if (el.TryGetInt64(out long l))
					{
						return l;
					}
					return el.GetDouble();
				case JsonValueKind.True:
					return true;
				case JsonValueKind.False:
					return false;
				default:
					return null;
			}
		}
	}
}
