//
//  Copyright © 2016 Zello. All rights reserved.
//

package com.zello.apitest;

import android.util.Log;

import org.json.JSONObject;

import java.math.BigInteger;
import java.security.MessageDigest;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.Map;

public class APITest {

	static String TAG = "APITest";

	ZelloAPI api;

	public APITest(String host, String apiKey, String username, String password) {
		api = new ZelloAPI(host, apiKey);
		authenticate(username, password);
	}

	void authenticate(String username, String password) {
		api.authenticate(username, password, new ResultCompletionHandler() {
			@Override
			public void onResult(boolean success, JSONObject response, Exception exception) {
				Log.w(TAG, "authenticate: " + Boolean.toString(success));

				if (success) {
					startTesting();
				} else {
					Log.w(TAG, "Input the correct credentials for your network in MainActivity.java");
				}
			}
		});
	}

	void startTesting() {
		api.getUsers(null, false, null, null, null, new ResultCompletionHandler() {
			@Override
			public void onResult(boolean success, JSONObject response, Exception exception) {
				Log.w(TAG, "getUsers: " + Boolean.toString(success));
				if (success) {
					Log.w(TAG, response.toString());
				}

				api.getChannels(null, null, null, new ResultCompletionHandler() {
					@Override
					public void onResult(boolean success, JSONObject response, Exception exception) {
						Log.w(TAG, "getChannels: " + Boolean.toString(success));
						if (success) {
							Log.w(TAG, response.toString());
						}

						// Add or update user
						Map<String, String> userMap = new HashMap<>();
						userMap.put("name", "zelloapi_test");
						userMap.put("password", MD5("test"));
						userMap.put("email", "support@zello.com");
						userMap.put("full_name", "API Test 'На здоровье'"); // UTF-8 is fully supported
						api.saveUser(userMap, new ResultCompletionHandler() {
							@Override
							public void onResult(boolean success, JSONObject response, Exception exception) {
								Log.w(TAG, "saveUser: " + Boolean.toString(success));

								// List users again -- look the new user is there
								api.getUsers(null, false, null, null, null, new ResultCompletionHandler() {
									@Override
									public void onResult(boolean success, JSONObject response, Exception exception) {
										Log.w(TAG, "getUsers: " + Boolean.toString(success));

										if (success) {
											Log.w(TAG, response.toString());
										}

										continueTesting();
									}
								});
							}
						});
					}
				});
			}
		});
	}

	void continueTesting() {
		// Add channel
		api.addChannel("Test channel", null, null, new ResultCompletionHandler() {
			@Override
			public void onResult(boolean success, JSONObject response, Exception exception) {
				Log.w(TAG, "addChannel: " + Boolean.toString(success));

				// Add user to a channel
				ArrayList<String> users = new ArrayList<>();
				users.add("zelloapi_test");
				api.addToChannel("Test channel", users, new ResultCompletionHandler() {
					@Override
					public void onResult(boolean success, JSONObject response, Exception exception) {
						Log.w(TAG, "addToChannel: " + Boolean.toString(success));

						// List channels again
						api.getChannels(null, null, null, new ResultCompletionHandler() {
							@Override
							public void onResult(boolean success, JSONObject response, Exception exception) {
								Log.w(TAG, "getChannels: " + Boolean.toString(success));

								if (success) {
									Log.w(TAG, response.toString());
								}

								// Create channel role

								Map<String, Object> channelRoleMap = new HashMap<>();
								channelRoleMap.put("listen_only", false);
								channelRoleMap.put("no_disconnect", true);
								channelRoleMap.put("allow_alerts", false);
								String[] toArray = new String[]{};
								channelRoleMap.put("to", toArray);

								api.saveChannelRole("Test channel", "Dispatcher", channelRoleMap, new ResultCompletionHandler() {
									@Override
									public void onResult(boolean success, JSONObject response, Exception exception) {
										Log.w(TAG, "saveChannelRole: " + Boolean.toString(success));

										Map<String, Object> channelRoleMap = new HashMap<>();
										channelRoleMap.put("listen_only", false);
										channelRoleMap.put("no_disconnect", false);
										channelRoleMap.put("allow_alerts", true);
										String[] toArray = new String[] { "Dispatcher" };
										channelRoleMap.put("to", toArray);

										api.saveChannelRole("Test channel", "Driver", channelRoleMap, new ResultCompletionHandler() {
											@Override
											public void onResult(boolean success, JSONObject response, Exception exception) {
												Log.w(TAG, "saveChannelRole: " + Boolean.toString(success));

												// List channel roles
												api.getChannelsRoles("Test channel", new ResultCompletionHandler() {
													@Override
													public void onResult(boolean success, JSONObject response, Exception exception) {
														Log.w(TAG, "getChannelsRoles: " + Boolean.toString(success));

														if (success) {
															Log.w(TAG, response.toString());
														}

														cleanUp();
													}
												});
											}
										});
									}
								});
							}
						});
					}
				});
			}
		});
	}

	void cleanUp() {
		// Remove the channel
		ArrayList<String> channelNames = new ArrayList<>();
		channelNames.add("Test channel");
		api.deleteChannels(channelNames, new ResultCompletionHandler() {
			@Override
			public void onResult(boolean success, JSONObject response, Exception exception) {
				Log.w(TAG, "deleteChannels: " + Boolean.toString(success));

				// Delete the user we just added
				ArrayList<String> users = new ArrayList<>();
				users.add("zelloapi_test");
				api.deleteUsers(users, new ResultCompletionHandler() {
					@Override
					public void onResult(boolean success, JSONObject response, Exception exception) {
						Log.w(TAG, "deleteUsers: " + Boolean.toString(success));

						// List users one last time -- the new user is gone
						api.getUsers(null, false, null, null, null, new ResultCompletionHandler() {
							@Override
							public void onResult(boolean success, JSONObject response, Exception exception) {
								Log.w(TAG, "getUsers: " + Boolean.toString(success));

								if (success) {
									Log.w(TAG, response.toString());
								}
							}
						});
					}
				});
			}
		});
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

}
