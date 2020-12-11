source(output(
		AEDAT as date,
		ANGDT as date,
		BEDAT as date,
		BSART as string,
		BSTYP as string,
		BUKRS as string,
		DPAMT as decimal(11,2),
		DPDAT as date,
		DPPCT as decimal(5,2),
		DPTYP as string,
		EBELN as string,
		EKGRP as string,
		EKKO_POHDR_KEY as string,
		EKORG as string,
		ERNAM as string,
		FRGRL as string,
		INCO1 as string,
		INCO2 as string,
		KNUMV as string,
		LIFNR as string,
		WAERS as string,
		WKURS as decimal(9,5),
		ZBD1T as integer,
		ZTERM as string
	),
	allowSchemaDrift: true,
	validateSchema: false,
	ignoreNoFilesFound: false,
	batchSize: 5000,
	isolationLevel: 'READ_UNCOMMITTED',
	format: 'table') ~> EKKO
source(output(
		AEDAT as date,
		ANFNR as string,
		ANFPS as integer,
		BANFN as string,
		BEDNR as string,
		BNFPO as integer,
		BRTWR as decimal(13,2),
		BUKRS as string,
		EBELN as string,
		EBELP as integer,
		EKPO_POLN_KEY as string,
		ELIKZ as string,
		KNTTP as string,
		LEWED as date,
		LOEKZ as string,
		MATKL as string,
		MATNR as string,
		MEINS as string,
		MENGE as decimal(13,3),
		NETPR as decimal(11,2),
		NETWR as decimal(13,2),
		PEINH as integer,
		PRIO_URG as integer,
		PSTYP as string,
		STATU as string,
		TXZ01 as string,
		WERKS as string,
		LGORT as string
	),
	allowSchemaDrift: true,
	validateSchema: false,
	ignoreNoFilesFound: false,
	batchSize: 5000,
	isolationLevel: 'READ_UNCOMMITTED',
	format: 'table') ~> EKPO
source(output(
		BANFN as string,
		BNFPO as integer,
		EBELN as string,
		EBELP as integer,
		EINDT as date,
		EKET_SCHLN_KEY as string,
		SLFDT as date,
		LOAD_DATETIME as timestamp
	),
	allowSchemaDrift: true,
	validateSchema: false,
	ignoreNoFilesFound: false,
	batchSize: 5000,
	isolationLevel: 'READ_UNCOMMITTED',
	format: 'table') ~> EKET
EKKO filter(BSTYP == 'A') ~> FilterDocCategory
FilterDocCategory, EKPO join(EKKO@EBELN == EKPO@EBELN,
	joinType:'inner',
	broadcast: 'auto')~> EKKOEKPOJN
EKETJOIN select(mapColumn(
		{RFQ No} = EKPO@EBELN,
		{RFQ Ln} = EKPO@EBELP,
		{RFQ Creation Date} = EKKO@AEDAT,
		{RFQ Deadline Date} = ANGDT,
		{RFQ Delivery Date} = EINDT
	),
	skipDuplicateMapInputs: true,
	skipDuplicateMapOutputs: true) ~> SelectRenameColumns
DataTypeConversion derive({RFQ CKey} = concat({RFQ No},{RFQ Ln})) ~> GenerateCKey
EKKOEKPOJN, EKET join(EKPO@EBELN == EKET@EBELN
	&& EKPO@EBELP == EKET@EBELP,
	joinType:'left',
	broadcast: 'auto')~> EKETJOIN
SelectRenameColumns derive({RFQ Ln} = toString({RFQ Ln})) ~> DataTypeConversion
GenerateCKey derive({RFQ No} = ltrim({RFQ No}, '0'),
		{RFQ CKey} = ltrim({RFQ CKey}, '0')) ~> TrimLeadingZeros
TrimLeadingZeros keyGenerate(output({FPurchaseRFQ Skey} as long),
	startAt: 1L) ~> FPurchaseRFQSkey
FPurchaseRFQSkey sink(allowSchemaDrift: true,
	validateSchema: false,
	deletable:false,
	insertable:true,
	updateable:false,
	upsertable:false,
	recreate:true,
	format: 'table',
	batchSize: 5000,
	postSQLs:['insert into [dbo].[F_PurchaseRFQ]([RFQ CKey],[FPurchaseRFQ Skey]) values(\'-1\',-1)'],
	skipDuplicateMapInputs: true,
	skipDuplicateMapOutputs: true,
	errorHandlingOption: 'stopOnFirstError') ~> LoadFPurchaseRFQ