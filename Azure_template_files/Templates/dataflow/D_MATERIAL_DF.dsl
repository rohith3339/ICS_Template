source(output(
		BISMT as string,
		MATKL as string,
		MATNR as string,
		MEINS as string,
		MTART as string,
		RAUBE as string,
		LOAD_DATETIME as timestamp
	),
	allowSchemaDrift: true,
	validateSchema: false,
	ignoreNoFilesFound: false,
	batchSize: 5000,
	isolationLevel: 'READ_UNCOMMITTED',
	format: 'table') ~> MARA
source(output(
		MAKTX as string,
		MATNR as string,
		LOAD_DATETIME as timestamp
	),
	allowSchemaDrift: true,
	validateSchema: false,
	ignoreNoFilesFound: false,
	batchSize: 5000,
	isolationLevel: 'READ_UNCOMMITTED',
	format: 'table') ~> MAKT
MARA, MAKT join(MARA@MATNR == MAKT@MATNR,
	joinType:'inner',
	broadcast: 'auto')~> MARAMAKTJN
MARAMAKTJN select(mapColumn(
		{Material No} = MARA@MATNR,
		{Material Desc} = MAKTX,
		{Material CKey} = MARA@MATNR
	),
	skipDuplicateMapInputs: false,
	skipDuplicateMapOutputs: false) ~> ColumnsSelect
ColumnsSelect derive({Material No} = ltrim({Material No}, '0'),
		{Material CKey} = ltrim({Material CKey}, '0')) ~> TrimLeadingZeros
TrimLeadingZeros keyGenerate(output({Material SKey} as long),
	startAt: 1L) ~> MaterialSKey
MaterialSKey sink(allowSchemaDrift: true,
	validateSchema: false,
	deletable:false,
	insertable:true,
	updateable:false,
	upsertable:false,
	recreate:true,
	format: 'table',
	batchSize: 5000,
	postSQLs:['insert into [dbo].[D_Material]([Material CKey],[Material SKey]) values(\'-1\',-1)'],
	skipDuplicateMapInputs: true,
	skipDuplicateMapOutputs: true,
	errorHandlingOption: 'stopOnFirstError') ~> MaterialSink