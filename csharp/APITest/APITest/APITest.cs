//
//  Copyright © 2016 Zello. All rights reserved.
//

using System;
using System.Collections.Generic;
using System.Collections;
using System.Security.Cryptography;
using System.Text;
using System.Threading.Tasks;

namespace APITest
{
    public class APITest
    {
        readonly ZelloAPI api;

        public APITest(string host, string apiKey)
        {
            api = new ZelloAPI(host, apiKey);
        }

        public async Task startTesting(string username, string password)
        {
            await authenticate(username, password);
        }

        async Task authenticate(string username, string password)
        {
            ZelloAPIResult result = null;
            try
            {
                result = await api.Authenticate(username, password);
            }
            catch (System.UriFormatException)
            {
            }

            if (result != null)
            {
                Console.WriteLine("Authenticate: " + result.Success);

                if (result.Success)
                {
                    await callOtherMethods();
                }
                else
                {
                    Console.WriteLine("Input the correct credentials for your network in Program.cs");
                }
            }
            else
            {
                Console.WriteLine("Input the correct credentials for your network in Program.cs");
            }
        }

        async Task callOtherMethods()
        {
            ZelloAPIResult result = await api.GetUsers(null, false, null, null, null);
            Console.WriteLine("GetUsers: " + result.Success);
            if (result.Success)
            {
                Object[] arr = (Object[])result.Response["users"];
                foreach (Object obj in arr)
                {
                    dictionaryOut((Dictionary<string, object>)obj);
                }
            }

            result = await api.GetChannels(null, null, null);
            Console.WriteLine("GetChannels: " + result.Success);
            if (result.Success)
            {
                Object[] arr = (Object[])result.Response["channels"];
                foreach (Object obj in arr)
                {
                    dictionaryOut((Dictionary<string, object>)obj);
                }
            }

            // Add or update user
            var userDictionary = new Dictionary<string, string>();
            userDictionary.Add("name", "zelloapi_test");
            userDictionary.Add("password", MD5Hash("test"));
            userDictionary.Add("email", "support@zello.com");
            userDictionary.Add("full_name", "API Test 'На здоровье'"); // UTF-8 is fully supported 
            result = await api.SaveUser(userDictionary);
            Console.WriteLine("SaveUser: " + result.Success);

            // List users again -- look the new user is there
            result = await api.GetUsers(null, false, null, null, null);
            Console.WriteLine("GetUsers: " + result.Success);
            if (result.Success)
            {
                Object[] arr = (Object[])result.Response["users"];
                foreach (Object obj in arr)
                {
                    dictionaryOut((Dictionary<string, object>)obj);
                }
            }

            // Add channel
            result = await api.AddChannel("Test channel", null, null);
            Console.WriteLine("AddChannel: " + result.Success);

            // Add user to a channel
            var users = new ArrayList();
            users.Add("zelloapi_test");
            result = await api.AddToChannel("Test channel", users);
            Console.WriteLine("AddToChannel: " + result.Success);

            // List channels again
            result = await api.GetChannels(null, null, null);
            Console.WriteLine("GetChannels: " + result.Success);
            if (result.Success)
            {
                Object[] arr = (Object[])result.Response["channels"];
                foreach (Object obj in arr)
                {
                    dictionaryOut((Dictionary<string, object>)obj);
                }
            }

            // Create channel role

            var channelRoleDictionary = new Dictionary<string, object>();
            channelRoleDictionary.Add("listen_only", false);
            channelRoleDictionary.Add("no_disconnect", true);
            channelRoleDictionary.Add("allow_alerts", false);
            var toArray = new string[0];
            channelRoleDictionary.Add("to", toArray);
            result = await api.SaveChannelRole("Test channel", "Dispatcher", channelRoleDictionary);
            Console.WriteLine("SaveChannelRole: " + result.Success);

            channelRoleDictionary = new Dictionary<string, object>();
            channelRoleDictionary.Add("listen_only", false);
            channelRoleDictionary.Add("no_disconnect", false);
            channelRoleDictionary.Add("allow_alerts", true);
            toArray = new string[] { "Dispatcher" };
            channelRoleDictionary.Add("to", toArray);
            result = await api.SaveChannelRole("Test channel", "Driver", channelRoleDictionary);
            Console.WriteLine("SaveChannelRole: " + result.Success);

            // List channel roles
            result = await api.GetChannelsRoles("Test channel");
            Console.WriteLine("GetChannelsRoles: " + result.Success);
            if (result.Success)
            {
                Object[] arr = (Object[])result.Response["roles"];
                foreach (Object obj in arr)
                {
                    dictionaryOut((Dictionary<string, object>)obj);
                }
            }

            // Remove the channel
            var channelNames = new ArrayList();
            channelNames.Add("Test channel");
            result = await api.DeleteChannels(channelNames);

            // Delete the user we just added
            users = new ArrayList();
            users.Add("zelloapi_test");
            result = await api.DeleteUsers(users);

            // List users one last time -- the new user is gone
            result = await api.GetUsers(null, false, null, null, null);
            Console.WriteLine("GetUsers: " + result.Success);
            if (result.Success)
            {
                Object[] arr = (Object[])result.Response["users"];
                foreach (Object obj in arr)
                {
                    dictionaryOut((Dictionary<string, object>)obj);
                }
            }
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

        void dictionaryOut(Dictionary<string, object> dictionary)
        {
            foreach (KeyValuePair<string, object> temp in dictionary)
            {
                Console.WriteLine(temp.Key + " : " + temp.Value.ToString());
            }

            Console.WriteLine();
        }
    }
}
