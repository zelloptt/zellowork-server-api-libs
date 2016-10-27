//
//  Copyright © 2016 Zello. All rights reserved.
//

using System;
using System.Threading.Tasks;
using System.Net;
using System.Text;
using System.IO;
using System.Collections;
using System.Collections.Generic;
using System.Web.Script.Serialization;
using System.Security.Cryptography;

namespace APITest
{
    /// <summary>
    /// ZelloWork server C# API wrapper class.
    /// This class provides an easy way to interact with the ZelloWork server
    /// from your C# code to add, modify and delete users and channels.
    /// Please note that all text values passed to the API must be in UTF-8 encoding
    /// and any text data returned are in UTF-8 as well.
    /// - Version 1.1
    /// </summary>
    public class ZelloAPI
    {
        /// <summary>
        /// API Version
        /// </summary>
        public static string Version = "1.1";

        /// <summary>
        /// Session ID used to identify logged in client. Typically you'll want to authenticate first and store the Session ID to reuse later.
        /// </summary>
        public string SessionId;

        /// <summary>
        /// Last accessed API URL. Useful for API troubleshooting.
        /// </summary>
        public string LastURL;

        /// <summary>
        /// Server hostname or IP address
        /// </summary>
        string host;
        /// <summary>
        /// API Key
        /// </summary>
        string apiKey;

        /// <summary>
        /// Initializes a new instance of the <see cref="T:Zello.API.ZelloAPI"/> class.
        /// </summary>
        /// <param name="host">Host.</param>
        /// <param name="apiKey">API key.</param>
        public ZelloAPI(string host, string apiKey)
            : this(host, apiKey, null)
        {

        }

        /// <summary>
        /// Initializes a new instance of the <see cref="T:Zello.API.ZelloAPI"/> class.
        /// </summary>
        /// <param name="host">Host.</param>
        /// <param name="apiKey">API key.</param>
        /// <param name="sessionId">Optional session identifier. Can be null.</param>
        public ZelloAPI(string host, string apiKey, string sessionId)
        {
            this.host = host;
            this.apiKey = apiKey;
            SessionId = sessionId;
        }

        /// <summary>
        /// API client authentication.
        /// If authentication fails, use the errorCode and errorDescription attributes on the response dictionary to get error details.
        /// If authentication succeeds, SessionId is set to the Session ID.
        /// The Session ID is reusable so it's recommended that you save this value and use it for further API calls.
        /// Once you are done using the API, call ZelloAPI.Logout() to end the session and invalidate Session ID.
        /// </summary>
        /// <param name="username">administrative username.</param>
        /// <param name="password">administrative password.</param>
        public async Task<ZelloAPIResult> Authenticate(string username, string password)
        {
            ZelloAPIResult result = await callAPI("user/gettoken", HTTPMethod.GET, null).ConfigureAwait(false);

            ZelloAPIResult returnResult;
            if (!result.Success)
            {
                returnResult = new ZelloAPIResult(false, result.Response, null);
                return returnResult;
            }

            if (result.Response == null)
            {
                returnResult = new ZelloAPIResult(false, null, null);
                return returnResult;
            }

            var token = (string)result.Response["token"];

            SessionId = (string)result.Response["sid"];

            if (apiKey == null)
            {
                returnResult = new ZelloAPIResult(false, result.Response, null);
                return returnResult;
            }

            string hashedPassword = MD5Hash(MD5Hash(password) + token + apiKey);
            string parameters = "username=" + username + "&password=" + hashedPassword;

            returnResult = await callAPI("user/login", HTTPMethod.POST, parameters);

            return returnResult;
        }

        /// <summary>
        /// Ends session identified by sessionId.
        /// Use this method to terminate the API session.
        /// See ZelloAPI.Authenticate().
        /// </summary>
        public async Task<ZelloAPIResult> Logout()
        {
            ZelloAPIResult result = await callAPI("user/logout", HTTPMethod.GET, null);
            SessionId = null;

            return result;
        }

        /// <summary>
        /// Gets the list of the users or detailed information regarding a particular user.
        /// </summary>
        /// <param name="username">username of the user, for which the details are requested. If null, the full users list is returned.</param>
        /// <param name="isGateway">whether to return users or gateways.</param>
        /// <param name="max">maximum number of results to fetch.</param>
        /// <param name="start">start index of results to fetch.</param>
        /// <param name="channel">channel name.</param>
        public async Task<ZelloAPIResult> GetUsers(string username, bool isGateway, int? max, int? start, string channel)
        {
            string command = "user/get";

            if (username != null)
            {
                command += "/login/" + urlEncode(username);
            }
            if (channel != null)
            {
                command += "/channel/" + urlEncode(channel);
            }
            if (isGateway)
            {
                command += "/gateway/1";
            }
            if (max != null)
            {
                command += "/max/" + max;
            }
            if (start != null)
            {
                command += "/start/" + start;
            }

            return await callAPI(command, HTTPMethod.GET, null);
        }

        /// <summary>
        /// Gets the list of the channels or detailed information regarding a particular channel.
        /// </summary>
        /// <param name="name">optional name of the channel, for which the details are requested. If omitted, the full channels list is returned.</param>
        /// <param name="max">maximum number of results to fetch.</param>
        /// <param name="start">start index of results to fetch.</param>
        public async Task<ZelloAPIResult> GetChannels(string name, int? max, int? start)
        {
            string command = "channel/get";

            if (name != null)
            {
                command += "/name/" + urlEncode(name);
            }
            if (max != null)
            {
                command += "/max/" + max;
            }
            if (start != null)
            {
                command += "/start/" + start;
            }

            return await callAPI(command, HTTPMethod.GET, null);
        }

        /// <summary>
        /// Adds users to a channel.
        /// </summary>
        /// <param name="channelName">name of the channel where the users will be added.</param>
        /// <param name="users">usernames of the users to add.</param>
        public async Task<ZelloAPIResult> AddToChannel(string channelName, ArrayList users)
        {
            string command = "user/addto/" + urlEncode(channelName);

            string parameters = implode("login[]=", "&login[]=", users);

            return await callAPI(command, HTTPMethod.POST, parameters);
        }

        /// <summary>
        /// Add users to multiple channels.
        /// </summary>
        /// <param name="channelNames">channel names where the users are added.</param>
        /// <param name="users">usernames of the users to add.</param>
        public async Task<ZelloAPIResult> AddToChannels(ArrayList channelNames, ArrayList users)
        {
            string command = "user/addtochannels";

            string parameters = implode("users[]=", "&users[]=", users);
            parameters += implode("&channels[]=", "&channels[]=", channelNames);

            return await callAPI(command, HTTPMethod.POST, parameters);
        }

        /// <summary>
        /// Removes users from a channel.
        /// </summary>
        /// <param name="channelName">name of the channel.</param>
        /// <param name="users">usernames of the users to remove from the channel.</param>
        public async Task<ZelloAPIResult> RemoveFromChannel(string channelName, ArrayList users)
        {
            string command = "user/removefrom/" + urlEncode(channelName);

            string parameters = implode("login[]=", "&login[]=", users);

            return await callAPI(command, HTTPMethod.POST, parameters);
        }

        /// <summary>
        /// Removes users from multiple channels.
        /// </summary>
        /// <param name="channelNames">names of the channels.</param>
        /// <param name="users">usernames of the users to remove from channels.</param>
        public async Task<ZelloAPIResult> RemoveFromChannels(ArrayList channelNames, ArrayList users)
        {
            string command = "user/removefromchannels";

            string parameters = implode("users[]=", "&users[]=", users);
            parameters += implode("&channels[]=", "&channels[]=", channelNames);

            return await callAPI(command, HTTPMethod.POST, parameters);
        }

        /// <summary>
        /// Adds or updates the user.
        /// If username exists, the user is updated.Otherwise, a new user is created.
        /// When adding a user, the "name" and "password" attributes are required.
        /// When updating a user, the "name" attribute is required.
        ///
        /// See ZelloAPI.deleteUsers()
        /// 
        /// Attributes:
        /// - name(required) - username
        /// - password - password md5 hash
        /// - email - e-mail address
        /// - full_name - user alias
        /// - job - user position
        /// - admin - "true" or "false". Defines whether the user has access to the admin console.
        /// - limited_access - "true" or "false". Defines whether the user is restricted from starting 1-on-1 conversations or not.
        /// - gateway - set to "true" for adding a gateway, "false" if normal user.
        /// - add - "true" or "false". If set to "true", the existing user will not be updated and an error will be returned.		
        /// </summary>
        /// <param name="user">dictionary of user attributes.</param>
        public async Task<ZelloAPIResult> SaveUser(Dictionary<string, string> user)
        {
            string command = "user/save";

            string parameters = createURLStringFromDictionary(user);

            return await callAPI(command, HTTPMethod.POST, parameters);
        }

        /// <summary>
        /// Deletes users.
        ///
        /// See ZelloAPI.saveUser().
        /// </summary>
        /// <param name="users">usernames of the users to remove.</param>
        public async Task<ZelloAPIResult> DeleteUsers(ArrayList users)
        {
            string command = "user/delete";

            string parameters = implode("login[]=", "&login[]=", users);

            return await callAPI(command, HTTPMethod.POST, parameters);
        }

        /// <summary>
        /// Adds a new channel.
        /// </summary>
        /// <param name="name">channel name.</param>
        /// <param name="isGroup">true means it is a group channel. false means it is a dynamic channel.</param>
        /// <param name="isHidden">when set to true in combination with isGroup set to true, a hidden group channel is created.</param>
        public async Task<ZelloAPIResult> AddChannel(string name, bool? isGroup, bool? isHidden)
        {
            string command = "channel/add/name/" + urlEncode(name);

            if (isGroup != null)
            {
                command += "/shared/" + ((bool)isGroup ? "true" : "false");
            }
            if (isHidden != null)
            {
                command += "/invisible/" + ((bool)isHidden ? "true" : "false");
            }

            return await callAPI(command, HTTPMethod.GET, null);
        }

        /// <summary>
        /// Deletes channels.
        /// </summary>
        /// <param name="channelNames">names of the channels to remove.</param>
        public async Task<ZelloAPIResult> DeleteChannels(ArrayList channelNames)
        {
            string command = "channel/delete";

            string parameters = implode("name[]=", "&name[]=", channelNames);

            return await callAPI(command, HTTPMethod.POST, parameters);
        }

        /// <summary>
        /// Get channel roles (simple format).
        /// </summary>
        /// <param name="channelName">channel name.</param>
        public async Task<ZelloAPIResult> GetChannelsRoles(string channelName)
        {
            string command = "channel/roleslist/name/" + urlEncode(channelName);

            return await callAPI(command, HTTPMethod.GET, null);
        }

        /// <summary>
        /// Adds or updates channel role.
        /// </summary>
        /// <param name="channelName">channel name.</param>
        /// <param name="roleName">new role name.</param>
        /// <param name="settings">role settings in JSON format: ["listen_only" : false, "no_disconnect" : true, "allow_alerts" : false, "to": ["dispatchers"]].</param>
        public async Task<ZelloAPIResult> SaveChannelRole(string channelName, string roleName, Dictionary<string, object> settings)
        {
            string command = "channel/saverole/channel/" + urlEncode(channelName) + "/name/" + urlEncode(roleName);

            string json = new JavaScriptSerializer().Serialize(settings);
            string parameters = "settings=" + json;

            return await callAPI(command, HTTPMethod.POST, parameters);
        }

        /// <summary>
        /// Deletes channel role.
        /// </summary>
        /// <param name="channelName">channel name.</param>
        /// <param name="roles">role names to delete.</param>
        public async Task<ZelloAPIResult> DeleteChannelRole(string channelName, ArrayList roles)
        {
            string command = "channel/deleterole/channel/" + urlEncode(channelName);

            string parameters = implode("roles[]=", "&roles[]=", roles);

            return await callAPI(command, HTTPMethod.POST, parameters);
        }

        /// <summary>
        /// Adds users to role in channel.
        /// </summary>
        /// <param name="channelName">channel name.</param>
        /// <param name="roleName">role name.</param>
        /// <param name="users">usernames to add to role in channel.</param>
        public async Task<ZelloAPIResult> AddToChannelRole(string channelName, string roleName, ArrayList users)
        {
            string command = "channel/addtorole/channel/" + urlEncode(channelName) + "/name/" + urlEncode(roleName);

            string parameters = implode("login[]=", "&login[]=", users);

            return await callAPI(command, HTTPMethod.POST, parameters);
        }

        async Task<ZelloAPIResult> callAPI(string command, HTTPMethod method, string parameters)
        {
            ZelloAPIResult returnResult;

            string prefix = "http://";
            if (host.Contains("http://") || host.Contains("https://"))
            {
                prefix = "";
            }
            string urlString = prefix + host + "/" + command;

            if (SessionId != null)
            {
                urlString += "?sid=" + SessionId;
            }

            LastURL = urlString;

            var request = (HttpWebRequest)WebRequest.Create(urlString);
            request.Method = convertHTTPMethodToString(method);

            if (parameters != null)
            {
                request.ContentType = "application/x-www-form-urlencoded; charset=utf-8";

                byte[] postData = Encoding.UTF8.GetBytes(parameters);

                using (var requestStream = await Task<Stream>.Factory.FromAsync(request.BeginGetRequestStream, request.EndGetRequestStream, request))
                {
                    requestStream.Write(postData, 0, postData.Length);
                }
            }

            try
            {
                // Pick up the response:
                using (var response = (HttpWebResponse)(await Task<WebResponse>.Factory.FromAsync(request.BeginGetResponse, request.EndGetResponse, null)))
                {
                    var reader = new StreamReader(response.GetResponseStream());
                    string result = reader.ReadToEnd();
                    var json = (Dictionary<string, object>)new JavaScriptSerializer().DeserializeObject(result);

                    bool success = json != null && json["code"].Equals("200");
                    returnResult = new ZelloAPIResult(success, json, null);
                }
            }
            catch (WebException exception)
            {
                returnResult = new ZelloAPIResult(false, null, exception);
            }

            return returnResult;
        }

        string convertHTTPMethodToString(HTTPMethod method)
        {
            switch (method)
            {
                case HTTPMethod.GET:
                    return "GET";
                case HTTPMethod.POST:
                    return "POST";
            }

            return "";
        }

        string MD5Hash(string input)
        {
            // Convert the input string to a byte array and compute the hash.
            byte[] data = MD5.Create().ComputeHash(Encoding.UTF8.GetBytes(input));

            // Create a new StringBuilder to collect the bytes
            // and create a string.
            var sBuilder = new StringBuilder();

            // Loop through each byte of the hashed data 
            // and format each one as a hexadecimal string.
            for (int i = 0; i < data.Length; i++)
            {
                sBuilder.Append(data[i].ToString("x2"));
            }

            // Return the hexadecimal string.
            return sBuilder.ToString();
        }

        string urlEncode(string input)
        {
            return WebUtility.UrlEncode(input);
        }

        string implode(string s, string glue, ArrayList pieces)
        {
            for (int i = 0; i < pieces.Count; i++)
            {
                s += urlEncode((string)pieces[i]);

                if (i < pieces.Count - 1)
                {
                    s += glue;
                }
            }

            return s;
        }

        string createURLStringFromDictionary(Dictionary<string, string> dictionary)
        {
            string s = "";

            int i = 0;
            foreach (KeyValuePair<string, string> entry in dictionary)
            {
                string key = entry.Key;
                string value = entry.Value;

                if (i == 0)
                {
                    s += key + "=" + urlEncode(value);
                }
                else
                {
                    s += "&" + key + "=" + urlEncode(value);
                }

                i++;
            }

            return s;
        }
    }

    /// <summary>
    /// Completion Object for making API Requests that returns a success indicator, a response dictionary and an exception.
    /// A value for the exception variable represents a client error. This is not the error returned by the API.
    /// An error returned by the API can be retrieved through the response dictionary.
    /// </summary>
    public class ZelloAPIResult
    {
        public bool Success;
        public Dictionary<string, object> Response;
        public Exception Exception;

        public ZelloAPIResult(bool success, Dictionary<string, object> response, Exception exception)
        {
            Success = success;
            Response = response;
            Exception = exception;
        }
    }

    enum HTTPMethod
    {
        GET, POST
    }
}
