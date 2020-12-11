source(output(
		LAND1 as string,
		LIFNR as string,
		NAME1 as string,
		ORT01 as string,
		LOAD_DATETIME as timestamp
	),
	allowSchemaDrift: true,
	validateSchema: false,
	ignoreNoFilesFound: false,
	batchSize: 5000,
	isolationLevel: 'READ_UNCOMMITTED',
	format: 'table') ~> LFA1
LFA1 select(mapColumn(
		{Vendor Country} = LAND1,
		{Vendor No} = LIFNR,
		{Vendor Name} = NAME1,
		{Vendor City} = ORT01
	),
	skipDuplicateMapInputs: true,
	skipDuplicateMapOutputs: true) ~> SelectRenameColumns
SelectRenameColumns derive({Vendor No} = ltrim({Vendor No}, '0'),
		{Vendor CKEY} = ltrim({Vendor No}, '0')) ~> TrimLeadingZerosGenCKEY
TrimLeadingZerosGenCKEY keyGenerate(output({Vendor SKey} as long),
	startAt: 1L) ~> VendorSKey
VendorSKey sink(allowSchemaDrift: true,
	validateSchema: false,
	deletable:false,
	insertable:true,
	updateable:false,
	upsertable:false,
	recreate:true,
	format: 'table',
	batchSize: 5000,
	postSQLs:['insert into [dbo].[D_VENDOR]([Vendor CKey],[Vendor SKey]) values(\'-1\',-1)'],
	skipDuplicateMapInputs: true,
	skipDuplicateMapOutputs: true,
	errorHandlingOption: 'stopOnFirstError') ~> LoadVendor