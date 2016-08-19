//
//  Copyright © 2016 Zello. All rights reserved.
//

using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace APITest
{
    class Program
    {
        static APITest apiTest;

        static void Main(string[] args)
        {
            MainAsync().Wait();
        }

        static async Task MainAsync()
        {
            // Input your host url or IP address and your API key.
            apiTest = new APITest("https://testing.zellowork.com/", "QSAEV6ZUGJ4BEJJNW49CUL6ALM70XGN7");
            // Input the administrative username/password combination.
            await apiTest.startTesting("admin", "secret");

            Console.WriteLine("Press any key to exit...");
            Console.ReadKey();
        }
    }
}
