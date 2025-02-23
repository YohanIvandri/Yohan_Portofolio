
BEGIN
SET NOCOUNT ON;
--SET ANSI_WARNINGS OFF;

if object_id('Tempdb..#LOOP') is not null
 drop table #LOOP
if object_id('Tempdb..#Temp') is not null
 drop table #Temp
if object_id('Tempdb..#DendaBungaTemp') is not null
 drop table #DendaBungaTemp
if object_id('Tempdb..#StatusCGS') is not null
 drop table #StatusCgs
if object_id('Tempdb..#DanaSosial') is not null
 drop table #DanaSosial 
 if object_id('Tempdb..#SocialFund') is not null
 drop table #SocialFund 

 
 Create Table #DendaBungaTemp(
 nppno varchar(10) NOT NULL PRIMARY KEY ,
 OD decimal(18,0), 
 )

Create Table #StatusCgs(
 CGSCABANGNO varchar(10),
 Approvedate datetime,
 AlasanApprove varchar(1000)
 )

 Create Table #DanaSosial(
 NPPNO varchar(10),
 TotalDana INT
 )

Create Table #SocialFund(
 NPPNO varchar(10),
 ODSocialFund INT
 )

Create table #Temp(                                
  nppno varchar(10) NOT NULL PRIMARY KEY,                                
  Period smallint,                                
  J_period smallint,                     
  LPaydate smalldatetime,                                
  JTPaydate smalldatetime,                                
  OP decimal(18,0),                                
  ULI decimal(18,0),                                
  LCR decimal(18,0),                                
  xDay smallint,                                
  dOverDue decimal(18,0),                                
  ParPayment decimal(18,0),          
  byr_denda decimal(18,0),                
  diskon_byr_denda decimal(18,0), --12 Feb 2009   
  M_tunggak smallint, 
  DueLimit decimal(18,0),                                
  OD decimal(18,0),                                
  BungaTunggakan decimal(18,0) --08 Oct 2009                                
  )

SELECT DISTINCT 
ic.nppno
,ic.ApprovalDate 
,cutoff=CASE when approvalDate IS NULL THEN DATEADD(dd,30,acceptdate)                          
			 ELSE CASE WHEN datediff(dd, acceptdate, CONVERT(smalldatetime, approvalDate,112) )<30                               
			 		   THEN DATEADD(dd,30,acceptdate)                              
			 	  ELSE CONVERT(smalldatetime, approvalDate,112) END                               
			 END 
INTO  #LOOP 
FROM  [MACF-DBSTG].REPL_DBKONSOL_EPKONSOLCGS.DBO.[CGS.CGSCabangHdr] cgs
INNER JOIN [MACF-DBSTG].REPL_DBKONSOL_EPKONSOLCGS.DBO.[CGS.CgsDocumentUploadAsuransi] da on da.cgscabangno = cgs.cgscabangno
INNER JOIN  [MACF-DBSTG].[REPL_DBMCF_EPMCF].[dbo].insclaim ic ON ic.nppno = da.nppno
WHERE emaildepartmentid = '00044'  
and cgs.formid = '00288'
AND (
        
        (DATEPART(HOUR, GETDATE()) < 14 -- Generate Jam 07.00 sampai 13.59
         AND CONVERT(DATETIME, Broadcastdate) BETWEEN 
             '2024-01-01 00:00:00' -- Awal tahun 2024
             AND DATEADD(HOUR, 21, CONVERT(DATETIME, CONVERT(VARCHAR(8), GETDATE()-1, 112))) -- Cutoff kemarin jam 21:00
        )
        OR
        (DATEPART(HOUR, GETDATE()) >= 14 -- Generate Jam 14.00
         AND CONVERT(DATETIME, Broadcastdate) BETWEEN 
             '2024-01-01 00:00:00' -- Awal tahun 2024
             AND DATEADD(HOUR, 13, CONVERT(DATETIME, CONVERT(VARCHAR(8), GETDATE(), 112))) -- Cut off hari ini jam 13:00
        )
		)


INSERT INTO #SocialFund
SELECT 
    loo.nppno,
    ODSocialFund = SUM(isnull(sf.SocialFundAmt,0))
FROM #LOOP loo  
INNER JOIN [MACF-DBSTG].[REPL_DBMCF_ECOL].dbo.EC_ARCard a WITH (NOLOCK) ON loo.nppno = a.nppno 
LEFT JOIN [MACF-DBSTG].[REPL_DBMCF_ECOL].dbo.EC_SocialFund sf WITH (NOLOCK) ON a.ARCardId = sf.ARCardId
WHERE sf.PayDate IS NULL 
AND CONVERT(VARCHAR(8), a.CollectionDate, 112) < CONVERT(VARCHAR(8), loo.cutoff, 112)
GROUP BY loo.nppno

DECLARE @danaSosial FLOAT
  SELECT @danaSosial = ValueParameter 
  FROM [MACF-DBSTG].REPL_DBKONSOL_EPROCESS.dbo.EP_GeneralParameter 
  WHERE KodeParameter = 'DANASOSIAL'


INSERT INTO #DanaSosial
SELECT 
    loo.nppno,
    TotalDana = ISNULL(COUNT(
        CASE 
            WHEN CONVERT(VARCHAR(8), a.CollectionDate, 112) < CONVERT(VARCHAR(8), loo.cutoff, 112)
                THEN a.NPPNo 
            ELSE NULL 
        END
    ) * @danaSosial,0)
FROM #LOOP loo  
LEFT JOIN [MACF-DBSTG].[REPL_DBMCF_ECOL].dbo.EC_ARCard a WITH (NOLOCK) ON loo.nppno = a.nppno 
WHERE a.paydate IS NULL  
GROUP BY loo.nppno






DECLARE @sql VARCHAR(MAX),
        @sql2 VARCHAR(MAX),
        @nppno VARCHAR(100),
        @approvalDate VARCHAR(1000);

DECLARE cur_loop CURSOR FOR
SELECT nppno,ApprovalDate
FROM #LOOP

OPEN cur_loop

FETCH NEXT FROM cur_loop INTO @nppno, @approvalDate

WHILE @@FETCH_STATUS = 0
BEGIN
	 SET @sql = '
	            SELECT DISTINCT NppNo, sPeriod, Period, LastPaidDate, DateOfPay, OP, ULI, LCR, day_ODInterest, DayOD,
                Par_payment, PaidLateCharge, DiskonPaidLateCharge, M_tunggak, DueLimit, OD, BungaTunggakan
                FROM OPENQUERY([HFMCF], 
                 ''SELECT * FROM EPMCF.DBO.fnEPASUJTPeriod_tyo(''''' + @nppno + ''''','''''+ @approvalDate + ''''')'')
			   '

     SET @sql2 = '
     			SELECT distinct * FROM OPENQUERY([HFMCF],
                 ''SELECT c.nppno, CASE WHEN c.KodeAngsuran = ''''0001'''' THEN (select DendaBungaMenurun from EPMCF.dbo.fnEPGetDendaBungaMenurun(c.nppno, isnull(ic.InsClaimDate,getdate())))
     			          +(1000-((select DendaBungaMenurun from EPMCF.dbo.fnEPGetDendaBungaMenurun(c.nppno, isnull(ic.InsClaimDate,getdate())))%1000)) 
     			           ELSE null END AS OD
                            FROM EPMCF.dbo.CM c 
     			       INNER JOIN EPMCF.dbo.insclaim ic on ic.nppno = c.nppno
     			                   WHERE c.NPPno  = '''''+@nppno+'''''
     			 '') '

    INSERT INTO #Temp
    EXEC (@sql)

	INSERT INTO #DendaBungaTemp
	EXEC (@sql2)

    FETCH NEXT FROM cur_loop INTO @nppno, @approvalDate
END

CLOSE cur_loop
DEALLOCATE cur_loop

--select * from #Temp order by nppno
--select * from #DendaBungaTemp
--select * from #StatusCgs
--select * from #SocialFund
--select * from #DanaSosial

--Insert ke tabel Fisik
INSERT INTO TB_MPPAsuransiDetail 
SELECT DISTINCT 
[Tanggal Generate] = convert(varchar(10),getdate(),103),
[Nama Konsumen] = l.Lesseename,
[NO NPP] = c.nppno,
[CABANG] = b.branchname,
[TGL Cair Asuransi] = convert(varchar(10),tr.claimdate,103),
[TGL Pengajuan MPP] = convert(varchar(10),cgs.broadcastdate,103),
[TGL Cutoff Masuk Finance] = isnull(REPLACE(REPLACE(REPLACE(isnull(st.alasanapprove,'-'),char(13),''),char(10),''),char(9),''),''),
[TGL Complete] =  isnull(convert(varchar(10),st.approvedate,103),''),
[Nama Bank] = da.bankname,
[NO CGS] = cgs.cgscabangno,
[Deskripsi] = REPLACE(REPLACE(REPLACE(isnull(cgs.description,'-'),char(13),''),char(10),''),char(9),''),
[Status CGS] = mst.cgsstatusname,
[Nomor Rekening] = ''''+da.rekeningnumber,
[Atas Nama] = ''''+da.rekeningname,
[Asuransi] = isnull(m.insname,''),
[Status Termination] = 	CASE tr.statustermination 
		                WHEN '0' THEN 'RFA' 
		                WHEN 'A' THEN 'Approved' 
		                WHEN 'B' THEN 'Cancelled' 
		                WHEN 'D' THEN 'Draft'
						END,
[Nilai Akseptasi] =	isnull(icl.acceptancevalue,0),
[Nilai Akseptasi Cabang] =	icl.acceptancevaluecab,
[Sisa Kewajiban] =   
 ((
  /*Tunggakan		=*/isnull(tm.BungaTunggakan,0)   
  /*BayarDenda		=*/+isnull(tm.byr_denda,0)     
  /*BungaBerjalan	=*/+isnull(   (case when datediff(day,tm.JTPaydate,convert(datetime,icl.approvaldate,112))<=0    
						  then 0                    
						  else round(datediff(day,tm.JTPaydate,convert(datetime,icl.approvaldate,112))*c.effrate/100/360*tm.OP,0)    
						  end),0)                    
  /*SisaPokok		=*/+isnull(tm.OP,0)
  /*ULI				=*/+isnull(tm.ULI,0)
  /*OD				=*/+COALESCE(dbt.OD,tm.OD,0)
  /*PartialPayment	=*/+0
  /*DanaSosial		=*/+(case when c.Fincode = 'US' then isnull(sf.ODSocialFund,0)+isnull(td.TotalDana,0)  else 0 end)
  /*BiayaDueLimit	=*/+isnull(tr.BiayaDueLimit,0)   
 /*BiayaAdministrasi=*/+isnull(tr.BiayaAdministrasi,0)                     
  /*BiayaKlaim		=*/+isnull(tr.BiayaKlaim,0)
  )-(
  /*NilaiDiskonBunga		=*/isnull(tr.NilaiDiskonBunga,0)
  /*NilaiDiskonDendaBunga	=*/+isnull(tr.NilaiDiskonDendaBunga,0)                               
  /*NilaiDiskonBiayaKlaim	=*/+isnull(tr.NilaiDiskonBiayaKlaim,0)                              
  /*NilaiDiskonAdministrasi	=*/+isnull(tr.NilaiDiskonAdministrasi,0)                            
  /*NilaiDiskonDueLimit		=*/+isnull(tr.NilaiDiskonDueLimit,0)                            
  /*NilaiDiskonULI			=*/+isnull(tr.NilaiDiskonULI,0) 
  )),
[Total (yg diterima/dibayarkan konsumen)] =   
  isnull(ti.NilaiSPP,0)-(((
  /*Tunggakan		=*/isnull(tm.BungaTunggakan,0)   
  /*BayarDenda		=*/+isnull(tm.byr_denda,0)     
  /*BungaBerjalan	=*/+isnull(   (case when datediff(day,tm.JTPaydate,convert(datetime,icl.approvaldate,112))<=0    
						  then 0                    
						  else round(datediff(day,tm.JTPaydate,convert(datetime,icl.approvaldate,112))*c.effrate/100/360*tm.OP,0)    
						  end),0)                    
  /*SisaPokok		=*/+isnull(tm.OP,0)
  /*ULI				=*/+isnull(tm.ULI,0)
  /*OD				=*/+COALESCE(dbt.OD,tm.OD,0)
  /*PartialPayment	=*/+0
  /*DanaSosial		=*/+(case when c.Fincode = 'US' then isnull(sf.ODSocialFund,0)+isnull(td.TotalDana,0)  else 0 end)
  /*BiayaDueLimit	=*/+isnull(tr.BiayaDueLimit,0)   
 /*BiayaAdministrasi=*/+isnull(tr.BiayaAdministrasi,0)                     
  /*BiayaKlaim		=*/+isnull(tr.BiayaKlaim,0)
  )-(
  /*NilaiDiskonBunga		=*/isnull(tr.NilaiDiskonBunga,0)
  /*NilaiDiskonDendaBunga	=*/+isnull(tr.NilaiDiskonDendaBunga,0)                               
  /*NilaiDiskonBiayaKlaim	=*/+isnull(tr.NilaiDiskonBiayaKlaim,0)                              
  /*NilaiDiskonAdministrasi	=*/+isnull(tr.NilaiDiskonAdministrasi,0)                            
  /*NilaiDiskonDueLimit		=*/+isnull(tr.NilaiDiskonDueLimit,0)                            
  /*NilaiDiskonULI			=*/+isnull(tr.NilaiDiskonULI,0) 
  )) - isnull(ti.AkseptasiCab,0))


FROM #temp tm 
INNER JOIN [MACF-DBSTG].[REPL_DBMCF_EPMCF].dbo.CM c on c.nppno = tm.nppno
INNER JOIN [MACF-DBSTG].[REPL_DBMCF_EPMCF].dbo.lessee l on l.lesseeno = c.lesseeno
INNER JOIN [MACF-DBSTG].REPL_DBKONSOL_EPKONSOLCGS.DBO.[CGS.CgsDocumentUploadAsuransi] da on da.nppno = tm.nppno
INNER JOIN [MACF-DBSTG].REPL_DBKONSOL_EPKONSOLCGS.DBO.[CGS.CGSCabangHdr] cgs on cgs.cgscabangno = da.cgscabangno
LEFT JOIN  #DendaBungaTemp dbt on dbt.nppno = tm.nppno
LEFT JOIN  [MACF-DBSTG].[REPL_DBMCF_MACFDB].dbo.SYSGFCompanyBranch b on b.branchid = c.branchid
LEFT JOIN  [MACF-DBSTG].[REPL_DBMCF_EPMCF].dbo.termination tr on tr.nppno = tm.nppno and tr.statustermination not in('R','B') and tr.terminationcode = 2
LEFT JOIN  [MACF-DBSTG].REPL_DBKONSOL_EPKONSOLCGS.DBO.[CGS.MsStatus] mst on mst.cgsstatusid = cgs.status
LEFT JOIN  [MACF-DBSTG].[REPL_DBMCF_EPMCF].dbo.inscoverdtl icd on icd.nppno = tm.nppno
LEFT JOIN  [MACF-DBSTG].[REPL_DBMCF_EPMCF].dbo.inscoverhdr ich on ich.nosuratcover = icd.nosuratcover
LEFT JOIN  [MACF-DBSTG].[REPL_DBMCF_EPMCF].dbo.msptinsurance m on m.insid = ich.insid
LEFT JOIN  [MACF-DBSTG].[REPL_DBMCF_EPMCF].[dbo].insclaim icl ON icl.nppno = tm.nppno
LEFT JOIN  [MACF-DBSTG].[REPL_DBMCF_EPMCF].[dbo].TerminationInsurance ti with(nolock) on ti.ClaimNo=tr.ClaimNo
LEFT JOIN  HFEPRO.EPKONSOLCGS.DBO.[CGS.Status] st on st.cgscabangno = cgs.cgscabangno AND st.isapprove = 1 AND  st.status = 'M' 
LEFT JOIN  #SocialFund sf on sf.nppno = tm.nppno
LEFT JOIN  #DanaSosial td on td.nppno = tm.nppno
WHERE cgs.Status not in('C','R','D') AND cgs.broadcastdate IS NOT NULL
END




