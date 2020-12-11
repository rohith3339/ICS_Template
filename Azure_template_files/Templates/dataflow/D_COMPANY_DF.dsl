source(output(
		BUKRS as string,
		BUTXT as string,
		LOAD_DATETIME as timestamp
	),
	allowSchemaDrift: true,
	validateSchema: false,
	ignoreNoFilesFound: false,
	batchSize: 5000,
	isolationLevel: 'READ_UNCOMMITTED',
	format: 'table') ~> T001
T001 select(mapColumn(
		{COMPANY CODE} = BUKRS,
		{COMPANY NAME} = BUTXT
	),
	skipDuplicateMapInputs: false,
	skipDuplicateMapOutputs: true) ~> RenameColumns
RenameColumns select(mapColumn(
		{Company Code} = {COMPANY CODE},
		{Company Name} = {COMPANY NAME},
		{Company CKey} = {COMPANY CODE}
	),
	skipDuplicateMapInputs: false,
	skipDuplicateMapOutputs: true) ~> CompanyCKey
CompanyCKey keyGenerate(output({Company SKey} as long),
	startAt: 1L) ~> CompanySKey
CompanySKey sink(allowSchemaDrift: true,
	validateSchema: false,
	deletable:false,
	insertable:true,
	updateable:false,
	upsertable:false,
	recreate:true,
	format: 'table',
	batchSize: 5000,
	postSQLs:['insert into [dbo].[D_Company]([Company CKey],[Company SKey]) values(\'-1\',-1)'],
	skipDuplicateMapInputs: true,
	skipDuplicateMapOutputs: true,
	errorHandlingOption: 'stopOnFirstError') ~> DCompany