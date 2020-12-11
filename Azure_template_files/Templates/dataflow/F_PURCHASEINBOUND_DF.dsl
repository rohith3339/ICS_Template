source(output(
		ARKTX as string,
		LFIMG as decimal(13,3),
		MATKL as string,
		MATNR as string,
		NETWR as decimal(15,2),
		POSNR as integer,
		VBELN as string,
		VGBEL as string,
		VGPOS as integer
	),
	allowSchemaDrift: true,
	validateSchema: false,
	ignoreNoFilesFound: false,
	batchSize: 5000,
	isolationLevel: 'READ_UNCOMMITTED',
	format: 'table') ~> LIPS
source(output(
		BLDAT as date,
		BOLNR as string,
		EXNUM as string,
		LFDAT as date,
		SPE_LOEKZ as string,
		TDDAT as date,
		VBELN as string,
		WERKS as string
	),
	allowSchemaDrift: true,
	validateSchema: false,
	ignoreNoFilesFound: false,
	batchSize: 5000,
	isolationLevel: 'READ_UNCOMMITTED',
	format: 'table') ~> LIKP
source(output(
		EXNUM as string,
		EXPVZ as string
	),
	allowSchemaDrift: true,
	validateSchema: false,
	ignoreNoFilesFound: false,
	inferDriftedColumnTypes: true,
	batchSize: 5000,
	isolationLevel: 'READ_UNCOMMITTED',
	format: 'table') ~> EIKP
source(output(
		{PO No} as string,
		{PO Release Date} as date,
		SKEY as long
	),
	allowSchemaDrift: true,
	validateSchema: false,
	ignoreNoFilesFound: false,
	batchSize: 5000,
	isolationLevel: 'READ_UNCOMMITTED',
	format: 'table') ~> PORELEASEDATE
LIPS, LIKP join(ltrim(LIPS@VBELN,'0') == ltrim(LIKP@VBELN,'0'),
	joinType:'left',
	broadcast: 'auto')~> LIKPJN
LIKPJN, EIKP join(ltrim(LIKP@EXNUM,'0') == ltrim(EIKP@EXNUM,'0'),
	joinType:'left',
	broadcast: 'auto')~> EIKPJN
EIKPJN, PORELEASEDATE join(VGBEL == {PO No},
	joinType:'left',
	broadcast: 'auto')~> PORELEASEDDATEJN
Transformations select(mapColumn(
		{Inbound No} = VBELN,
		{Inbound Ln} = POSNR,
		{Inbound Qty} = LFIMG,
		{Inbound Value} = NETWR,
		{Inbound Desc} = ARKTX,
		{Inbound Document Date} = BLDAT,
		{Inbound Trnsplning Date} = TDDAT,
		{Inbound Delivery Date} = LFDAT,
		{Inbound Transport Mode} = EXPVZ,
		{Inbound Bill of Lading} = BOLNR,
		{Inbound Deletion Ind} = SPE_LOEKZ,
		{PO Release Date},
		{Vendor Lead Time},
		{Inbound CKey}
	),
	skipDuplicateMapInputs: false,
	skipDuplicateMapOutputs: true) ~> RenameColumns
PORELEASEDDATEJN derive(VBELN = ltrim(LIPS@VBELN,'0'),
		POSNR = toString(POSNR,'####'),
		SPE_LOEKZ = case(SPE_LOEKZ=='X','Deleted','Active'),
		EXPVZ = case(EXPVZ=='1','Air',EXPVZ=='2','Road',EXPVZ=='3','Sea','Others'),
		{Inbound CKey} = concat(ltrim(LIPS@VBELN,'0'),toString(POSNR, "####")),
		{Vendor Lead Time} = {TDDAT}-{PO Release Date}) ~> Transformations
RenameColumns keyGenerate(output({Inbound SKey} as long),
	startAt: 1L) ~> InboundSKey
InboundSKey sink(allowSchemaDrift: true,
	validateSchema: false,
	deletable:false,
	insertable:true,
	updateable:false,
	upsertable:false,
	recreate:true,
	format: 'table',
	batchSize: 5000,
	postSQLs:['insert into [dbo].[F_Inbound]([Inbound CKey],[Inbound SKey]) values(\'-1\',-1)'],
	skipDuplicateMapInputs: true,
	skipDuplicateMapOutputs: true,
	errorHandlingOption: 'stopOnFirstError') ~> FPURCHASEINBOUNDSINK