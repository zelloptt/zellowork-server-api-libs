//
//  Copyright © 2016 Zello. All rights reserved.
//

package com.zellowork.apiwrapper;

import org.json.JSONObject;

import java.io.BufferedWriter;
import java.io.IOException;
import java.io.InputStream;
import java.io.InputStreamReader;
import java.io.OutputStream;
import java.io.OutputStreamWriter;
import java.io.Reader;
import java.io.UnsupportedEncodingException;
import java.math.BigInteger;
import java.net.HttpURLConnection;
import java.net.URL;
import java.net.URLEncoder;
import java.security.MessageDigest;
import java.util.ArrayList;
import java.util.Map;

/**
 Zello for Work server Java API wrapper class.

 The class provides an easy way to interact with Zello for Work server
 from your Java code to add, modify and delete users and channels.
 Please note that all text values passed to the API must be in UTF-8 encoding
 and any text data returned are in UTF-8 as well.

 - Version 1.0.0
 */
public class ZelloAPI {

	private enum HTTPMethod {
		POST, GET
	}

	/// API Version
	public static String version = "1.0.0";

	/// Session ID used to identify logged in client. Typically you'll want to authenticate first and store the Session ID to reuse later.
	public String sessionId;

	/// Last accessed API URL. Useful for API troubleshooting.
	public String lastURL;

	/// Server hostname or IP address.
	private String host;
	/// API Key.
	private String apiKey;

	public ZelloAPI(String host, String apiKey) {
		this(host, apiKey, null);
	}

	public ZelloAPI(String host, String apiKey, String sessionId) {
		this.host = host;
		this.apiKey = apiKey;
		this.sessionId = sessionId;
	}

	/**
	 API client authentication.
	 If authentication fails, use the errorCode and errorDescription attributes on the response dictionary to get error details.
	 If authentication succeeds, sessionId is set to the Session ID.
	 The Session ID is reusable so it's recommended that you save this value and use it for further API calls.
	 Once you are done using the API, call ZelloAPI.logout() to end the session and invalidate Session ID.

	 - parameter username:          administrative username
	 - parameter password:          administrative password
	 - parameter completionHandler: completion handler indicating success, response and error.
	 */
	public void authenticate(final String username, final String password, final ResultCompletionHandler completionHandler) {
		callAPI("user/gettoken", HTTPMethod.GET, null, new ResultCompletionHandler() {
			@Override
			public void onResult(boolean success, JSONObject response, Exception exception) {
				// On main thread.
				if (!success) {
					completionHandler.onResult(false, response, exception);
					return;
				}

				if (response == null) {
					completionHandler.onResult(false, null, exception);
					return;
				}

				try {
					String token = response.getString("token");

					sessionId = response.getString("sid");

					if (apiKey == null) {
						completionHandler.onResult(false, response, exception);
						return;
					}

					String hashedPassword = MD5(MD5(password) + token + apiKey);
					String parameters = "username=" + username + "&password=" + hashedPassword;

					callAPI("user/login", HTTPMethod.POST, parameters, completionHandler);
				} catch (Exception e) {
					completionHandler.onResult(false, response, e);
				}
			}
		});
	}

	/**
	 Ends session identified by sessionId.
	 Use this method to terminate the API session.
	 See ZelloAPI.authenticate()

	 - parameter completionHandler: completion handler indicating success, response and error.
	 */
	public void logout(final ResultCompletionHandler completionHandler) {
		callAPI("user/logout", HTTPMethod.GET, null, new ResultCompletionHandler() {
			@Override
			public void onResult(boolean success, JSONObject response, Exception exception) {
				sessionId = null;

				completionHandler.onResult(success, response, exception);
			}
		});
	}

	/**
	 Gets the list of the users or detailed information regarding a particular user.

	 - parameter username:          username of the user, for which the details are requested. If null, the full users list is returned.
	 - parameter isGateway:         whether to return users or gateways.
	 - parameter max:               maximum number of results to fetch.
	 - parameter start:             start index of results to fetch.
	 - parameter channel:           channel name.
	 - parameter completionHandler: completion handler indicating success, response and error.
	 */
	public void getUsers(String username, Boolean isGateway, Integer max, Integer start, String channel, ResultCompletionHandler completionHandler) {
		String command = "user/get";

		if (username != null) {
			command += "/login/" + urlEncode(username);
		}
		if (channel != null) {
			command += "/channel/" + urlEncode(channel);
		}
		if (isGateway != null && isGateway) {
			command += "/gateway/1";
		}
		if (max != null) {
			command += "/max/" + max.toString();
		}
		if (start != null) {
			command += "/start/" + start.toString();
		}

		callAPI(command, HTTPMethod.GET, null, completionHandler);
	}

	/**
	 Gets the list of the channels or detailed information regarding a particular channel.

	 - parameter name:              name of the channel, for which the details are requested. If omitted, the full channels list is returned.
	 - parameter max:               maximum number of results to fetch.
	 - parameter start:             start index of results to fetch.
	 - parameter completionHandler: completion handler indicating success, response and error.
	 */
	public void getChannels(String name, Integer max, Integer start, ResultCompletionHandler completionHandler) {
		String command = "channel/get";

		if (name != null) {
			command += "/name/" + urlEncode(name);
		}
		if (max != null) {
			command += "/max/" + max.toString();
		}
		if (start != null) {
			command += "/start/" + start.toString();
		}

		callAPI(command, HTTPMethod.GET, null, completionHandler);
	}

	/**
	 Adds users to a channel.

	 - parameter channelName: name of the channel where the users will be added.
	 - parameter users:       usernames of the users to add.
	 - parameter completionHandler: completion handler indicating success, response and error.
	 */
	public void addToChannel(String channelName, ArrayList<String> users, ResultCompletionHandler completionHandler) {
		String command = "user/addto/" + urlEncode(channelName);

		String parameters = implode("login[]=", "&login[]=", users);

		callAPI(command, HTTPMethod.POST, parameters, completionHandler);
	}

	/**
	 Add users to multiple channels.

	 - parameter channelNames:      channel names where the users are added.
	 - parameter users:             usernames of the users to add.
	 - parameter completionHandler: completion handler indicating success, response and error.
	 */
	public void addToChannels(ArrayList<String> channelNames, ArrayList<String> users, ResultCompletionHandler completionHandler) {
		String command = "user/addtochannels";

		String parameters = implode("users[]=", "&users[]=", users);
		parameters += implode("&channels[]=", "&channels[]=", channelNames);

		callAPI(command, HTTPMethod.POST, parameters, completionHandler);
	}

	/**
	 Removes users from a channel.

	 - parameter channelName:       name of the channel.
	 - parameter users:             usernames of the users to remove from the channel.
	 - parameter completionHandler: completion handler indicating success, response and error.
	 */
	public void removeFromChannel(String channelName, ArrayList<String> users, ResultCompletionHandler completionHandler) {
		String command = "user/removefrom/" + urlEncode(channelName);

		String parameters = implode("login[]=", "&login[]=", users);

		callAPI(command, HTTPMethod.POST, parameters, completionHandler);
	}

	/**
	 Removes users from multiple channels.

	 - parameter channelNames:      names of the channels.
	 - parameter users:             usernames of the users to remove from channels.
	 - parameter completionHandler: completion handler indicating success, response and error.
	 */
	public void removeFromChannels(ArrayList<String> channelNames, ArrayList<String> users, ResultCompletionHandler completionHandler) {
		String command = "user/removefromchannels";

		String parameters = implode("users[]=", "&users[]=", users);
		parameters += implode("&channels[]=", "&channels[]=", channelNames);

		callAPI(command, HTTPMethod.POST, parameters, completionHandler);
	}

	/**
	 Adds or updates the user.
	 If username exists, the user is updated. Otherwise, a new user is created.
	 When adding a user, the "name" and "password" attributes are required.
	 When updating a user, the "name" attribute is required.

	 See ZelloAPI.deleteUsers()

	 Attributes:
	 - name (required) - username
	 - password - password md5 hash
	 - email - e-mail address
	 - full_name - user alias
	 - job - user position
	 - admin - "true" or "false". Defines whether the user has access to the admin console.
	 - limited_access - "true" or "false". Defines whether the user is restricted from starting 1-on-1 conversations or not.
	 - gateway - set to "true" for adding a gateway, "false" if normal user.
	 - add - "true" or "false". If set to "true", the existing user will not be updated and an error will be returned.

	 - parameter user:              map of user attributes.
	 - parameter completionHandler: completion handler indicating success, response and error.
	 */
	public void saveUser(Map<String, String> user, ResultCompletionHandler completionHandler) {
		String command = "user/save";

		String parameters = createURLStringFromMap(user);

		callAPI(command, HTTPMethod.POST, parameters, completionHandler);
	}

	/**
	 Deletes users.

	 See ZelloAPI.saveUser()

	 - parameter users:             usernames of the users to remove.
	 - parameter completionHandler: completion handler indicating success, response and error.
	 */
	public void deleteUsers(ArrayList<String> users, ResultCompletionHandler completionHandler) {
		String command = "user/delete";

		String parameters = implode("login[]=", "&login[]=", users);

		callAPI(command, HTTPMethod.POST, parameters, completionHandler);
	}

	/**
	 Adds a new channel.

	 - parameter name:              channel name.
	 - parameter isGroup:           true means it is a group channel. false means it is a dynamic channel.
	 - parameter isHidden:          when set to true in combination with isGroup set to true, a hidden group channel is created.
	 - parameter completionHandler: completion handler indicating success, response and error.
	 */
	public void addChannel(String name, Boolean isGroup, Boolean isHidden, ResultCompletionHandler completionHandler) {
		String command = "channel/add/name/" + urlEncode(name);

		if (isGroup != null){
			command += "/shared/" + (isGroup ? "true" : "false");
		}
		if (isHidden != null) {
			command += "/invisible/" + (isHidden ? "true" : "false");
		}

		callAPI(command, HTTPMethod.GET, null, completionHandler);
	}

	/**
	 Deletes channels.

	 - parameter channelNames:      names of the channels to remove.
	 - parameter completionHandler: completion handler indicating success, response and error.
	 */
	public void deleteChannels(ArrayList<String> channelNames, ResultCompletionHandler completionHandler) {
		String command = "channel/delete";

		String parameters = implode("name[]=", "&name[]=", channelNames);

		callAPI(command, HTTPMethod.POST, parameters, completionHandler);
	}

	/**
	 Get channel roles (simple format).

	 - parameter channelName:       channel name.
	 - parameter completionHandler: completion handler indicating success, response and error.
	 */
	public void getChannelsRoles(String channelName, ResultCompletionHandler completionHandler) {
		String command = "channel/roleslist/name/" + urlEncode(channelName);

		callAPI(command, HTTPMethod.GET, null, completionHandler);
	}

	/**
	 Adds or updates channel role.

	 - parameter channelName:       channel name.
	 - parameter roleName:          new role name.
	 - parameter settings:          role settings in JSON format: ["listen_only" : false, "no_disconnect" : true, "allow_alerts" : false, "to": ["dispatchers"]]
	 - parameter completionHandler: completion handler indicating success, response and error.
	 */
	public void saveChannelRole(String channelName, String roleName, Map<String, Object> settings, ResultCompletionHandler completionHandler) {
		String command = "channel/saverole/channel/" + urlEncode(channelName) + "/name/" + urlEncode(roleName);

		JSONObject object = new JSONObject(settings);
		String parameters = "settings=" + object.toString();

		callAPI(command, HTTPMethod.POST, parameters, completionHandler);
	}

	/**
	 Deletes channel role.

	 - parameter channelName:       channel name.
	 - parameter roles:             role names to delete.
	 - parameter completionHandler: completion handler indicating success, response and error.
	 */
	public void deleteChannelRole(String channelName, ArrayList<String> roles, ResultCompletionHandler completionHandler) {
		String command = "channel/deleterole/channel/" + urlEncode(channelName);

		String parameters = implode("roles[]=", "&roles[]=", roles);

		callAPI(command, HTTPMethod.POST, parameters, completionHandler);
	}

	/**
	 Adds users to role in channel.

	 - parameter channelName:       channel name.
	 - parameter roleName:          role name.
	 - parameter users:             usernames to add to role in channel.
	 - parameter completionHandler: completion handler indicating success, response and error.
	 */
	public void addToChannelRole(String channelName, String roleName, ArrayList<String> users, ResultCompletionHandler completionHandler) {
		String command = "channel/addtorole/channel/" + urlEncode(channelName) + "/name/" + urlEncode(roleName);

		String parameters = implode("login[]=", "&login[]=", users);

		callAPI(command, HTTPMethod.POST, parameters, completionHandler);
	}

	private void callAPI(String command, HTTPMethod method, String parameters, ResultCompletionHandler completionHandler) {
		String prefix = "http://";
		if (host.contains("http://") || host.contains("https://")) {
			prefix = "";
		}
		String string = prefix + host + "/" + command;

		if (sessionId != null) {
			string += "?sid=" + sessionId;
		}

		lastURL = string;

		final String urlString = string;
		final String httpParameters = parameters;
		final HTTPMethod httpMethod = method;
		final ResultCompletionHandler resultCompletionHandler = completionHandler;
		new Thread(new Runnable() {
			@Override
			public void run() {
				InputStream is = null;

				try {
					URL url = new URL(urlString);
					HttpURLConnection conn = (HttpURLConnection) url.openConnection();
					conn.setReadTimeout(10000 /* milliseconds */);
					conn.setConnectTimeout(15000 /* milliseconds */);
					conn.setRequestMethod(convertHTTPMethodToString(httpMethod));
					conn.setDoInput(true);
					conn.setDoOutput(true);

					if (httpParameters != null) {
						OutputStream os = conn.getOutputStream();
						BufferedWriter writer = new BufferedWriter(
								new OutputStreamWriter(os, "UTF-8"));
						writer.write(httpParameters);

						writer.flush();
						writer.close();
						os.close();
					}

					// Starts the query
					conn.connect();
					is = conn.getInputStream();

					// Convert the InputStream into a string
					String contentAsString = readIt(is);

					final JSONObject result = new JSONObject(contentAsString);

					final String response = result.getString("code");
					resultCompletionHandler.onResult(response != null && response.equals("200"), result, null);
				} catch (final Exception e) {
					resultCompletionHandler.onResult(false, null, e);
				} finally {
					try {
						if (is != null) {
							is.close();
						}
					} catch (Exception e) {
						// Empty
					}
				}
			}
		}).start();
	}

	// Reads an InputStream and converts it to a String.
	private String readIt(InputStream stream) throws IOException {
		Reader reader = new InputStreamReader(stream, "UTF-8");
		char[] buffer = new char[10240];
		int bytesRead = reader.read(buffer);

		return new String(buffer, 0, bytesRead);
	}

	private String convertHTTPMethodToString(HTTPMethod method) {
		switch (method) {
			case POST:
				return "POST";
			case GET:
				return "GET";
		}

		return "";
	}

	private synchronized String MD5(String string) {
		try {
			MessageDigest m = MessageDigest.getInstance("MD5");
			m.reset();
			m.update(string.getBytes());
			byte[] digest = m.digest();
			BigInteger bigInt = new BigInteger(1, digest);

			return bigInt.toString(16);
		} catch (Exception e) {
			// Empty
		}

		return null;
	}

	private String urlEncode(String string) {
		try {
			return URLEncoder.encode(string, "UTF-8");
		} catch (UnsupportedEncodingException e) {
			return string;
		}
	}

	private String implode(String string, String glue, ArrayList<String> pieces) {
		for (int i = 0; i < pieces.size(); i++) {
			string += urlEncode(pieces.get(i));

			if (i < pieces.size() - 1) {
				string += glue;
			}
		}

		return string;
	}

	private String createURLStringFromMap(Map<String, String> map) {
		String string = "";

		Object[] keys = map.keySet().toArray();
		for (int i = 0; i < keys.length; i++) {
			String key = (String) keys[i];
			String value = map.get(key);

			if (i == 0) {
				string += key + "=" + urlEncode(value);
			} else {
				string += "&" + key + "=" + urlEncode(value);
			}
		}

		return string;
	}

}
