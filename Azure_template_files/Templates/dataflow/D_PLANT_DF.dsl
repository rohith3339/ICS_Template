source(output(
		NAME1 as string,
		WERKS as string,
		LOAD_DATETIME as timestamp
	),
	allowSchemaDrift: true,
	validateSchema: false,
	ignoreNoFilesFound: false,
	batchSize: 5000,
	isolationLevel: 'READ_UNCOMMITTED',
	format: 'table') ~> T001W
T001W select(mapColumn(
		{Plant Name} = NAME1,
		{Plant No} = WERKS
	),
	skipDuplicateMapInputs: false,
	skipDuplicateMapOutputs: true) ~> RenameColumns
RenameColumns select(mapColumn(
		{Plant Name},
		{Plant No},
		{Plant CKey} = {Plant No}
	),
	skipDuplicateMapInputs: false,
	skipDuplicateMapOutputs: true) ~> PlantCKey
PlantCKey keyGenerate(output({Plant SKey} as long),
	startAt: 1L) ~> PlantSKey
PlantSKey sink(allowSchemaDrift: true,
	validateSchema: false,
	deletable:false,
	insertable:true,
	updateable:false,
	upsertable:false,
	recreate:true,
	format: 'table',
	batchSize: 5000,
	postSQLs:['insert into [dbo].[D_PLANT]([Plant CKey],[Plant SKey]) values(\'-1\',-1)'],
	skipDuplicateMapInputs: true,
	skipDuplicateMapOutputs: true,
	errorHandlingOption: 'stopOnFirstError') ~> PlantSink