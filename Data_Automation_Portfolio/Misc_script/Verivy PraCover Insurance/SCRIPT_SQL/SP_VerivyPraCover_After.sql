
DECLARE
	@pivchInsID varchar(3) = '005',
	@pivchItemID char(3) = '001'

BEGIN TRAN TEST
declare @TInsurance table(id int identity, NppNo varchar(10), Tenor tinyint, InsPeriodID char(3), InsID varchar(3))
declare @TComposition table(id int identity, InsPeriodID char(3), InsID varchar(3), PeriodTo tinyint, CP1 int, CP2 int, CP3 int, CP4 int, CP5 int)

declare @cntTInsurance int, @iTInsurance int, @NppNo varchar(10), @BranchID varchar(3), @Tenor tinyint, @InsPeriodID char(3), @InsID varchar(3)
, @PeriodTo tinyint
		,@MachineNo varchar(35), @ChasisNo varchar(35) 
		,@CP1 int, @CP2 int, @CP3 int, @CP4 int, @CP5 int
		,@TenorComposition tinyint , @P varchar(20)
		,@CovegarePeriodValue varchar(30)
		,@CovegarePeriodLessThenValue varchar(30) 
		,@RemainingPeriodLessThenValue varchar(30)
		,@IsComposition bit
		,@ValidDataTIns bit

Declare @MinCoveragePeriodValue varchar(30)
-- ** Minimal Coverage Period ** --  
Set @MinCoveragePeriodValue=dbo.fnEPGenInsPolicyValue('MinCoveragePeriod')  
		
DECLARE @CountNPPSkip INT
SET @CountNPPSkip=(SELECT COUNT(NPPNo) FROM InsurancePraCoverTCManual)

IF @CountNPPSkip>0
BEGIN
	SET @MinCoveragePeriodValue=0
END

insert into @TInsurance(NppNo, Tenor, InsPeriodID, InsID) 	
SELECT tdt.NPPNo, tdt.Tenor, dbo.fnEPGenInsPeriodIDComposition(tdt.Tenor) AS InsPeriodID, tdt.InsID
FROM TInsuranceDtl tdt	
inner join NPP np with(nolock) on np.NPPNo=tdt.NPPNo	
INNER JOIN CM cm with(nolock) on cm.NPPNo=tdt.NPPNo 
WHERE tdt.InsID = @pivchInsID AND 
		cm.ItemID = @pivchItemID AND
		tdt.IsActive = 0 AND 
		tdt.NoSuratCover IS NULL AND 
		tdt.DownloadDate IS NULL AND 
		tdt.DownloadBy IS NULL AND
		-- Untuk mencegah data2 lama yang tidak pernah di download
		tdt.TglAkhirIns >= DATEADD(MONTH, CAST(@MinCoveragePeriodValue AS int), GETDATE())
		and RIGHT(CONVERT(varchar(8),np.ApproveDate,112),6) >= '120701' 
ORDER BY np.ApproveDate DESC									

select @cntTInsurance=count(*) from @TInsurance

set @iTInsurance=1
Set @CovegarePeriodValue=dbo.fnEPGenInsPolicyValue('CoveragePeriod') -- ** Coverage Period ** --
Set @CovegarePeriodLessThenValue=dbo.fnEPGenInsPolicyValue('CoveragePeriodLessThen') -- ** Coverage Period Less Then ** --
Set @RemainingPeriodLessThenValue=dbo.fnEPGenInsPolicyValue('RemainingPeriodLessThen') -- ** Remaining Period Less Then ** --
Set @TenorComposition = @Tenor
Set @IsComposition = 0

     UPDATE tdt 
     Set	
	 IsActive = 1
	 ,TglAkhirIns = DATEADD(MONTH, tin.tenor, TglAwalIns)
	 ,Tenor = tin.Tenor
	 ,TenorSisa = cm.tenor-tdt.tenor
	 ,IsComposition = tin.IsComposition
	 ,DateOfVerify = GETDATE()
    FROM TInsuranceDtl tdt	
    inner join (
				select nppno,tenor,iscomposition = @IsComposition
					    from @TInsurance 
	           ) tin on tin.nppno = tdt.nppno
	inner join cm cm on cm.nppno = tdt.NppNo		   	
	
ROLLBACK TRAN TEST
