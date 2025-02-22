ALTER FUNCTION [dbo].[fnInsurancePremi](@nppno varchar(100))
RETURNS @table TABLE (
	NPPNo varchar(10),NoPolisi varchar(20),Model varchar(100),Kegunaan varchar(100)
	,TipePertanggungan varchar(100), tahun int, UmurKendaraan int, TanggalAwalPeriode date, TanggalAkhirPeriode date
	, Wilayah char(3), Depresiasi numeric(21,2), Rate numeric(21,5), Loading numeric(21,5), Premi numeric(21,2)
	, TJH numeric(21,2), SRCC numeric(21,2), TS numeric(21,2), Gempa numeric(21,2), Banjir numeric(21,2)
	, PAP numeric(21,2), PAD numeric(21,2)
)
AS
/*****************************************************************************
FUNCTION PREMI R2-R4 ALL INSURANCE
CREATED ON : 2022-12-26
*****************************************************************************/

BEGIN

/**FUNCTION START**/
--DECLARE @NPPNo VARCHAR(100) = '7552200257'
DECLARE @Premi NUMERIC(21,2), @TJH NUMERIC(21,2), @Addons NUMERIC(21,2)
		, @OTR NUMERIC(21,2), @DEPRESIASI NUMERIC(21,5), @RATE NUMERIC(21,5), @countCompre int
		, @UPTJH NUMERIC(21,2), @RateTJH NUMERIC(21,5), @RateAddons NUMERIC(21,5), @Tenor int
		, @DownloadDate datetime, @LoopPeriode int = 1, @tahunKendaraan int, @LockLoading int
		, @isTJH varchar(100), @tipeGuna varchar(5),@BranchId varchar(5),@BranchName varchar(100)
		, @isBanjir bit, @isSRCC bit, @isTS bit, @isGempa bit, @isGIIAS bit, @isPAD bit, @isPAP bit
		, @UPPAP NUMERIC(21,2), @UPPAD NUMERIC(21,2),@TglAwalIns Date,@HargaPertanggunganDepresiasi NUMERIC(21,2) 
		, @wilayahID varchar(100),@JumlahPenumpang int , @PoliceID char(2), @ItemID varchar(10),@ModelName varchar(100)
		,@InsType varchar(100),@modelID varchar(50),@insid char(3),@LoadingRate NUMERIC(21,5),@multiplierojk numeric(21,5),@UmurKendaraan int

SELECT @OTR = HargaPertanggunganDwl, @TENOR = datediff(mm,tglawalins,tglakhirins)
		, @DownloadDate = downloaddate,@TglAwalIns = tglawalins FROM inscoverdtl WHERE nppno = @NPPNo
SELECT @tahunKendaraan = itemYear, @itemid = cm.itemid
	, @isTJH          = case when isnull(dbo.fn_MappingBiayaProsesDesc('1',cm.cmno),'') like '%TJH 50JT%' then'TJH 50JT'
							 when isnull(dbo.fn_MappingBiayaProsesDesc('1',cm.cmno),'') like '%TJH 40JT%' then'TJH 40JT'
							 when isnull(dbo.fn_MappingBiayaProsesDesc('1',cm.cmno),'') like '%TJH 30JT%' then'TJH 30JT'
							 when isnull(dbo.fn_MappingBiayaProsesDesc('1',cm.cmno),'') like '%TJH 20JT%' then'TJH 20JT' 
							 when convert(varchar(12),cm.dtmcrt,112) >= '20180709' and cm.isitemnew = 0 
							       and (imh.insmodelname LIKE '%compre%' or imh.insmodelname like '%AR%' or CMI.InsModel = '1')
							 	  or isnull(dbo.fn_MappingBiayaProsesDesc('1',cm.cmno),'') like '%TJH 10JT%' 	  	
							 then 'TJH 10 JUTA'
							 else 'TIDAK ADA TJH' end
	, @UPTJH          = case when @istjh = 'TJH 10 JUTA' then 10000000
	                         when @istjh = 'TJH 20JT'    then 20000000
							 when @istjh = 'TJH 30JT'    then 30000000
							 when @istjh = 'TJH 40JT'    then 40000000
							 when @istjh = 'TJH 50JT'    then 50000000 
							 else 0 end
	, @isBanjir = iif(ISNULL(dbo.fn_MappingBiayaProsesDesc('2',cm.cmno),'') like '%Banjir%',1,0)
	, @isSRCC   = iif(ISNULL(dbo.fn_MappingBiayaProsesDesc('2',cm.cmno),'') like '%SRCC%',1,0)
	, @isTS     = iif(ISNULL(dbo.fn_MappingBiayaProsesDesc('2',cm.cmno),'') like '%TS%',1,0)
	, @isGempa  = iif(ISNULL(dbo.fn_MappingBiayaProsesDesc('2',cm.cmno),'') like '%GEMPA%',1,0)
	, @isGIIAS  = iif(ISNULL(dbo.fn_MappingBiayaProsesDesc('2',cm.cmno),'') like '%GIIAS%',1,0)
	, @UPPAP  = case when isnull(dbo.fn_MappingBiayaProsesDesc('1',cm.cmno),'') like '%PAP 10JT%' then 10000000
	                 when isnull(dbo.fn_MappingBiayaProsesDesc('1',cm.cmno),'') like '%PAP 20JT%' then 20000000
					 when isnull(dbo.fn_MappingBiayaProsesDesc('1',cm.cmno),'') like '%PAP 30JT%' then 30000000
					 when isnull(dbo.fn_MappingBiayaProsesDesc('1',cm.cmno),'') like '%PAP 40JT%' then 40000000
					 when isnull(dbo.fn_MappingBiayaProsesDesc('1',cm.cmno),'') like '%PAP 50JT%' then 50000000 
					 else 0 end
	, @UPPAD  = case when isnull(dbo.fn_MappingBiayaProsesDesc('1',cm.cmno),'') like '%PAD 10JT%' then 10000000
	                 when isnull(dbo.fn_MappingBiayaProsesDesc('1',cm.cmno),'') like '%PAD 20JT%' then 20000000
					 when isnull(dbo.fn_MappingBiayaProsesDesc('1',cm.cmno),'') like '%PAD 30JT%' then 30000000
					 when isnull(dbo.fn_MappingBiayaProsesDesc('1',cm.cmno),'') like '%PAD 40JT%' then 40000000
					 when isnull(dbo.fn_MappingBiayaProsesDesc('1',cm.cmno),'') like '%PAD 50JT%' then 50000000 
					 else 0 end
	, @JumlahPenumpang = case when isnull(dbo.fn_MappingBiayaProsesDesc('1',cm.cmno),'') like '%PAP%3 Penumpang%' then 3
							  when isnull(dbo.fn_MappingBiayaProsesDesc('1',cm.cmno),'') like '%PAP%6 Penumpang%' then 6
							  when isnull(dbo.fn_MappingBiayaProsesDesc('1',cm.cmno),'') like '%PAP%'             then 3
							  else 0 end
	, @tipeGuna = iif(cm.itemid = '001',1,tipecover)
	, @PoliceID = replace(replace(replace(replace(replace(replace(replace(replace(replace(replace(replace(left(isnull(bp.carno,bpm.CarNO),2) --modified by yohan 2023/08/03
	               ,'',''),'1',''),'2',''),'3',''),'4',''),'5',''),'6',''),'7',''),'8',''),'9',''),'0','')
	,@modelID     = isnull(imt.modelID,ass.AssetKindClassID)
	,@insid       = ich.insid
	,@branchid    = cm.branchid
	,@branchname  = cb.branchname
FROM CM cm 
left join bpkb bp on bp.nppno = cm.nppno
left join BPKB_MB bpm on bpm.nppno = cm.nppno
left join MACFDB.DBO.SYSGFCOMPANYBRANCH cb on cm.branchid = cb.branchid
left join CM_Insurance CMI with(nolock) on Cm.CMNo = CMI.CMNo
left join macfdb.dbo.CFCM_Insurance CMINew with(nolock) on Cm.CMNo = CMINew.CMNo
left join macfdb.dbo.GFInsuranceModelHeader imh with(nolock) on imh.insmodelid = CMINew.insmodel
inner join ItemMerkType imt with(nolock) on cm.ItemMerkTypeID=imt.ItemMerkTypeId
left join macfdb.dbo.gfassettypemaster ass with(nolock) on ass.AssetTypeID = imt.MappingId
inner join InscoverDtl icd with(nolock) on cm.NPPNo=icd.NPPNo
inner join InsCoverHdr ich with(nolock) on icd.NoSuratCover = ich.NoSuratCover
WHERE cm.nppno = @NPPNO
SELECT @ModelName = modelname FROM model WHERE modelid = @modelID

/***SET MODEL_ID NULL*/
if @modelID is null
	begin 
	select @modelID = ass.assetkindclassid from cm cm
		left join itemmerktype itm on itm.itemmerktypeid = cm.itemmerktypeid
		left join model mo on mo.modelid = itm.modelid
		left join macfdb.dbo.gfassettypemaster ass on ass.assettypeid = itm.mappingid
		where nppno = @NPPNO
	
	select @ModelName = ModelName from model where modelid = @modelID

	end

/***SET MODEL_ID '015'*/
IF @modelID = '015'
BEGIN
    SET @modelID = '014'
    SELECT @ModelName = ModelName 
    FROM model 
    WHERE modelid = @modelID
END


/**SET DOUBLE CABIN**/ --yohan 2023/10/17
if exists (select '' from cm cm 
            inner join itemmerktype itm on itm.itemmerktypeid = cm.itemmerktypeid
            inner join model mo on mo.modelid = itm.modelid
            where mo.modelid = '013' and cm.itemid = '002' and nppno = @NPPNo /**and (itm.itemtypename LIKE '%DC%' or itm.itemtypename LIKE '%DOUBLE CABIN%')**/)

		begin
				set @modelID = '006'
				set @ModelName = 'DOUBLE CABIN'
		end

else
        begin
				set @modelID = @modelID
		end

/**GIIAS**/
if @isGIIAS = 1
		begin 
		declare @Compre int
		select @Compre = count(CMNo) from MACFDB.dbo.CFCM 
		where BiayaProsesID in ('B000000130','B000000132','B000000131') and StatusCM in ('A','D','0')
			begin
			set @Tenor = @Tenor - 12
			end
		end


if exists  (select '' from cm cm left join bpkb bp on cm.nppno = bp.nppno
                                 left join bpkb_mb bpm on cm.NPPNo = bpm.NPPNo 
								 where bp.carno is not null
									   and cm.nppno =  @NPPNO
									   or bpm.CarNO is not null 
									   and cm.nppno =  @NPPNO ) --modified by yohan 2023/08/03
	begin
		SELECT @WilayahID = WilayahID FROM MsInsuranceWilayahNomorPolisi WHERE policeid = @PoliceID
	end
else
	begin 
		SELECT @WilayahID = coalesce(bmoo.wilayahID,map2.WilayahID,map.WilayahID) FROM cm cm
		left join DUMP_EMPCF.dbo.branchMappingOJK_override bmoo with(nolock) on bmoo.nppno = cm.nppno
		left join branch bra on bra.branchid = cm.branchid
		left join  MsInsuranceWilayahBranch map on map.areaid = bra.areaid
		left join  MsInsuranceWilayahBranch map2 on map2.BranchID = bra.BranchID
		where cm.NPPNo = @NPPNo	                                   
	end


/**TJH**/
IF @modelid IN ('005','006','007','008','009','010')
	BEGIN 
		SELECT @TJH =iif(@UPTJH>25000000,25000000,@UPTJH) * 0.015 --iif(@tipeGuna = 1, 0.01, 0.015)
				    +iif(@UPTJH <= 25000000, 0,iif(@UPTJH>50000000,25000000,@UPTJH - 25000000) * 0.0075)--iif(@tipeGuna = 1, 0.005, 0.0075))
			        +iif(@UPTJH>50000000,(@UPTJH - 50000000),0) * 0.0025--iif(@tipeGuna = 1, 0.0025, 0.00375)
	END

ELSE IF @insid IN ('004','014','017','015')
	BEGIN 
	    SELECT @TJH =iif(@UPTJH>25000000,25000000,@UPTJH) * iif(@tipeGuna = 1, 0.01, 0.015)
				    +iif(@UPTJH <= 25000000, 0,iif(@UPTJH>50000000,25000000,@UPTJH - 25000000) * iif(@tipeGuna = 1, 0.005, 0.0075))
			        +iif(@UPTJH>50000000,(@UPTJH - 50000000),0) *iif(@tipeGuna = 1, 0.0025, 0.00375)
	END

	
 ELSE 			 	
	    SELECT @TJH =iif(@UPTJH>25000000,25000000,@UPTJH) * 0.01--iif(@tipeGuna = 1, 0.01, 0.015)
				    +iif(@UPTJH <= 25000000, 0,iif(@UPTJH>50000000,25000000,@UPTJH - 25000000) * 0.005)--iif(@tipeGuna = 1, 0.005, 0.0075))
			    +iif(@UPTJH>50000000,(@UPTJH - 50000000),0) * 0.00375--iif(@tipeGuna = 1, 0.0025, 0.00375)

--select @ISTJH,@TJH


/***********BUAT INSMODEL DARI BIAYA PROSES MACFDB************/ --add by yohan 02/09/2024
declare @insmodelID int,
        @Allrisk varchar(3),
		@TLO varchar(3)

select @Allrisk =allrisk, @TLO =tlo from MACFDB.dbo.msbiayaproseshdr a
inner join MACFDB.dbo.cfcm b on b.BiayaProsesID = a.BiayaProsesID AND CAST(b.biayaprosessecq AS INT) = a.secq
 where b.agreementnumber = @NPPNo

 --select * from MACFDB.dbo.GFInsuranceModelHeader

SELECT @insmodelID = 
    CASE 
	    WHEN @Allrisk = 1 AND @TLO = 0 THEN 1 --insmodelID ditentukan berdasarkan tabel master GFInsuranceModelHeader
	    WHEN @Allrisk = 2 AND @TLO = 0 THEN 2
        WHEN @Allrisk = 3 AND @TLO = 0 THEN 3
		WHEN @Allrisk = 4 AND @TLO = 0 THEN 4
		WHEN @Allrisk = 5 AND @TLO = 0 THEN 5
		WHEN @Allrisk = 1 AND @TLO = 1 THEN 6
		WHEN @Allrisk = 1 AND @TLO = 2 THEN 7
		WHEN @Allrisk = 1 AND @TLO = 3 THEN 8
		WHEN @Allrisk = 1 AND @TLO = 4 THEN 9
		WHEN @Allrisk = 2 AND @TLO = 1 THEN 10
		WHEN @Allrisk = 2 AND @TLO = 2 THEN 11
		WHEN @Allrisk = 2 AND @TLO = 3 THEN 12
		WHEN @Allrisk = 3 AND @TLO = 1 THEN 13
		WHEN @Allrisk = 3 AND @TLO = 2 THEN 14
		WHEN @Allrisk = 4 AND @TLO = 1 THEN 15
		WHEN @Allrisk = 0 AND @TLO = 1 THEN 16
		WHEN @Allrisk = 0 AND @TLO = 2 THEN 17
		WHEN @Allrisk = 0 AND @TLO = 3 THEN 18
		WHEN @Allrisk = 0 AND @TLO = 4 THEN 19
		WHEN @Allrisk = 0 AND @TLO = 5 THEN 20
		ELSE NULL
    END 

/**Start Looping**/
WHILE @LoopPeriode <= CEILING(@TENOR/12.0)
BEGIN

/**TIPE PERTAGUNGAN**/
	SELECT  @InsType = iif(cm.itemid = '001','TLO',dbo.fnEPGetInsuranceTypePerPeriod_NewNPP(icd.Tenor, @loopperiode, isnull(@insmodelID/*add by yohan 02/09/2024*/,imh.InsModelID))) 
	FROM InscoverDtl icd with(nolock)
	  inner join CM Cm with(nolock) on icd.NPPNo = Cm.NPPNo 
	  left join CM_Insurance CMI with(nolock) on Cm.CMNo = CMI.CMNo
	  left join macfdb.dbo.CFCM_Insurance CMINew with(nolock) on Cm.CMNo = CMINew.CMNo
	  left join macfdb.dbo.GFInsuranceModelHeader imh with(nolock) on imh.insmodelid = CMINew.insmodel
	WHERE icd.nppno = @nppno

/**UMUR KENDARAAN*/	
	SELECT @UmurKendaraan = year(@downloaddate) - @tahunKendaraan + (@LoopPeriode-1)

/**DEPRESIASI**/
IF @itemid = '001'
	BEGIN
		SELECT @DEPRESIASI = case @LoopPeriode when 1 then 1
											   when 2 then 0.8
											   when 3 then 0.7
											   when 4 then 0.6
											   when 5 then 0.5 end
    END

ELSE IF @InsID in ('010','011','020')	
	BEGIN
		SELECT @DEPRESIASI = case @LoopPeriode when 1 then 1
											   when 2 then 0.8
											   when 3 then 0.7
											   when 4 then 0.65
											   when 5 then 0.625 end
	END


ELSE
		SELECT @DEPRESIASI = case @LoopPeriode when 1 then 1
											   when 2 then 0.8
											   when 3 then 0.7
											   when 4 then 0.65
											   when 5 then 0.6 end

/**HARGAPERTANGGUNGAN**/	
	SELECT @HargaPertanggunganDepresiasi = @OTR*@DEPRESIASI

/**RATE**/	
	select @RATE = Rate FROM MsInsuranceRateOJK /*[[hfmcf].DUMP_EMPCF].dbo.RateCorpRelianceCakrawala*/
			WHERE InsID   = @InsID
			AND InsType   = @InsType
			AND TipeGuna  = @TipeGuna
			AND WilayahID = @WilayahID
			AND ModelID   = @modelID
			AND @HargaPertanggunganDepresiasi BETWEEN OTRStart AND OTREnd

/**LOADING RATE**/
	IF (@instype LIKE '%Compre%' AND @InsID in ('011'))
		BEGIN
			IF @LoopPeriode = 1 BEGIN SELECT @LockLoading = @UmurKendaraan END
			
			SET @loadingrate = case when @LockLoading > 5 then 0.05 else 0.00 end 
		END

	ELSE IF ( @instype LIKE '%Compre%' AND @UmurKendaraan > 5 AND @insid in ('010','020','016','019') )
		BEGIN
			SET @loadingrate = 0.05
		END
	ELSE IF ( @instype LIKE '%Compre%' AND @UmurKendaraan BETWEEN 6 AND 10 AND @insid = '015' )
		BEGIN
			SET @loadingrate = 0.05
		END
	ELSE IF ( @instype LIKE '%Compre%' AND @UmurKendaraan > 10 AND @insid = '015' )
		BEGIN
			SET @multiplierojk = @UmurKendaraan-10
			SET @loadingrate = 0.05+(0.05*@multiplierojk)
		END
	ELSE IF ( @instype LIKE '%Compre%' AND @UmurKendaraan > 5 )
		BEGIN
			SET @multiplierojk = @UmurKendaraan-5
			SET @loadingrate = 0.05*@multiplierojk
		END

	ELSE IF (@instype LIKE '%TLO%'  )
		BEGIN
			SET @loadingrate = 0
		END

	ELSE
			SET @loadingrate = 0

/**TJH**/
IF @InsType LIKE '%TLO%'
	BEGIN 
		SET @TJH = 0
	END
	

	insert into @table
	select    @NPPNo
			, iif(@PoliceID is null ,'Belum Terbit',@PoliceID)
			, @ModelName
			, iif(@tipeGuna = 1,'Pribadi','Komersil')
			, @instype
			, @LoopPeriode
			, @UmurKendaraan
			, dateadd(year,@LoopPeriode-1,@TglAwalIns)
			, dateadd(MONTH,iif(@tenor-(12*(@LoopPeriode-1))>=12,12,@tenor-(12*(@LoopPeriode-1))),dateadd(year,@LoopPeriode-1,@TglAwalIns))
			, @WilayahID
			, @HargaPertanggunganDepresiasi
			, @RATE
			, @LoadingRate
			, (@HargaPertanggunganDepresiasi * @RATE / 100 + (@HargaPertanggunganDepresiasi * @RATE / 100 * @loadingrate)) 
				*iif(@tenor-(12*(@LoopPeriode-1))>=12
					,1
					,datediff(day,dateadd(year,@LoopPeriode-1,@TglAwalIns),dateadd(MONTH,iif(@tenor-(12*(@LoopPeriode-1))>=12,12,@tenor-(12*(@LoopPeriode-1))),dateadd(year,@LoopPeriode-1,@TglAwalIns)))/
					iif(@insid in ('004','014','022'),datediff(day,dateadd(year,@LoopPeriode-1,@TglAwalIns),dateadd(year,@LoopPeriode,@TglAwalIns)),365.0)
					)
			, @TJH
			, iif(@isSRCC=0  ,0,@HargaPertanggunganDepresiasi * 0.0005)
			, iif(@isTS=0    ,0,@HargaPertanggunganDepresiasi * 0.0005)
			, iif(@isGempa=0 ,0,@HargaPertanggunganDepresiasi * case @wilayahID when 'wp1' then 0.0012 when 'wp2' then 0.001 else 0.00075 end)
			, iif(@isBanjir=0,0,@HargaPertanggunganDepresiasi * case @wilayahID when 'wp1' then 0.00075 when 'wp2' then 0.001 else 0.00075 end)
			, iif(@UPPAD=0,0, 0.005 * @UPPAD)
			, iif(@UPPAP=0,0, 0.001 * @UPPAP * @JumlahPenumpang)
	SET @LoopPeriode += 1

END


/* Debug */
/*
select * from @table

select PremiGross = sum(premi)+sum(TJH)+sum(SRCC)+sum(TS)+sum(Gempa)+sum(Banjir)+sum(PAP)+sum(PAD)
	  ,Diskon = (sum(premi)+sum(TJH)+sum(SRCC)+sum(TS)+sum(Gempa)+sum(Banjir)+sum(PAP)+sum(PAD))*0.25
      ,TotalPremi = (sum(premi)+sum(TJH)+sum(SRCC)+sum(TS)+sum(Gempa)+sum(Banjir)+sum(PAP)+sum(PAD))*0.75
from @table

select Banjir = @isBanjir, SRRC = @isSRCC, TS = @isTS, Gempa = @isGempa, GIIAS = @isGIIAS, 
UPPAP = @UPPAP, UPPAD = @UPPAD,NomorPolisi = @PoliceID,IDCaba = @BranchID,NamaCabang = @Branchname,MODEL = @modelID
,Asuransi= insname, Tenor = @tenor
,TipeGuna = iif(@tipeGuna = 1,'Pribadi','Komersil')
,ItemID = @itemid
from msptinsurance where insid = @insid
*/

RETURN
END










