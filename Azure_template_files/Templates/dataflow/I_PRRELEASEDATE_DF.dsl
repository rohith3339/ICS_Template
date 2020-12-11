source(output(
		CHANGENR as string,
		OBJECTCLAS as string,
		OBJECTID as string,
		UDATE as date,
		USERNAME as string
	),
	allowSchemaDrift: true,
	validateSchema: false,
	ignoreNoFilesFound: false,
	batchSize: 5000,
	isolationLevel: 'READ_UNCOMMITTED',
	format: 'table') ~> CDHDRPROC
source(output(
		CHANGENR as string,
		CHNGIND as string,
		OBJECTCLAS as string,
		OBJECTID as string,
		TABKEY as string,
		TABNAME as string,
		VALUE_NEW as string,
		FNAME as string
	),
	allowSchemaDrift: true,
	validateSchema: false,
	ignoreNoFilesFound: false,
	batchSize: 5000,
	isolationLevel: 'READ_UNCOMMITTED',
	format: 'table') ~> CDPOSPROC
CDHDRPROC, CDPOSPROC join(CDHDRPROC@CHANGENR == CDPOSPROC@CHANGENR
	&& CDHDRPROC@OBJECTID == CDPOSPROC@OBJECTID
	&& CDHDRPROC@OBJECTCLAS == CDPOSPROC@OBJECTCLAS,
	joinType:'inner',
	broadcast: 'auto')~> CDHDRPOSJN
CDHDRPOSJN filter(CDHDRPROC@OBJECTCLAS =='BANF' && VALUE_NEW == "2") ~> FilterVALUENEWOBJECTCLASS
FilterVALUENEWOBJECTCLASS select(mapColumn(
		{PR No} = CDHDRPROC@OBJECTID,
		{PR Release Date} = UDATE,
		{PR Ln} = TABKEY
	),
	skipDuplicateMapInputs: true,
	skipDuplicateMapOutputs: true) ~> SelectRenameColumns
SelectRenameColumns aggregate(groupBy({PR No},
		{PR Ln}),
	{PR Release Date} = max({PR Release Date})) ~> MaxUDATE
MaxUDATE derive({PR Ln} = substring({PR Ln}, 14, 5)) ~> ExtractPRLn
ExtractPRLn derive({PR No} = ltrim({PR No},'0'),
		{PR Ln} = ltrim({PR Ln},'0')) ~> TrimLeadingZeros
TrimLeadingZeros sink(input(
		{PR No} as string,
		{PR Ln} as string,
		{PR Release Date} as date
	),
	allowSchemaDrift: true,
	validateSchema: false,
	deletable:false,
	insertable:true,
	updateable:false,
	upsertable:false,
	recreate:true,
	format: 'table',
	batchSize: 5000,
	skipDuplicateMapInputs: true,
	skipDuplicateMapOutputs: true,
	errorHandlingOption: 'stopOnFirstError') ~> LoadtoIPRReleaseDate