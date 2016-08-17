//
//  Copyright © 2016 Zello. All rights reserved.
//

package com.zellowork.apiwrapper;

import org.json.JSONObject;

/// Completion handler for making API Requests that returns a success indicator, a JSON object and an exception.
/// A value for the error variable represents a client error. This is not the error returned by the API.
/// An error returned by the API can be retrieved through the JSON object.
public interface ResultCompletionHandler {
	void onResult(boolean success, JSONObject response, Exception exception);
}
