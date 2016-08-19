//
//  Copyright © 2016 Zello. All rights reserved.
//

import UIKit

class ViewController: UIViewController {

  var apiTest: APITest!
  
  override func viewDidLoad() {
    super.viewDidLoad()

    // Input your host url or IP address, your API key, and the administrative username/password combination.
    apiTest = APITest(host: "https://testing.zellowork.com/", apiKey: "QSAEV6ZUGJ4BEJJNW49CUL6ALM70XGN7", username: "admin", password: "secret")
  }

}
