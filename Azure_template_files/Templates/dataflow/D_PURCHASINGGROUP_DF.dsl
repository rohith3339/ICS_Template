source(output(
		EKGRP as string,
		EKNAM as string,
		LOAD_DATETIME as timestamp
	),
	allowSchemaDrift: true,
	validateSchema: false,
	ignoreNoFilesFound: false,
	batchSize: 5000,
	isolationLevel: 'READ_UNCOMMITTED',
	format: 'table') ~> T024
T024 select(mapColumn(
		{Purchasing Group No} = EKGRP,
		{Purchasing Group Name} = EKNAM
	),
	skipDuplicateMapInputs: false,
	skipDuplicateMapOutputs: true) ~> RenameColumns
RenameColumns select(mapColumn(
		{Purchasing Group No},
		{Purchasing Group Name},
		{Purchasing Group CKey} = {Purchasing Group No}
	),
	skipDuplicateMapInputs: false,
	skipDuplicateMapOutputs: true) ~> PurchasingGroupCKey
PurchasingGroupCKey keyGenerate(output({Purchasing Group SKey} as long),
	startAt: 1L) ~> PurchasingGroupSKey
PurchasingGroupSKey sink(allowSchemaDrift: true,
	validateSchema: false,
	deletable:false,
	insertable:true,
	updateable:false,
	upsertable:false,
	recreate:true,
	format: 'table',
	batchSize: 5000,
	postSQLs:['insert into [dbo].[D_PURCHASINGGROUP]([Purchasing Group CKey],[Purchasing Group SKey]) values(\'-1\',-1)'],
	skipDuplicateMapInputs: true,
	skipDuplicateMapOutputs: true,
	errorHandlingOption: 'stopOnFirstError') ~> PurchasingGroupSink