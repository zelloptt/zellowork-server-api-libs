<?php
/**
* ZelloWork server API sandbox
*/
error_reporting( E_ALL ); 
require("./zello_server_api.class.php"); // ZelloWork API wrapper

$host = "https://testing.zellowork.com/";	// your ZelloWork network URL hostname
$apikey = "QSAEV6ZUGJ4BEJJNW49CUL6ALM70XGN7"; // your API key

$ltapi = new ZelloServerAPI($host, $apikey);
if (!$ltapi) {
	die("Failed to create API wrapper instance");
}

// See if we preserved Session ID through GET parameter. Use it if we did
$sid = isset($_GET["sid"]) ? $_GET["sid"] : '';
if ($sid) {
	$ltapi->sid = $sid;
	echo("Session ID was provided, use it and skip login authentication. ");
	echo('Session ID is <a href="?sid='.$ltapi->sid.'">'.$ltapi->sid.'</a>');
// No Session ID -- authenticate using username / password
} else {
	if (!$ltapi->auth("admin", "secret")) {
		echo("auth error: ".$ltapi->errorCode." ".$ltapi->errorDescription);
		echo("<br/>request: ".$ltapi->lastUrl);
	} else {
		echo('auth successful. Session ID is <a href="?sid='.$ltapi->sid.'">'.$ltapi->sid.'</a>');
	}
}

if (!$ltapi->getUsers()) {
	echo("<br/>getUsers error: ".$ltapi->errorCode." ".$ltapi->errorDescription);
	echo("<br/>request: ".$ltapi->lastUrl);
} else {
	echo("<br/>Users list:");
	arrayOut($ltapi->data["users"]);
}

if (!$ltapi->getChannels()) {
	echo("<br/>getChannels error: ".$ltapi->errorCode." ".$ltapi->errorDescription);
	echo("<br/>request: ".$ltapi->lastUrl);
} else {
	echo("<br/>Channels list:");
	arrayOut($ltapi->data["channels"]);
}
//phpinfo();

// Add or update user
if (!$ltapi->saveUser(array(
	"name" => "ltapi_test",
	"password" => md5("test"),
	"email" => "support@loudtalks.com",
	"full_name" => "API Test 'На здоровье'", // UTF-8 is fully supported 
	"job" => "API guinea pig"
))) {
	echo("<br/>saveUser error: ".$ltapi->errorCode." ".$ltapi->errorDescription);
	echo("<br/>request: ".$ltapi->lastUrl);
} else {
	echo("<br/>User added or updated");
}

// List users again -- look the new user is there
if (!$ltapi->getUsers()) {
	echo("<br/>getUsers error: ".$ltapi->errorCode." ".$ltapi->errorDescription);
	echo("<br/>request: ".$ltapi->lastUrl);
} else {
	echo("<br/>Users list:");
	arrayOut($ltapi->data["users"]);
}

// Add channel
if (!$ltapi->addChannel("Test channel")) {
	echo("<br/>addChannel error: ".$ltapi->errorCode." ".$ltapi->errorDescription);
	echo("<br/>request: ".$ltapi->lastUrl);
} else {
	echo("<br/>Channel added");
}

// Add user to a channel
if (!$ltapi->addToChannel("Test channel", array("ltapi_test"))) {
	echo("<br/>addToChannel error: ".$ltapi->errorCode." ".$ltapi->errorDescription);
	echo("<br/>request: ".$ltapi->lastUrl);
} else {
	echo("<br/>User added to a channel");
}

// List channels again
if (!$ltapi->getChannels()) {
	echo("<br/>getChannels error: ".$ltapi->errorCode." ".$ltapi->errorDescription);
	echo("<br/>request: ".$ltapi->lastUrl);
} else {
	echo("<br/>Channels list:");
	arrayOut($ltapi->data["channels"]);
}

// Create channel role

if (!$ltapi->saveChannelRole("Test channel", "Dispatcher", array(
	"listen_only" => false, 
	"no_disconnect" => true, 
	"allow_alerts" => false, 
	"to" => array()
))) {
	echo("<br/>saveChannelRole error: ".$ltapi->errorCode." ".$ltapi->errorDescription);
	echo("<br/>request: ".$ltapi->lastUrl);
} else {
	echo("<br/>Created a Dispatcher channel role");
}

if (!$ltapi->saveChannelRole("Test channel", "Driver", '{"listen_only":false, "no_disconnect":false, "allow_alerts": true, "to":["Dispatcher"]}')) {
        echo("<br/>saveChannelRole error: ".$ltapi->errorCode." ".$ltapi->errorDescription);
        echo("<br/>request: ".$ltapi->lastUrl);
} else {
        echo("<br/>Created a Driver channel role");
}

// List channel roles
if (!$ltapi->getChannelsRoles("Test channel")) {
	echo("<br/>getChannelsRoles error: ".$ltapi->errorCode." ".$ltapi->errorDescription);
	echo("<br/>request: ".$ltapi->lastUrl);
} else {
	echo("<br/>Roles defined in Test channel:");
	arrayOut($ltapi->data["roles"]);
}

// Remove the channel
if (!$ltapi->deleteChannels(array("Test channel"))) {
	echo("<br/>deleteChannels error: ".$ltapi->errorCode." ".$ltapi->errorDescription);
	echo("<br/>request: ".$ltapi->lastUrl);
} else {
	echo("<br/>Channels removed");
}

// Delete the user we just added
if (!$ltapi->deleteUsers(array("ltapi_test"))) {
	echo("<br/>deleteUsers error: ".$ltapi->errorCode." ".$ltapi->errorDescription);
	echo("<br/>request: ".$ltapi->lastUrl);
} else {
	echo("<br/>Users removed");
}

// List users one last time -- the new user is gone
if (!$ltapi->getUsers()) {
	echo("<br/>getUsers error: ".$ltapi->errorCode." ".$ltapi->errorDescription);
	echo("<br/>request: ".$ltapi->lastUrl);
} else {
	echo("<br/>Users list:");
	arrayOut($ltapi->data["users"]);
}

/*
 * A simple helper function to aid data output in this example 
 */
function arrayOut($arr) {
	echo '<table border="1">';
	echo "<tr><td>".implode("</td><td>", array_keys($arr[0]))."</td></tr>";
	foreach ($arr as $row) {
		echo "<tr><td>".implode("</td><td>", array_map("printValue", $row))."</td></tr>";
	}
	echo "</table>";
}
function printValue($val){
	if (is_array($val)) {
		if (function_exists("json_encode")) {
			return json_encode($val);
		} else { 
			return implode(", ", $val);
		}
	} else {
		return $val;
	}
}
?>
