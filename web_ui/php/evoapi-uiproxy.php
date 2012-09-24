<?php

require 'evoapi-core.php';

// Set the strict warnings and notices to off
error_reporting(E_ALL ^ (E_NOTICE | E_STRICT));

// Display the necessary header for the JSON responses
header('Content-Type:text/plain:charset=utf-8');

// Before anything else, check if we have php-curl installed
if (!function_exists('curl_init')) {
	echo json_encode(array('success' => false, 'description' => '<br /> Kindly install/enable php-curl module and try again. <br /> This standard module allows the webserver to communicate with the EMS.'));
	exit();
}

// Instantiate EMS functionalities
$api = new EvoCoreAPI('http://' . $_POST['ip'] . ':7777/');

$description = ''; // container for the actual description in case of failure
$result = false; // command success/fail state

/*
 * Test connection to server by sending out the Version command
 *
 * Decode the JSON format to determine if
 * 1) We have a response from the server
 * 2) It is successful in connecting
 */
$connected = checkResponse($description, json_decode($api->Version(), true));

if ($connected && isset($_POST['cmd'])) {
	/**
	 * At this point we know the version of the server (which is returned through 
	 * the $description variable)
	 * 
	 */
	$version = (float) $description['releaseNumber'];

	// Able to connect to the server and we have a command request
	$webRoot = '/var/www/html';

	switch ((string) $_POST['cmd']) {
		case "addStream":
			// Check if we have the necessary parameters first
			if (isset($_POST['source'], $_POST['name'], $_POST['forceTcp'])) {
				// Call the API to add the stream and check the response
				$result = checkResponse($description, json_decode($api->pullStream($_POST['source'], '', $_POST['name'], '', '', $_POST['forceTcp'], '', ''), true));

				// Before returning, sleep for a few seconds to allow EMS process the request
				sleep(1);
			} else {
				$result = false;
				$description = 'Incomplete parameters!';
			}

			echo json_encode(array('success' => $result, 'description' => $description));
			exit();
		case "createHLS":
			// Check if we have the necessary parameters first
			if (isset($_POST['name'], $_POST['folder'])) {

				$targetFolder = $_POST['folder'];
				if ('' == $targetFolder) {
					$targetFolder = $webRoot . '/hls';
				}

				$group = $_POST['group'];
				$chunk = $_POST['chunkLength'];

				// Call the API to add HLS stream and check the response
				$result = checkResponse($description, json_decode($api->createHLSStream($_POST['name'], $targetFolder, '', '', '', '', '', $group, '', '', '', $chunk, '', ''), true));

				// Before returning, sleep for a few seconds to allow EMS process the request
				sleep(1);
			} else {
				$result = false;
				$description = 'Incomplete parameters!';
			}

			echo json_encode(array('success' => $result, 'description' => $description));
			exit();
		case "listStream":
			// List available streams on EMS
			$json = json_decode($api->listStreams(), true);

			if (checkResponse($description, $json)) {
				// Set the container for the list of streams
				$list = array();
				//$xmlDoc = '';
				$name = '';
				$uri = '';
				$latest = false;

				if ($version >= 1.6) {
					// This is the latest version of the server
					$latest = true;
				}

				//TODO: for each array push, pull, hds and hls, need to compare with the latest version number
				// Loop through each entry and parse accordingly, update the streams.xml as well
				if (is_array($json['data'])) {
					foreach ($json['data'] as $data) {
						if (array_key_exists('pullSettings', $data)) {
							$name = $data['pullSettings']['localStreamName'];
							if ($latest) {
								$uri = $data['pullSettings']['uri']['fullUri'];
							} else {
								$uri = $data['pullSettings']['uri'];
							}
							array_push($list, array('id' => $data['uniqueId'], 'name' => $name, 'uri' => $uri, 'type' => 'pull'));

							// Only show as RTMP source
							//$uri = 'rtmp://' . $_POST['ip'] . '/live/' . $name;
							//addXmlListEntry($xmlDoc, $name, $uri);
							// Add RTSP source?
							//$uri = 'rtsp://' . $_POST['ip'] . ':5544/' . $name;
							//addXmlListEntry($xmlDoc, $name, $uri);
						} else if (array_key_exists('pushSettings', $data)) {
							$name = $data['pushSettings']['localStreamName'];
							if ($latest) {
								$uri = $data['pushSettings']['targetUri']['fullUri'];
							} else {
								$uri = $data['pushSettings']['targetUri'];
							}
							array_push($list, array('id' => $data['uniqueId'], 'name' => $name, 'uri' => $uri, 'type' => 'push'));
							//addXmlListEntry($xmlDoc, $name, $uri);
						} else if (array_key_exists('hlsSettings', $data)) {
							$name = $data['hlsSettings']['localStreamName'];
							$uri = $data['hlsSettings']['masterPlaylistPath'];

							// Replace uri to have a valid http link. This assumes that webroot is /var/www/html!!!
							$uriHls = str_replace($webRoot, ('http://' . $_POST['ip']), $uri);
							$uri = $uriHls;

							array_push($list, array('id' => $data['uniqueId'], 'name' => $name, 'uri' => $uri, 'type' => 'hls'));
							//addXmlListEntry($xmlDoc, $name, $uri);
						} else if (array_key_exists('hdsSettings', $data)) {
							$name = $data['hdsSettings']['localStreamName'];
							$uri = $data['hdsSettings']['masterPlaylistPath'];

							// Replace uri to have a valid http link. This assumes that webroot is /var/www/html!!!
							$uriHds = str_replace($webRoot, ('http://' . $_POST['ip']), $uri);
							$uri = $uriHds;

							array_push($list, array('id' => $data['uniqueId'], 'name' => $name, 'uri' => $uri, 'type' => 'hds'));
							//addXmlListEntry($xmlDoc, $name, $uri);
						} else {
							$type = ($data['type'][0] == 'O') ? "outbound" : "inbound";
							array_push($list, array('id' => $data['uniqueId'], 'name' => $data['name'], 'uri' => '', 'type' => $type));
						}
					}
				}

				// Create the new streams.xml
				//createXmlList($xmlDoc);
				// Set up the response
				echo json_encode(array('data' => $list, 'success' => true));
			} else {
				// Error getting list of streams
				echo json_encode(array('success' => false, 'description' => $description));
			}

			exit();
		case "removeStream":
			// Check if we have the necessary parameters first
			if (isset($_POST['id'])) {
				// Call the API to remove the stream and check the response
				$result = checkResponse($description, json_decode($api->shutdownStream($_POST['id'], '1'), true));

				// Before returning, sleep for a few seconds to allow EMS process the request
				sleep(1);
			} else {
				$result = false;
				$description = 'Incomplete parameters!';
			}

			echo json_encode(array('success' => $result, 'description' => $description));
			exit();
		case "sendMpegTs":
			// Check if we have the necessary parameters first
			if (isset($_POST['target'], $_POST['name'])) {
				// Push the stream to the target address
				$result = checkResponse($description, json_decode($api->pushStream('mpegtsudp://' . $_POST['target'], $_POST['name'], '', '', '', '', '', '', '', ''), true));

				// Before returning, sleep for a few seconds to allow EMS process the request
				sleep(1);
			} else {
				$result = false;
				$description = 'Incomplete parameters!';
			}

			echo json_encode(array('success' => $result, 'description' => $description));
			exit();
		case "stopMpegTs":
			// Check parameter
			if (isset($_POST['stop'])) {
				// Get a list of streams. TODO: I'm not sure why listPullPushConfig() was used but retain for the time being
				$retVal = json_decode($api->listPullPushConfig(), true);

				if (checkResponse($description, $retVal)) {
					$nb = 0;

					// Loop through the pushed streams and search for mpegtsudp TODO: or should this be dmpegtsudp?
					foreach ($retVal['data']['push'] as $data) {

						// Check if this stream is mpegtsudp
						preg_match('/^(\w+):\/\//', $data['targetUri'], $m);
						if (!strcasecmp($m[1], $_POST['stop'])) {
							// If it is, remove it.
							$fn = json_decode($api->removePullPushConfig($data['configId'], '', ''), true);

							// Increment for each MPEG-TS stream removed
							if (checkResponse($d, $fn)) {
								$nb++;
							}
						}
					}

					echo json_encode(array('success' => true, 'description' => $nb . ' MPEG-TS stream(s) stopped'));
					exit();
				}
			}

			echo json_encode(array('success' => false, 'description' => $description));
			exit();
		default:
			// Nothing to do...
			exit();
	}
} else {
	// If weren't able to connect
	if (!$connected) {
		$description = '<br /> Either EMS is stopped or the firewall settings (and/or SeLinux) of the target machine does not permit connection to port 7777. <br /> Kindly consult the user manual.';
	}

	// Send back the Version() response to the browser
	echo json_encode(array('connected' => $connected, 'description' => $description));
}

/**
 * Checks the decoded JSON result and determines if the command response is a success
 *
 * @param type $description Contains the actual returned 'description'
 * @param type $response JSON decoded input
 * @return boolean true on a successful command, false otherwise
 */
function checkResponse(&$description, $response) {
	$retVal = false;

	if (null != $response) {
		if ($response['status'] == 'SUCCESS') {
			$retVal = true;
			$description = $response['data'];
		} else {
			$description = $response['description'];
		}
	} else {
		$description = null;
	}

	return $retVal;
}

/**
 * Creates the actual streams.xml file
 */
function createXmlList($xml) {
	$xmlFile = '../shared/streams.xml';
	$xml = '<?xml version="1.0" encoding="utf-8"?>' . PHP_EOL . '<channellist>' . PHP_EOL . $xml . '</channellist>' . PHP_EOL;

	$fh = fopen($xmlFile, 'w');
	if (false != $fh) {
		fwrite($fh, $xml);
		fclose($fh);
	}
}

/**
 * Add entries to the streams.xml file
 *
 * @param string $xml Container of the xml elements
 * @param type $name Name of the stream to be added
 * @param type $uri URI/Path of the stream
 */
function addXmlListEntry(&$xml, $name, $uri) {
	// Assume for now, since the path for HLS/HDS does not contain anything
	$protocol = 'http';

	// Parse the protocol used
	if (preg_match('/^(\w+):\/\//', $uri, $p)) {
		$protocol = $p[1];
	}

	$nameTmp = '<name>' . $name . '</name>';

	// Retain a single entry for each stream name
	if (strpos($xml, $nameTmp)) {
		$insertVal = $nameTmp . PHP_EOL . '    <' . $protocol . '>' . $uri . '</' . $protocol . '>';
		$xml = str_replace($nameTmp, $insertVal, $xml);
	} else {
		$xml = $xml . '  <channel>' . PHP_EOL . '    <name>' . $name . '</name>' . PHP_EOL . '    <' . $protocol . '>' . $uri . '</' . $protocol . '>' . PHP_EOL . '  </channel>' . PHP_EOL;
	}
}
