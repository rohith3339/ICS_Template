source(output(
		LGOBE as string,
		LGORT as string,
		WERKS as string,
		LOAD_DATETIME as timestamp
	),
	allowSchemaDrift: true,
	validateSchema: false,
	ignoreNoFilesFound: false,
	batchSize: 5000,
	isolationLevel: 'READ_UNCOMMITTED',
	format: 'table') ~> T001L
T001L select(mapColumn(
		{Storage Description} = LGOBE,
		{Storage Location} = LGORT,
		{Plant No} = WERKS
	),
	skipDuplicateMapInputs: false,
	skipDuplicateMapOutputs: true) ~> RenameColumns
Concatenation keyGenerate(output({Storage Location SKey} as long),
	startAt: 1L) ~> StorageLocationSKey
RenameColumns derive({Storage Location Key} = concat(ltrim({Storage Location},'0'), ltrim({Plant No}, '0')),
		{Storage Location CKey} = concat(ltrim({Storage Location},'0'), ltrim({Plant No}, '0'))) ~> Concatenation
StorageLocationSKey sink(allowSchemaDrift: true,
	validateSchema: false,
	deletable:false,
	insertable:true,
	updateable:false,
	upsertable:false,
	recreate:true,
	format: 'table',
	batchSize: 5000,
	postSQLs:['insert into [dbo].[D_STORAGELOCATION]([Storage Location CKey],[Storage Location SKey]) values(\'-1\',-1)'],
	skipDuplicateMapInputs: true,
	skipDuplicateMapOutputs: true,
	errorHandlingOption: 'stopOnFirstError') ~> StorageLocationSink