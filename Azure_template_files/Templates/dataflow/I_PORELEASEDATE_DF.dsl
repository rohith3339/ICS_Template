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
	format: 'table') ~> CDHDR
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
	isolationLevel: 'READ_UNCOMMITTED',
	format: 'table') ~> CDPOS
CDPOS filter(FNAME=='FRGKE'&&TABNAME=='EKKO'&&CHNGIND=='U'&&VALUE_NEW=='3') ~> CDPOSDataFilter
CDHDR, CDPOSDataFilter join(CDHDR@CHANGENR == CDPOS@CHANGENR
	&& CDHDR@OBJECTCLAS == CDPOS@OBJECTCLAS
	&& CDHDR@OBJECTID == CDPOS@OBJECTID,
	joinType:'inner',
	broadcast: 'auto')~> JoinCDHDRCDPOS
JoinCDHDRCDPOS select(mapColumn(
		{PO No} = CDHDR@OBJECTID,
		{PO Release Date} = UDATE
	),
	skipDuplicateMapInputs: true,
	skipDuplicateMapOutputs: true) ~> RequiredColumns
RequiredColumns aggregate(groupBy({PO No}),
	{PO Release Date} = max({PO Release Date})) ~> Aggregate1
Aggregate1 sink(input(
		{PO No} as string,
		{PO Release Date} as date,
		SKEY as long
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
	errorHandlingOption: 'stopOnFirstError') ~> IPORELEASEDATESINK