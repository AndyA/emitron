<?php

/**
 * @package evostream
 * @subpackage api
 * @version 0.708
 */

/**
 * EMS API
 */
class EvoCoreAPI {
	/*
	 * evostream server url
	 * @var string
	 * @access private
	 */

	private $ServerUrl = "http://localhost:7777/";

	/*
	 * json data
	 * @var string
	 * @access private
	 */
	private $data = "";

	function __construct($svrURL) {
		if ($svrURL != "")
			$this->ServerUrl = $svrURL;
	}

	/*
	 * process ems api function with curl
	 *
	 * @param    string      $fn         api function
	 * @param    string      $params     function parameters
	 * @return   string                  json data
	 */

	private function _procFunc($fn, $params = '') {
		$url = $this->ServerUrl . $fn;

		if ($params != '') {
			$url .= '?params=' . base64_encode($params);
		}

		$curl = curl_init();

		// Set the URL including the parameters
		curl_setopt($curl, CURLOPT_URL, $url);

		// We don't need any HTTP header, so set as empty
		curl_setopt($curl, CURLOPT_HTTPHEADER, array());

		// Return the data instead of printing it out
		curl_setopt($curl, CURLOPT_RETURNTRANSFER, true);

		// Set the time out to 10sec, should be long enough in case no response from server
		curl_setopt($curl, CURLOPT_CONNECTTIMEOUT, 10);

		// Actual curl exec
		$this->data = curl_exec($curl);

		curl_close($curl);

		// Return as string, this however is in JSON format
		return $this->data;
	}

	/*
	 * pull in a stream from an external source
	 */

	public function pullStream($uri, $keepAlive, $localStreamName, $width, $height, $forceTcp, $ttl, $tos) {
		if (!isset($uri) || empty($uri)) {
			Throw new Exception('parameter uri required');
		}
		if (!isset($keepAlive) || $keepAlive == '') {
			$keepAlive = 1;
		}
		if (!preg_match('/^[0,1]{1}$/', $keepAlive)) {
			Throw new Exception('parameter keepAlive invalid');
		}
		if (!isset($localStreamName) || empty($localStreamName)) {
			$localStreamName = '';
		}
		if (!isset($width) || empty($width)) {
			$width = 0;
		} else if (!preg_match('/^\d+$/', $width)) {
			Throw new Exception('parameter width invalid');
		}
		if (!isset($height) || empty($height)) {
			$height = 0;
		} else if (!preg_match('/^\d+$/', $height)) {
			Throw new Exception('parameter height invalid');
		}
		if (!isset($forceTcp) || $forceTcp == '') {
			$forceTcp = 1;
		}
		if (!preg_match('/^[0,1]{1}$/', $forceTcp)) {
			Throw new Exception('parameter forceTcp invalid');
		}
		if (!isset($ttl) || empty($ttl)) {
			$ttl = 0;
		}
		if (!isset($tos) || empty($tos)) {
			$tos = 0;
		}
		$params = 'uri=' . str_replace(' ', '', $uri) . ' keepAlive=' . $keepAlive . ' localStreamName=' . str_replace(' ', '', $localStreamName) . ' width=' . $width . ' height=' . $height . ' forceTcp=' . $forceTcp . ' ttl=' . $ttl . ' tos=' . $tos;
		return $this->_procFunc("pullStream", $params);
	}

	/*
	 * push a local stream to an external destination
	 */

	public function pushStream($uri, $localStreamName, $keepAlive, $targetStreamName, $targetStreamType, $emulateUserAgent, $swfUrl, $pageUrl, $ttl, $tos) {
		if (!isset($uri) || empty($uri)) {
			Throw new Exception('parameter uri required');
		}
		if (!isset($localStreamName) || empty($localStreamName)) {
			Throw new Exception('parameter localStreamName required');
		}
		if (!isset($keepAlive) || $keepAlive == '') {
			$keepAlive = 1;
		}
		if (!preg_match('/^[0,1]{1}$/', $keepAlive)) {
			Throw new Exception('parameter keepAlive invalid');
		}
		if (!isset($targetStreamName) || empty($targetStreamName)) {
			$targetStreamName = $localStreamName;
		}
		if (!isset($targetStreamType) || empty($targetStreamType)) {
			$targetStreamType = 'live';
		}
		if (!preg_match('/^live|record|append$/i', $targetStreamType)) {
			Throw new Exception('parameter targetStreamType invalid');
		}
		if (!isset($emulateUserAgent) || empty($emulateUserAgent)) {
			$emulateUserAgent = '';
		}
		if (!isset($swfUrl) || empty($swfUrl)) {
			$swfUrl = '';
		}
		if (!isset($pageUrl) || empty($pageUrl)) {
			$pageUrl = '';
		}
		if (!isset($ttl) || empty($ttl)) {
			$ttl = 0;
		}
		if (!isset($tos) || empty($tos)) {
			$tos = 0;
		}
		$params = 'uri=' . str_replace(' ', '', $uri) . ' localStreamName=' . str_replace(' ', '', $localStreamName) . ' keepAlive=' . $keepAlive . ' targetStreamName=' . str_replace(' ', '', $targetStreamName) . ' targetStreamType=' . $targetStreamType . ' emulateUserAgent=' . str_replace(' ', '', $emulateUserAgent) . ' swfUrl=' . $swfUrl . ' pageUrl=' . $pageUrl . ' ttl=' . $ttl . ' tos=' . $tos;
		return $this->_procFunc("pushStream", $params);
	}

	/*
	 * create HTTP live stream out of an existing H.264/AAC stream
	 */

	public function createHLSStream($localStreamNames, $targetFolder, $bandwidths, $keepAlive, $overwriteDestination, $staleRetentionCount, $createMasterPlaylist, $groupName, $playlistType, $playlistLength, $playlistName, $chunkLength, $chunkBaseName, $chunkOnIDR) {
		if (!isset($localStreamNames) || empty($localStreamNames)) {
			Throw new Exception('parameter localStreamNames required');
		}
		if (!isset($targetFolder) || empty($targetFolder)) {
			Throw new Exception('parameter targetFolder required');
		}
		if (!isset($bandwidths) || empty($bandwidths)) {
			$bandwidths = null;
		}
		if (!isset($keepAlive) || $keepAlive == '') {
			$keepAlive = 1;
		}
		if (!preg_match('/^[0,1]{1}$/', $keepAlive)) {
			Throw new Exception('parameter keepAlive invalid');
		}
		if (!isset($overwriteDestination) || empty($overwriteDestination)) {
			$overwriteDestination = 1;
		}
		if (!preg_match('/^[0,1]{1}$/', $overwriteDestination)) {
			Throw new Exception('parameter overwriteDestination invalid');
		}
		if (!isset($playlistLength) || empty($playlistLength)) {
			$playlistLength = 10;
		} else if (!preg_match('/^\d+$/', $playlistLength)) {
			Throw new Exception('parameter playlistLength invalid');
		}
		if (!isset($staleRetentionCount) || empty($staleRetentionCount)) {
			$staleRetentionCount = $playlistLength;
		} else if (!preg_match('/^\d+$/', $staleRetentionCount)) {
			Throw new Exception('parameter staleRetentionCount invalid');
		}
		if (!isset($createMasterPlaylist) || $createMasterPlaylist == '') {
			$createMasterPlaylist = 1;
		}
		if (!preg_match('/^[0,1]{1}$/', $createMasterPlaylist)) {
			Throw new Exception('parameter createMasterPlaylist invalid');
		}
		if (!isset($groupName) || empty($groupName)) {
			$groupName = '';
		}
		if (!isset($playlistType) || empty($playlistType)) {
			$playlistType = 'appending';
		}
		if (!preg_match('/^appending|rolling$/i', $playlistType)) {
			Throw new Exception('parameter playlistType invalid');
		}
		if (!isset($playlistName) || empty($playlistName)) {
			$playlistName = 'playlist.m3u8';
		}
		if (!isset($chunkLength) || empty($chunkLength)) {
			$chunkLength = 10;
		} else if (!preg_match('/^\d+$/', $chunkLength)) {
			Throw new Exception('parameter chunkLength invalid');
		}
		if (!isset($chunkBaseName) || empty($chunkBaseName)) {
			$chunkBaseName = 'segment';
		}
		if (!isset($chunkOnIDR) || $chunkOnIDR == '') {
			$chunkOnIDR = 1;
		}
		if (!preg_match('/^[0,1]{1}$/', $chunkOnIDR)) {
			Throw new Exception('parameter chunkOnIDR invalid');
		}
		$params = 'localStreamNames=' . str_replace(' ', '', $localStreamNames) . ' targetFolder=' . str_replace(' ', '', $targetFolder) . ' keepAlive=' . $keepAlive . ' overwriteDestination=' . $overwriteDestination . ' staleRetentionCount=' . $staleRetentionCount . ' createMasterPlaylist=' . $createMasterPlaylist . ' groupName=' . str_replace(' ', '', $groupName) . ' playlistType=' . $playlistType . ' playlistLength=' . $playlistLength . ' playlistName=' . str_replace(' ', '', $playlistName) . ' chunkLength=' . $chunkLength . ' chunkBaseName=' . str_replace(' ', '', $chunkBaseName) . ' chunkOnIDR=' . $chunkOnIDR;

		// Add bandwidths if available
		if (null != $bandwidths) {
			$params = $params . ' bandwidths=' . str_replace(' ', '', $bandwidths);
		}

		return $this->_procFunc("createHLSStream", $params);
	}

	/*
	 * Provides a detailed description of every active stream
	 */

	public function listStreams() {
		return $this->_procFunc("listStreams");
	}

	/*
	 * Terminate a specific stream
	 */

	public function shutdownStream($id, $permanently) {
		if (!isset($id) || empty($id)) {
			Throw new Exception('parameter id required');
		} else if (!preg_match('/^\d+$/', $id)) {
			Throw new Exception('parameter id invalid');
		}
		if (!isset($permanently) || $permanently == '') {
			$permanently = 1;
		}
		if (!preg_match('/^[0,1]{1}$/', $permanently)) {
			Throw new Exception('parameter permanently invalid');
		}
		$params = 'id=' . $id . ' permanently=' . $permanently;
		return $this->_procFunc("shutdownStream", $params);
	}

	/*
	 * Returns a list with all push/pull configurations
	 */

	public function listPullPushConfig() {
		return $this->_procFunc("listPullPushConfig");
	}

	/*
	 * Removes a pull/push configuration. It does NOT stop the corresponding stream
	 */

	public function removePullPushConfig($id, $hlsGroup, $removeHLSFiles) {
		if (!isset($id) || empty($id)) {
			Throw new Exception('parameter id required');
		} else if (!preg_match('/^\d+$/', $id)) {
			Throw new Exception('parameter id invalid');
		}
		if (!isset($hlsGroup) || empty($hlsGroup)) {
			$hlsGroup = '';
		}
		if (!isset($removeHLSFiles) || $removeHLSFiles == '') {
			$removeHLSFiles = 0;
		}
		if (!preg_match('/^[0,1]{1}$/', $removeHLSFiles)) {
			Throw new Exception('parameter removeHLSFiles invalid');
		}
		$params = 'id=' . $id . ' hlsGroup=' . str_replace(' ', '', $hlsGroup) . ' removeHLSFiles=' . $removeHLSFiles;
		return $this->_procFunc("removePullPushConfig", $params);
	}

	/*
	 * Returns the list of active connections
	 */

	public function listConnections() {
		return $this->_procFunc("listConnections");
	}

	/*
	 * Returns the limit of concurrent connections. This is the maximum number of connections this EMS instance will allow at one time
	 */

	public function getConnectionsCountLimit() {
		return $this->_procFunc("getConnectionsCountLimit");
	}

	/*
	 * This interface sets a limit on the number of concurrent connections the EMS will allow
	 */

	public function setConnectionsCountLimit($count) {
		if (!isset($count) || empty($count)) {
			Throw new Exception('parameter count required');
		} else if (!preg_match('/^\d+$/', $count)) {
			Throw new Exception('parameter count invalid');
		}
		$params = 'count=' . $count;
		return $this->_procFunc("setConnectionsCountLimit", $params);
	}

	/*
	 * Returns the list of available service
	 */

	public function listServices() {
		return $this->_procFunc("listServices");
	}

	/*
	 * Creates a new service
	 */

	public function createService($ip, $port, $protocol, $sslCert, $sslKey) {
		if (!isset($ip) || empty($ip)) {
			Throw new Exception('parameter ip required');
		} else if (!preg_match('/^[0-9]{1,3}[.][0-9]{1,3}[.][0-9]{1,3}[.][0-9]{1,3}$/i', $ip)) {
			Throw new Exception('parameter ip invalid');
		}
		if (!isset($port) || empty($port)) {
			Throw new Exception('parameter port required');
		} else if (!preg_match('/^\d+$/', $port)) {
			Throw new Exception('parameter port invalid');
		}
		if (!isset($protocol) || empty($protocol)) {
			Throw new Exception('parameter protocol required');
		}
		if (!isset($sslCert) || empty($sslCert)) {
			$sslCert = '';
		}
		if (!isset($sslKey) || empty($sslKey)) {
			$sslKey = '';
		}
		$params = 'ip=' . $ip . ' port=' . $port . ' protocol=' . $protocol . ' sslCert=' . $sslCert . ' sslKey=' . $sslKey;
		return $this->_procFunc("createService", $params);
	}

	/*
	 * Enable or disable a service
	 */

	public function enableService($id, $enable) {
		if (!isset($id) || empty($id)) {
			Throw new Exception('parameter id required');
		} else if (!preg_match('/^\d+$/', $id)) {
			Throw new Exception('parameter id invalid');
		}
		if (!isset($enable) || $enable == '') {
			Throw new Exception('parameter enable required');
		}
		if (!preg_match('/^[0,1]{1}$/', $enable)) {
			Throw new Exception('parameter enable invalid');
		}
		$params = 'id=' . $id . ' enable=' . $enable;
		return $this->_procFunc("enableService", $params);
	}

	/*
	 * Terminates a service
	 */

	public function shutdownService($id) {
		if (!isset($id) || empty($id)) {
			Throw new Exception('parameter id required');
		} else if (!preg_match('/^\d+$/', $id)) {
			Throw new Exception('parameter id invalid');
		}
		$params = 'id=' . $id;
		return $this->_procFunc("shutdownService", $params);
	}

	/*
	 * Will enable/disable RTMP authentication
	 */

	public function setAuthentication($enabled) {
		if (!isset($enabled) || $enabled == '') {
			Throw new Exception('parameter enabled required');
		}
		if (!preg_match('/^[0,1]{1}$/', $enabled)) {
			Throw new Exception('parameter enabled invalid');
		}
		$params = 'enabled=' . $enabled;
		return $this->_procFunc("setAuthentication", $params);
	}

	/*
	 * Returns the versions for framework and this application
	 */

	public function Version() {
		return $this->_procFunc("Version");
	}
}
