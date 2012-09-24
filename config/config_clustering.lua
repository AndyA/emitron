configuration=
{
	daemon=false,
	instancesCount=-1,
	pathSeparator="/",
	logAppenders=
	{
		{
			name="console appender",
			type="coloredConsole",
			level=6
		},
		{
			name="file appender",
			type="file",
			level=6,
			fileName="../logs/evostream",
			newLineCharacters="\n",
			fileHistorySize=10,
			fileLength=1024*1024,
			singleLine=true
		},
	},

	applications=
	{
		rootDirectory="applications",
		{
			name="evostreamms",
			description="EVOSTREAM MEDIA SERVER",
			protocol="dynamiclinklibrary",
			default=true,
			pushPullPersistenceFile="../config/pushPullSetup.xml",
			authPersistenceFile="../config/auth.xml",
			connectionsLimitPersistenceFile="../config/connlimits.xml",
			bandwidthLimitPersistenceFile="../config/bandwidthlimits.xml",
			externSeekGenerator=false,
			mediaFolder="../media",
			streamsExpireTimer=10,
			rtcpDetectionInterval=15,
			hasStreamAliases=false,
			aliases=
			{
				"er",
				"live",
				"vod",
			},
			acceptors=
			{
				{
					ip="0.0.0.0",
					port=1935,
					protocol="inboundRtmp",
				},
				{
					ip="127.0.0.1",
					port=1936,
					protocol="inboundRtmp",
					clustering=true
				},
				{
					ip="127.0.0.1",
					port=1112,
					protocol="inboundJsonCli",
					useLengthPadding=true
				},
				{
					ip="127.0.0.1",
					port=1113,
					protocol="inboundBinVariant",
					clustering=true
				},
				{
					ip="0.0.0.0",
					port=7777,
					protocol="inboundHttpJsonCli"
				},
				{
					ip="0.0.0.0",
					port=5544,
					protocol="inboundRtsp"
				},
			},
			validateHandshake=false,
			authentication=
			{
				rtmp={
					type="adobe",
					encoderAgents=
					{
						"FMLE/3.0 (compatible; FMSc/1.0)",
						"Wirecast/FM 1.0 (compatible; FMSc/1.0)",
						"EvoStream Media Server (www.evostream.com)"
					},
					usersFile="../config/users.lua"
				},
				rtsp={
					usersFile="../config/users.lua"
				}
			},
		},
	}
}

