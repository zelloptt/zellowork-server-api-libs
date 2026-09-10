<?php
$lang = 'php';

function emit($lang, $scenario, $ok, $error = null) {
	$out = array('lang' => $lang, 'scenario' => $scenario, 'ok' => $ok);
	if ($error !== null && $error !== '') {
		$out['error'] = $error;
	}
	echo json_encode($out) . "\n";
}

$host = getenv('ZW_HOST');
$username = getenv('ZW_USERNAME');
$apiKey = getenv('ZW_API_KEY');
$password = getenv('ZW_PASSWORD');
$scenarioPath = getenv('ZW_SCENARIO');

if (!$host || !$username || !$apiKey || !$password || !$scenarioPath) {
	emit($lang, 'unknown', false, 'missing ZW_HOST, ZW_USERNAME, ZW_API_KEY, ZW_PASSWORD, or ZW_SCENARIO');
	exit(1);
}

$scenario = json_decode(file_get_contents($scenarioPath), true);
if (!$scenario) {
	emit($lang, 'unknown', false, 'failed to parse scenario JSON');
	exit(1);
}

$scenarioId = isset($scenario['id']) ? $scenario['id'] : basename($scenarioPath, '.json');
$expectSuccess = !isset($scenario['expect_success']) || $scenario['expect_success'];

require_once '/workspace/php/zello_server_api.class.php';

$api = null;
$stepsOk = true;
$error = null;

try {
	foreach ($scenario['steps'] as $step) {
		$op = $step['op'];
		if ($op === 'authenticate') {
			$key = isset($step['api_key']) ? $step['api_key'] : $apiKey;
			$pass = isset($step['password']) ? $step['password'] : $password;
			$api = new ZelloServerAPI($host, $key);
			$api->use_legacy_auth = !empty($step['legacy_auth']);
			if (!$api->auth($username, $pass)) {
				$stepsOk = false;
				$error = $api->errorCode . ' ' . $api->errorDescription;
				break;
			}
		} elseif ($op === 'get_users') {
			if (!$api || !$api->getUsers()) {
				$stepsOk = false;
				$error = $api ? ($api->errorCode . ' ' . $api->errorDescription) : 'no api';
				break;
			}
		} elseif ($op === 'logout') {
			if (!$api || !$api->logout()) {
				$stepsOk = false;
				$error = $api ? ($api->errorCode . ' ' . $api->errorDescription) : 'no api';
				break;
			}
		} else {
			$stepsOk = false;
			$error = 'unknown op: ' . $op;
			break;
		}
	}
} catch (Exception $e) {
	$stepsOk = false;
	$error = $e->getMessage();
}

$ok = ($stepsOk === $expectSuccess);
if (!$ok && $error === null) {
	$error = $expectSuccess ? 'steps failed' : 'expected failure but steps succeeded';
}
emit($lang, $scenarioId, $ok, $ok ? null : $error);
exit($ok ? 0 : 1);
