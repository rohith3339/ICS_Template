source(output(
		AFNAM as string,
		BADAT as date,
		BANFN as string,
		BEDNR as string,
		BLCKD as string,
		BNFPO as integer,
		BSART as string,
		BSMNG as decimal(13,3),
		EBELN as string,
		EBELP as integer,
		EKGRP as string,
		EKORG as string,
		ERDAT as date,
		ERNAM as string,
		FRGKZ as string,
		FRGST as string,
		FRGZU as string,
		KNTTP as string,
		LFDAT as date,
		LGORT as string,
		LOAD_DATETIME as date,
		LOEKZ as string,
		MATKL as string,
		MATNR as string,
		MEINS as string,
		MENGE as decimal(13,3),
		PEINH as integer,
		PREIS as decimal(11,2),
		PRIO_URG as integer,
		PSTYP as string,
		RLWRT as decimal(15,2),
		STATU as string,
		TXZ01 as string,
		WAERS as string,
		WERKS as string
	),
	allowSchemaDrift: true,
	validateSchema: false,
	ignoreNoFilesFound: false,
	batchSize: 5000,
	isolationLevel: 'READ_UNCOMMITTED',
	format: 'table') ~> EBAN
source(output(
		{PR No} as string,
		{PR Ln} as string,
		{PR Release Date} as date
	),
	allowSchemaDrift: true,
	validateSchema: false,
	ignoreNoFilesFound: false,
	batchSize: 5000,
	isolationLevel: 'READ_UNCOMMITTED',
	format: 'table') ~> IPRRELEASEDATE
source(output(
		BELNR as string,
		BEWTP as string,
		BLDAT as date,
		BUDAT as date,
		BUZEI as integer,
		BWART as string,
		DMBTR as decimal(15,3),
		EBELN as string,
		EBELP as integer,
		ERNAM as string,
		GJAHR as integer,
		MENGE as decimal(15,3),
		SHKZG as string,
		WAERS as string,
		WRBTR as decimal(15,3),
		LFBNR as string,
		LFGJA as string,
		LFPOS as string
	),
	allowSchemaDrift: true,
	validateSchema: false,
	ignoreNoFilesFound: false,
	batchSize: 5000,
	isolationLevel: 'READ_UNCOMMITTED',
	format: 'table') ~> EKBE
source(output(
		BWART as string,
		MBLNR as string,
		MJAHR as integer,
		VBELN_IM as string,
		VBELP_IM as integer,
		ZEILE as integer
	),
	allowSchemaDrift: true,
	validateSchema: false,
	ignoreNoFilesFound: false,
	batchSize: 5000,
	isolationLevel: 'READ_UNCOMMITTED',
	format: 'table') ~> MSEG
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
DerivedColumn1, IPRRELEASEDATE join(BANFN == {PR No}
	&& BNFPO == {PR Ln},
	joinType:'left',
	broadcast: 'auto')~> IPRAndEBANJoin1
IPRAndEBANJoin1 select(mapColumn(
		BANFN,
		BNFPO,
		EBELN,
		EBELP,
		{PR Release Date}
	),
	skipDuplicateMapInputs: true,
	skipDuplicateMapOutputs: true) ~> PRTable
EKBE filter(BEWTP=='E') ~> EKBEfilter
EKBEfilter, PRTable join(EKBE@EBELN == PRTable@EBELN
	&& EKBE@EBELP == PRTable@EBELP,
	joinType:'left',
	broadcast: 'auto')~> PRtableEKBEJoin2
EBAN derive(BNFPO = toString(BNFPO,"####"),
		BANFN = ltrim(BANFN, "0")) ~> DerivedColumn1
MSEG, LIKP join(VBELN_IM == VBELN,
	joinType:'inner',
	broadcast: 'auto')~> InboundTable
InboundTable select(mapColumn(
		MBLNR,
		MJAHR,
		VBELN_IM,
		ZEILE,
		{Inbound Trnsplning Date} = TDDAT,
		VBELN
	),
	skipDuplicateMapInputs: true,
	skipDuplicateMapOutputs: true) ~> InboundColumns
EKET select(mapColumn(
		EBELN,
		EBELP,
		SLFDT
	),
	skipDuplicateMapInputs: true,
	skipDuplicateMapOutputs: true) ~> EKETColumns
PRtableEKBEJoin2 select(mapColumn(
		{GR No} = BELNR,
		{GR Doc Date} = BLDAT,
		{GR Posting Date} = BUDAT,
		{GR Ln} = BUZEI,
		{GR Movement Type} = BWART,
		{GR Value in LC} = DMBTR,
		{GR Created By} = ERNAM,
		{GR Year} = GJAHR,
		{GR Qty} = MENGE,
		{GR DC Ind} = SHKZG,
		{GR Currency} = WAERS,
		{PR Release Date},
		EBELP = EKBE@EBELP,
		EBELN = EKBE@EBELN,
		{GR Value} = WRBTR
	),
	skipDuplicateMapInputs: true,
	skipDuplicateMapOutputs: true) ~> Join2Columns
InboundColumns, Join2Columns join(MBLNR == {GR No}
	&& ZEILE == {GR Ln}
	&& MJAHR == {GR Year},
	joinType:'right',
	broadcast: 'auto')~> PRtabInboundJoin3
Join3Columns, EKETColumns join(Join3Columns@EBELN == EKETColumns@EBELN
	&& Join3Columns@EBELP == EKETColumns@EBELP,
	joinType:'left',
	broadcast: 'auto')~> EKETInboundJoin4
PRtabInboundJoin3 select(mapColumn(
		{Inbound Trnsplning Date},
		{GR No},
		{GR Doc Date},
		{GR Posting Date},
		{GR Ln},
		{GR Movement Type},
		{GR Value in LC},
		{GR Created By},
		{GR Year},
		{GR Qty},
		{GR DC Ind},
		{GR Currency},
		{PR Release Date},
		EBELP,
		EBELN,
		{GR Value}
	),
	skipDuplicateMapInputs: true,
	skipDuplicateMapOutputs: true) ~> Join3Columns
EKETInboundJoin4 derive({GR Ln} = toString({GR Ln}, '####'),
		{GR Year} = toString({GR Year},'####'),
		{On Time Delivery} = {GR Posting Date} -SLFDT,
		{Vendor Shipment Time} = {GR Doc Date}-{Inbound Trnsplning Date},
		{PR GR Cycle Time} = {GR Doc Date}-{PR Release Date},
		{GR CKey} = concat((concat(toString({GR Year},'####'), {GR No})), toString({GR Ln}, '####'))) ~> Trannsformations
OutputColumns keyGenerate(output({GR SKey} as long),
	startAt: 1L) ~> GRSKEY
Trannsformations select(mapColumn(
		{Inbound Trnsplning Date},
		{GR No},
		{GR Doc Date},
		{GR Posting Date},
		{GR Ln},
		{GR Movement Type},
		{GR Value in LC},
		{GR Created By},
		{GR Year},
		{GR Qty},
		{GR DC Ind},
		{GR Currency},
		{PR Release Date},
		{GR Value},
		{On Time Delivery},
		{Vendor Shipment Time},
		{PR GR Cycle Time},
		{GR CKey}
	),
	skipDuplicateMapInputs: true,
	skipDuplicateMapOutputs: true) ~> OutputColumns
GRSKEY sink(allowSchemaDrift: true,
	validateSchema: false,
	deletable:false,
	insertable:true,
	updateable:false,
	upsertable:false,
	recreate:true,
	format: 'table',
	batchSize: 5000,
	postSQLs:['insert into [dbo].[F_GOODSRECEIPT]([GR CKey],[GR SKey]) values(\'-1\',-1)'],
	skipDuplicateMapInputs: true,
	skipDuplicateMapOutputs: true,
	errorHandlingOption: 'stopOnFirstError') ~> FGOODSRECEIPTSINK