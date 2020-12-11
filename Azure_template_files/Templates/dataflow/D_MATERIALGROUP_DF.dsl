source(output(
		MATKL as string,
		WGBEZ60 as string,
		LOAD_DATETIME as timestamp
	),
	allowSchemaDrift: true,
	validateSchema: false,
	ignoreNoFilesFound: false,
	batchSize: 5000,
	isolationLevel: 'READ_UNCOMMITTED',
	format: 'table') ~> T023T
T023T select(mapColumn(
		{Material Group No} = MATKL,
		{Material Group Desc} = WGBEZ60
	),
	skipDuplicateMapInputs: false,
	skipDuplicateMapOutputs: true) ~> RenameColumns
RenameColumns select(mapColumn(
		{Material Group No},
		{Material Group Desc},
		{Material Group CKey} = {Material Group No}
	),
	skipDuplicateMapInputs: false,
	skipDuplicateMapOutputs: true) ~> MaterialGroupCKey
MaterialGroupCKey keyGenerate(output({Material Group SKey} as long),
	startAt: 1L) ~> MaterialGroupSKey
MaterialGroupSKey sink(allowSchemaDrift: true,
	validateSchema: false,
	deletable:false,
	insertable:true,
	updateable:false,
	upsertable:false,
	recreate:true,
	format: 'table',
	batchSize: 5000,
	postSQLs:['insert into [dbo].[D_MATERIALGROUP]([Material Group CKey],[Material Group SKey]) values(\'-1\',-1)'],
	skipDuplicateMapInputs: true,
	skipDuplicateMapOutputs: true,
	errorHandlingOption: 'stopOnFirstError') ~> DimMaterialGroup