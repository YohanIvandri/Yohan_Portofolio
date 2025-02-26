

DECLARE
	@pivchInsID varchar(3) = '005',
	@pivchItemID char(3) = '002'

BEGIN TRAN TEST
declare @TInsurance table(id int identity, NppNo varchar(10), Tenor tinyint, InsPeriodID char(3), InsID varchar(3))
declare @TComposition table(id int identity, InsPeriodID char(3), InsID varchar(3), PeriodTo tinyint, CP1 int, CP2 int, CP3 int, CP4 int, CP5 int)

declare @cntTInsurance int, @iTInsurance int, @NppNo varchar(10), @BranchID varchar(3), @Tenor tinyint, @InsPeriodID char(3), @InsID varchar(3)
, @PeriodTo tinyint
		,@MachineNo varchar(35), @ChasisNo varchar(35) 
		,@CP1 int, @CP2 int, @CP3 int, @CP4 int, @CP5 int
		,@TenorComposition tinyint , @P varchar(20)
		--,@MinCoveragePeriodValue varchar(30)
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

				
insert into @TComposition (InsPeriodID, InsID, PeriodTo, CP1, CP2, CP3, CP4, CP5)	
Exec spEPInsuranceGetNppPerCompositionPeriodBatching @pivchInsID, @pivchItemID 	

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
		--TglAkhirIns >= GETDATE()
		tdt.TglAkhirIns >= DATEADD(MONTH, CAST(@MinCoveragePeriodValue AS int), GETDATE())	
		and RIGHT(CONVERT(varchar(8),np.ApproveDate,112),6) >= '120701' -- confirm by Kiki, 12-11-12
ORDER BY np.ApproveDate DESC									

select @cntTInsurance=count(*) from @TInsurance

set @iTInsurance=1

--Set @MinCoveragePeriodValue=dbo.fnEPGenInsPolicyValue('MinCoveragePeriod') -- ** Minimal Coverage Period ** --
Set @CovegarePeriodValue=dbo.fnEPGenInsPolicyValue('CoveragePeriod') -- ** Coverage Period ** --
Set @CovegarePeriodLessThenValue=dbo.fnEPGenInsPolicyValue('CoveragePeriodLessThen') -- ** Coverage Period Less Then ** --
Set @RemainingPeriodLessThenValue=dbo.fnEPGenInsPolicyValue('RemainingPeriodLessThen') -- ** Remaining Period Less Then ** --

Declare GetIns Cursor
For
	select  
		NppNo,
		Tenor,
		InsPeriodID,
		InsID
	from @TInsurance 

Open GetIns
Fetch Next From GetIns Into
	@NPPNo, @Tenor, @InsPeriodID, @InsID 
While @@Fetch_Status = 0
Begin

	if @CovegarePeriodValue = '1' -- FULL
	Begin
	
		IF @pivchItemID = '001' -- TIPE MOTOR
		BEGIN
	
			Select @CP1=CP1, @CP2=CP2, @CP3=CP3, @CP4=CP4, @CP5=CP5, @PeriodTo=PeriodTo From @TComposition
			Where InsPeriodID = @InsPeriodID AND InsID = @InsID
			
			If @CP1 > 0 
			Begin
				Update @TComposition Set CP1 = CP1 - 1
				Where InsPeriodID = @InsPeriodID AND InsID = @InsID
				
				if 12 < @Tenor 
				Begin
					Set @TenorComposition = 12 
					Set @IsComposition = 1
				End
				Else
				Begin
					Set @TenorComposition = @Tenor
					Set @IsComposition = 0
				End
				EXEC spEPVerifyBatchingUpdate @NPPNo, @InsID, @TenorComposition, @IsComposition, @CovegarePeriodValue, @CovegarePeriodLessThenValue, @RemainingPeriodLessThenValue
				Set @P = 'P1'
			End
			Else
			Begin
				
				If @CP2 > 0 
				Begin
					Update @TComposition Set CP2 = CP2 - 1
					Where InsPeriodID = @InsPeriodID AND InsID = @InsID
					
					if 24 < @Tenor 
					Begin
						Set @TenorComposition = 24 
						Set @IsComposition = 1
					End
					else
					Begin 
						Set @TenorComposition = @Tenor
						Set @IsComposition = 0
					End
				
					EXEC spEPVerifyBatchingUpdate @NPPNo, @InsID, @TenorComposition, @IsComposition, @CovegarePeriodValue, @CovegarePeriodLessThenValue, @RemainingPeriodLessThenValue
					Set @P = 'P2'
				End
				Else
				Begin
					
					If @CP3 > 0 
					Begin
						Update @TComposition Set CP3 = CP3 - 1
						Where InsPeriodID = @InsPeriodID AND InsID = @InsID
						
						if 36 < @Tenor 
						Begin
							Set @TenorComposition = 36 
							Set @IsComposition = 1
						End
						else
						Begin 
							Set @TenorComposition = @Tenor
							Set @IsComposition = 0
						End
						
						EXEC spEPVerifyBatchingUpdate @NPPNo, @InsID, @TenorComposition, @IsComposition, @CovegarePeriodValue, @CovegarePeriodLessThenValue, @RemainingPeriodLessThenValue 
						Set @P = 'P3'
					End
					Else
					Begin
						
						If @CP4 > 0 
						Begin
							Update @TComposition Set CP4 = CP4 - 1
							Where InsPeriodID = @InsPeriodID AND InsID = @InsID
							
							if 48 < @Tenor 
							Begin
								Set @IsComposition = 1
								Set @TenorComposition = 48 
							End
							else
							Begin 
								Set @IsComposition = 0
								Set @TenorComposition = @Tenor
							End
							
							EXEC spEPVerifyBatchingUpdate @NPPNo, @InsID, @TenorComposition, @IsComposition, @CovegarePeriodValue, @CovegarePeriodLessThenValue, @RemainingPeriodLessThenValue
							Set @P = 'P4' 
						End
						Else
						Begin
							
							If @CP5 > 0 
							Begin
								Update @TComposition Set CP5 = CP5 - 1
								Where InsPeriodID = @InsPeriodID AND InsID = @InsID
								
								if 60 < @Tenor 
								Begin
									Set @IsComposition = 1
									Set @TenorComposition = 60 
								End
								else
								Begin 
									Set @IsComposition = 0
									Set @TenorComposition = @Tenor
								End
								
								EXEC spEPVerifyBatchingUpdate @NPPNo, @InsID, @TenorComposition, @IsComposition, @CovegarePeriodValue, @CovegarePeriodLessThenValue, @RemainingPeriodLessThenValue 
								Set @P = 'P5'
							End
						End
					End
				End
			End

		END --IF @pivchItemID = '001' -- TIPE MOTOR 
		
		ELSE IF @pivchItemID = '002' -- TIPE MOBIL
		BEGIN
			Set @IsComposition = 0
			Set @TenorComposition = @Tenor
			
			EXEC spEPVerifyBatchingUpdate @NPPNo, @InsID, @TenorComposition, @IsComposition, @CovegarePeriodValue, @CovegarePeriodLessThenValue, @RemainingPeriodLessThenValue 
		END --IF @pivchItemID = '002' -- TIPE MOBIL
	End
	Else
	Begin
	
		Set @IsComposition = 0
		EXEC spEPVerifyBatchingUpdate @NPPNo, @InsID, null, @IsComposition, @CovegarePeriodValue, @CovegarePeriodLessThenValue, @RemainingPeriodLessThenValue
		
	End	

	Fetch Next From GetIns Into
	@NPPNo, @Tenor, @InsPeriodID, @InsID 
End 
Close GetIns
Deallocate GetIns	
ROLLBACK TRAN TEST