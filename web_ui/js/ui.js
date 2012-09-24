jQuery(document).ready(function(){
	// old state of the command list
	var oldCmd = '';
	// hide/show animation duration
	var duration = 400;
	// flag to indicate that this is an auto IP config
	var autoIp = false;

	// List of available commands
	var addStream = 'addStream';
	var removeStream = 'removeStream';
	var createHLS = 'createHLS';
	var sendMpegTs = 'sendMpegTs';
	var listStream = 'listStream';

	// Assign handle for flowplayer
	var flowPlayer = $f("videoContainer", "swf/flowplayer-3.2.11.swf");

	if (autoIp) {
		// Save the IP
		$('#ipAddress').val(document.domain);

		// Auto connect to server
		autoConnect();
	}

	function autoConnect() {
		var ip = getIp();

		$.ajax({
			type:'POST',
			url:'php/evoapi-uiproxy.php',
			data:'ip=' + ip,
			dataType:'json',
			async:true,
			error: function(json, status){
				showAjaxErr(status);
			},
			success:function(json){
				if(json.connected) {
					// Show the command list
					connStatus(false);

					// Retrieve the list of streams
					processListStream(true);
				} else {
					// Hide the command list
					connStatus(true);

					// Otherwise show an error
					showStatus(true, 'Could not connect to ' + ip + '!' + ((null == json.description)? '' : json.description));
				}
			}
		});
	}

	// Display error or success status messages
	function showStatus(isErr, msg) {
		var statMsg = '';

		// Create the status display
		if (isErr) {
			statMsg = '<div class="notice error"><span class="icon" data-icon="x"></span>' + msg + ' <a href="#close" class="icon close" data-icon="x"></a></div>';
		} else {
			statMsg = '<div class="notice success"><span class="icon" data-icon="C"></span>' + msg + ' <a href="#close" class="icon close" data-icon="x"></a></div>';
		}

		// Update the DIV container of the status
		$('#statusMessage').html(statMsg);

		// Rerun the html kick start script for newly created html tags
		doKickStart();
	}

	// Create detailed error reporting of AJAX error
	function showAjaxErr(err) {
		var errMsg = 'Could not load PHP script!';

		// Compose error message depending on ajax error
		switch (err) {
			case 'error':
				errMsg = 'Webserver is no longer accessible! <br /> Make sure that the webserver is running and has not crashed/shutdown.';

				break;
			case 'parsererror':
				errMsg = 'PHP is not installed on the webserver! <br /> Install it, restart the webserver and try again.';

				break;
			case 'timeout':
				errMsg = 'Webserver is taking too long to respond... <br /> There seems to be a connection issue, try again.';

				break;
			case 'abort':
				errMsg = 'Connection request was aborted!';

				break;
			default:

		}

		// Display the error
		showStatus(true, errMsg);
	}

	// Show messages depending on the type of command
	function setCmdMsgs(cmd, msg) {
		var notice = '';

		// Determine the type of command
		switch (cmd) {
			case removeStream:
				notice = '#remNotice';

				break;
			case createHLS:
				notice = '#hlsNotice';

				break;
			case sendMpegTs:
				notice = '#mpgNotice';

				break;
			default:
				break;
		}

		$(notice).html(msg);
	}

	// Enable or disable a command button
	function setCmdButton(cmd, isEnabled) {
		var button = '';

		// Determine the type of command
		switch (cmd) {
			case addStream:
				button = '#cmdAddButton';
				break;
			case removeStream:
				button = '#cmdRemButton';
				break;
			case createHLS:
				button = '#cmdHlsButton';
				break;
			case sendMpegTs:
				button = '#cmdSendMpgButton';
				break;
			default:
				break;
		}

		$(button).attr('disabled', !isEnabled);

		if (isEnabled) {
			// Remove the 'disabled' class
			if ($(button).hasClass('disabled')) $(button).removeClass('disabled');
		} else {
			// Add a 'disabled' class for each
			$(button + 'not(.disabled)').addClass('disabled');
		}

	}

	// Display or hides items depending on connection status
	function connStatus(isErr) {
		if (isErr) {
			$('#serverComandContainer').hide();
			$('#streamList').hide();
			$('#streamDetail').hide();
			$('#videoContainer').hide();
			$('#cmdAdd').hide();
			$('#cmdRemove').hide();
			$('#cmdHLS').hide();
			$('#cmdMpegSend').hide();
		} else {
			$('#serverComandContainer').show(duration);
			$('#streamList').show(duration);
		}
	}

	// Returns the IP address of EMS
	function getIp() {
		return $('#ipAddress').val();
	}

	// Returns the name of currently selected stream
	function getCurrentStream() {
		return $('#nameSrc').val();
	}

	// Returns the active server command
	function getCurrentCmd() {
		return $('#commandList').val();
	}

	// Checks the IP address of the EMS if valid
	function checkIp() {
		if (autoIp) return true;

		var ip = getIp();

		if(ip.toString().length > 0 && /^[0-9]{1,3}[.][0-9]{1,3}[.][0-9]{1,3}[.][0-9]{1,3}$/i.test(ip)) {
			return true;
		} else {
			// Considered as connection error
			connStatus(true);

			// Invalid IP
			showStatus(true, 'Invalid IP address! <br /> If EMS is on the local machine, try "127.0.0.1" instead.');

			return false;
		}
	}

	// Repopulate the list of streams
	function updateList(tbody) {
		// Create the HTML table with the list of streams
		var table = '<h6>Stream List</h6><div id="streamListDiv"><table id="streamListTable" class="striped sortable" cellspacing="0" cellpadding="0"><thead><tr><th>ID</th><th>Name</th><th>URI</th><th>Type</th></tr></thead><tbody>' + tbody + '</tbody></table></div>';

		$('#streamList').html(table);
	}

	// Change the UI's appearance based on the selected server command
	function processSelectedCmd(cmd, stream) {
		var msg = ''; // message to display
		var enable = false; // disabled button

		switch (cmd) {
			case 'none':
				break; // do nothing
			case addStream:
				// Display the Add stream options
				$('#cmdAdd').show(duration);
				enable = true;

				break;
			case createHLS:
				// Display HLS options

				if ('' == stream) {
					// If no stream is selected, show that info and disable the button
					msg = 'Select a stream from the list and populate the settings to create an HLS stream.';
				} else {
					msg = 'Create HLS from "' + stream + '" stream?';
					enable = true;
				}

				$('#cmdHLS').show(duration);
				break;
			case listStream:
				// No paramater command, process
				processListStream(false);
				return;
			case removeStream:
				// Display the Remove Stream options

				if ('' == stream) {
					// If no stream is selected, show that info and disable the button
					msg = 'Select a stream from the list to delete.';
				} else {
					msg = 'Remove the stream "' + stream + '"?';
					enable = true;
				}

				$('#cmdRemove').show(duration);
				break;
			case sendMpegTs:

				if ('' == stream) {
					// If no stream is selected, show that info and disable the button
					msg = 'Select a stream from the list to send as MPEG-TS packets.';
				} else {
					msg = 'Create MPEG-TS for "' + stream + '"?';
					enable = true;
				}

				$('#cmdMpegSend').show(duration);

				break;
			default:
				break; // do nothing
		}

		setCmdMsgs(cmd, msg)
		setCmdButton(cmd, enable);
	}

	// Handler for listStream command
	function processListStream(ignoreError) {
		// Check for the validity of IP address
		if (checkIp()) {
			// Process the AJAX request and response
			$.ajax({
				type:'POST',
				url:'php/evoapi-uiproxy.php',
				data:'ip=' + getIp() + '&cmd='+ listStream,
				dataType:'json',
				async:true,
				error: function(json, status){
					showAjaxErr(status);
				},
				success:function(json){
					if(json.success){
						var tbody = '';

						// Process the response
						$.each(json.data, function(index, item) {
							if ((item.uri).indexOf('http://') == -1) {
								tbody += '<tr><td>' + item.id + '</td><td>' + item.name + '</td><td>' + item.uri + '</td><td>' + item.type + '</td></tr>'
							} else {
								// String 'http://' found, add a link.
								tbody += '<tr><td>' + item.id + '</td><td>' + item.name + '</td><td><a href="' + item.uri + '" target="_blank">' + item.uri + '</a></td><td>' + item.type + '</td></tr>'
							}
						});

						// In case we don't have any table content
						if ('' == tbody) {
							tbody = '<tr><td>-</td><td>-</td><td>No stream available...</td><td>-</td></tr>';

							// Hide the stream details and video
							$('#streamDetail').hide();
							$('#videoContainer').hide();
						}

						// Populate contents of table
						updateList(tbody);

						if (!ignoreError) {
							// Display the success message
							showStatus(false, 'Streams list is now updated.');
						}
					} else {
						if (!ignoreError) {
							// Otherwise show a failed message
							showStatus(true, 'Error updating list! ' + ((null == json.description)? '' : json.description));
						}
					}

					if (ignoreError) {
						// Since we updated the stream list table, we still need this
						doKickStart();
					}
				}
			});
		}
	}

	// Play the selected stream
	function playVideo(stream, emsIP) {
		$f("videoContainer", "swf/flowplayer-3.2.11.swf", {
			plugins: {
				controls: null,
				rtmp: {
					url: 'flowplayer.rtmp-3.2.10.swf',
					netConnectionUrl: 'rtmp://' + emsIP + '/live'
				}
			},
			play: null,
			clip: {
				url: stream,
				live: true,
				provider: 'rtmp'
			}
		});
	}

	// Store the last used command
	$('#commandList').focus(function(){
		oldCmd = getCurrentCmd();
	});
	// Process the selection of server commands
	$('#commandList').change(function(){
		// Hide the previous command options/details
		switch (oldCmd) {
			case 'addStream':
				$('#cmdAdd').hide();
				break;
			case 'removeStream':
				$('#cmdRemove').hide();
				break;
			case 'createHLS':
				$('#cmdHLS').hide();
				break;
			case 'sendMpegTs':
				$('#cmdMpegSend').hide();
				break;
			default:
				break;
		}

		// Update the container for old value
		$('#commandList').trigger('focus');

		// Process the command selected
		var cmd = getCurrentCmd();
		var sName = getCurrentStream();

		processSelectedCmd(cmd, sName);

		return false;
	});

	// Add a stream to the server
	$('#cmdAddButton').live('click', function(){
		var stream = [];
		var sName = $('#streamName').val();
		var sSrc = $('#streamSource').val();
		var sForceTcp = ($('#forceTcp').is(":checked")) ? '1' : '0';
		var ip = getIp();

		// Sanity checks
		if(('' != sName) && ('' != sSrc)){
			stream.push('name=' + sName);
			stream.push('source=' + sSrc);
			stream.push('forceTcp=' + sForceTcp);
		} else {
			showStatus(true, 'Enter a valid stream name and source!');
			return false;
		}

		if (checkIp()) {

			$.ajax({
				type:'POST',
				url:'php/evoapi-uiproxy.php',
				data:'ip=' + ip + '&cmd=addStream&' + stream.join("&"),
				dataType:'json',
				async: true,
				error: function(json, status){
					showAjaxErr(status);
				},
				success:function(json){
					if(json.success) {
						showStatus(false, sName + ' was added successfully.');

						// Now send another request to update the stream list
						processListStream(true);
					} else {
						showStatus(true, 'Failed adding stream: "' + sName + '"! ' + ((null == json.description)? '' : json.description));
					}
				}
			});
		}

		return false;
	});

	// Remove a stream from the server
	$('#cmdRemButton').live('click', function(){
		var ip = getIp();
		var sId = $('#idSrc').val();
		var sName = getCurrentStream();

		// Sanity checks
		if('' == sName){
			showStatus(true, 'Click on a stream from the list!');
			return false;
		}

		if (checkIp()){
			// Process the AJAX request and response
			$.ajax({
				type:'POST',
				url:'php/evoapi-uiproxy.php',
				data:'ip=' + ip + '&cmd=removeStream&id=' + sId,
				dataType:'json',
				async:true,
				error: function(json, status){
					showAjaxErr(status);
				},
				success:function(json){
					if(json.success) {
						showStatus(false, sName + ' was removed successfully.');

						// Now send another request to update the stream list
						processListStream(true);
					} else {
						showStatus(true, 'Failed removing stream: "' + sName + '"! ' + ((null == json.description)? '' : json.description));
					}
				}
			});
		}

		return false;
	});

	// Create an HLS stream from the list
	$('#cmdHlsButton').live('click', function(){
		var ip = getIp();
		var sName = getCurrentStream();
		var folder = $('#folderHls').val();
		var group = $('#gNameHls').val();
		var cLen = $('#chunkLenHls').val();

		// Sanity checks
		if('' == sName){
			showStatus(true, 'Click on a stream from the list!');
			return false;
		}

		if (checkIp()){
			// Process the AJAX request and response
			$.ajax({
				type:'POST',
				url:'php/evoapi-uiproxy.php',
				data:'ip=' + ip + '&cmd=createHLS&name=' + sName + '&group=' + group + '&folder=' + folder + '&chunkLength=' + cLen,
				dataType:'json',
				async:true,
				error: function(json, status){
					showAjaxErr(status);
				},
				success:function(json){
					if(json.success) {
						showStatus(false, 'HLS stream for "' + sName + '" was created successfully.');

						// Now send another request to update the stream lists
						processListStream(true);
					} else {
						showStatus(true, 'Failed adding HLS stream for "' + sName +'"! ' + ((null == json.description)? '' : json.description));
					}
				}
			});
		}

		return false;
	});

	// Push an MPEG-TS stream from the list
	$('#cmdSendMpgButton').live('click', function(){
		var ip = getIp();
		var sName = getCurrentStream();
		var target = $('#targetMpg').val();
		var port = $('#targetPortMpg').val();

		if ('' == port) {
			port = '10000';
		}

		target += ':' + port;

		// Sanity checks
		if('' == sName){
			showStatus(true, 'Click on a stream from the list!');
			return false;
		}

		if (checkIp()){
			// Process the AJAX request and response
			$.ajax({
				type:'POST',
				url:'php/evoapi-uiproxy.php',
				data:'ip=' + ip + '&cmd=sendMpegTs&name=' + sName + '&target=' + target,
				dataType:'json',
				async:true,
				error: function(json, status){
					showAjaxErr(status);
				},
				success:function(json){
					if(json.success) {
						showStatus(false, 'MPEG-TS packets of "' + sName +'" being sent to ' + target + '. ' + ((null == json.description)? '' : json.description));

						// Now send another request to update the stream lists
						processListStream(true);
					} else {
						showStatus(true, 'Failed adding HLS stream for "' + sName +'"! ' + ((null == json.description)? '' : json.description));
					}
				}
			});
		}

		return false;
	});

	// Stop all MPEG-TS streams
	$('#cmdStopMpgButton').live('click', function(){
		var ip = getIp();

		// Sanity check
		if (checkIp()){
			// Process the AJAX request and response
			$.ajax({
				type:'POST',
				url:'php/evoapi-uiproxy.php',
				data:'ip=' + ip + '&cmd=stopMpegTs&stop=mpegtsudp',
				dataType:'json',
				async:true,
				error: function(json, status){
					showAjaxErr(status);
				},
				success:function(json){
					if(json.success) {
						showStatus(false, 'Stopped MPEG-TS. ' + ((null == json.description)? '' : json.description));

						// Now send another request to update the stream lists
						processListStream(true);
					} else {
						showStatus(true, 'Failed stopping MPEG-TS! ' + ((null == json.description)? '' : json.description));
					}
				}
			});
		}

		return false;
	});

	// Check the connection with the server
	$('#checkServer').live('click', function(){
		var ip = getIp();

		// Validate the IP address first
		if (checkIp()){
			// Process the AJAX request and response
			$.ajax({
				type:'POST',
				url:'php/evoapi-uiproxy.php',
				data:'ip=' + ip,
				dataType:'json',
				async:true,
				error: function(json, status){
					showAjaxErr(status);
				},
				success:function(json){
					if(json.connected) {
						// Show the command list
						connStatus(false);

						// Retrieve the list of streams
						processListStream(true);

						// Display the success message
						showStatus(false, 'Server connected.');
					} else {
						// Hide the command list
						connStatus(true);

						// Otherwise show an error
						showStatus(true, 'Could not connect to ' + ip + '!' + ((null == json.description)? '' : json.description));
					}
				}
			});
		}

		return false;
	});

	// Process the selected rows
	$('#streamListTable tbody tr').live('click', function(e){
		var values = $(this).children('td').map(function() {
			return this.innerHTML;
		}).toArray();

		var ip = getIp();

		// For now, only process pull streams, ignore the rest
		if ('pull' == values[3]) {
			$f(0).stop(); // stop???

			// Only update the details if this is a pull stream
			$('#nameSrc').val(values[1]);
			$('#srcSrc').val(values[2]);
			$('#rtmpSrc').val('rtmp://' + ip + '/live/' + values[1]);
			$('#rtspSrc').val('rtsp://' + ip + ':5544/' + values[1]);

			// Include the hidden input
			$('#idSrc').val(values[0]);

			// Display the details
			if(!$('#streamDetail').is(':visible')) {
				$('#streamDetail').show(duration);
			}

			// Display the video screen
			if(!$('#videoContainer').is(':visible')) {
				$('#videoContainer').show(duration);
			}


			// Determine the active server command
			var cmd = getCurrentCmd();
			switch (cmd) {
				case removeStream:
					setCmdMsgs(cmd, 'Remove the stream "' + values[1] + '"?');
					setCmdButton(cmd, true);
					break;
				case createHLS:
					setCmdMsgs(cmd, 'Create HLS stream for "' + values[1] + '"?');
					setCmdButton(cmd, true);
					break;
				case sendMpegTs:
					setCmdMsgs(cmd, 'Create MPEG-TS for "' + values[1] + '"?');
					setCmdButton(cmd, true);
					break;
				default:
					break;
			}
		}
	});

	// Play the selected video
	$('#playVid').live('click', function(e){
		var ip = getIp();

		// Sanity check
		if (checkIp()) {
			var name = getCurrentStream();

			if (name.length > 0) {
				playVideo(name, ip);
			} else {
				alert('Invalid target video. Refresh page.');
			}
		}
	});

	// Handler for enter key
	$('#ipAddress').live('keypress', function(e) {
		if (e.which == 13) {
			// Connect!
			$('#checkServer').trigger('click');
		}
	});

	// Download the streams XML file
	$('#xmlFile').live('click', function(e) {
		window.location.href = 'php/stream.php';
	});
});

// Disables all buttons to avoid user sending another request while a previous request is on-going
function serverBusy(isTrue) {
	var buttons = ['#commandList', '#cmdAddButton', '#cmdRemButton', '#cmdHlsButton', '#cmdSendMpgButton', '#cmdStopMpgButton'];

	if (isTrue) {
		// Loop through the buttons and disable it
		$.each(buttons, function(index, button) {
			$(button).attr('disabled', true);
		});

		// Change the cursor to "busy""
		$('body').css('cursor', 'wait');
	} else {
		// Enable it back
		$.each(buttons, function(index, button) {
			$(button).attr('disabled', false);
		});

		// Revert the cursor
		$('body').css('cursor', 'auto');
	}
}

jQuery(document).ajaxStart(function(){
	// Disable the major buttons/elements
	serverBusy(true);
});

jQuery(document).ajaxStop(function(){
	// Enable back the buttons
	serverBusy(false);
});
