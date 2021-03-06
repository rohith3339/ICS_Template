source(output(
		LBLNI as string,
		ERNAM as string,
		ERDAT as date,
		AEDAT as date,
		LWERT as decimal(11,2),
		TXZ01 as string,
		NETWR as decimal(11,2),
		BUDAT as date,
		LOEKZ as string,
		WAERS as string,
		EBELN as string,
		EBELP as string
	),
	allowSchemaDrift: true,
	validateSchema: false,
	ignoreNoFilesFound: false,
	batchSize: 5000,
	isolationLevel: 'READ_UNCOMMITTED',
	format: 'table') ~> ESSR
ESSR select(mapColumn(
		{SES No} = LBLNI,
		{SES Value} = LWERT,
		{SES Net Value} = NETWR,
		{SES Desc} = TXZ01,
		{SES Created Date} = ERDAT,
		{SES Changed Date} = AEDAT,
		{SES Posting Date} = BUDAT,
		{SES Created By} = ERNAM,
		{SES Deletion Ind} = LOEKZ,
		{SES Currency} = WAERS
	),
	skipDuplicateMapInputs: true,
	skipDuplicateMapOutputs: true) ~> SelectESSR
SelectESSR select(mapColumn(
		{SES No},
		{SES Value},
		{SES Net Value},
		{SES Desc},
		{SES Created Date},
		{SES Changed Date},
		{SES Posting Date},
		{SES Created By},
		{SES Deletion Ind},
		{SES Currency},
		{SES CKey} = {SES No}
	),
	skipDuplicateMapInputs: false,
	skipDuplicateMapOutputs: true) ~> SESCKey
SESCKey keyGenerate(output({SES SKey} as long),
	startAt: 1L) ~> SESSKey
SESSKey sink(allowSchemaDrift: true,
	validateSchema: false,
	deletable:false,
	insertable:true,
	updateable:false,
	upsertable:false,
	recreate:true,
	format: 'table',
	batchSize: 5000,
	postSQLs:['insert into [dbo].[F_ServiceEntrySheet]([SES CKey],[SES SKey]) values(\'-1\',-1)'],
	skipDuplicateMapInputs: true,
	skipDuplicateMapOutputs: true,
	errorHandlingOption: 'stopOnFirstError') ~> FPURCHASESESSINK