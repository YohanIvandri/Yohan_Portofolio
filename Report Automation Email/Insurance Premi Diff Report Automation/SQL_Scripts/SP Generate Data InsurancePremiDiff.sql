--ALTER procedure sp_GenInsPremiDiff (@PT varchar(100)) -- MAF/MCF

--AS

DECLARE --@PT VARCHAR(3) = 'MAF',
	    @SQl VARCHAR (MAX)
BEGIN
SET @SQL = '
select * from OPENQUERY([macf-dbstg],''

WITH RankedBilling AS (
    SELECT ibd.*,
           ROW_NUMBER() OVER (PARTITION BY ibd.nppno 
                              ORDER BY 
                              CASE 
                                  WHEN CAST(status AS VARCHAR) = ''''A'''' THEN 1
								  WHEN CAST(status AS VARCHAR) = ''''0'''' THEN 2
								  ELSE 3
                              END) AS rn
    FROM REPL_DB'+@PT+'_EP'+@PT+'.dbo.insbilling i
	INNER JOIN REPL_DB'+@PT+'_EP'+@PT+'.dbo.insbillingdtl ibd on ibd.billingno = i.billingno
	WHERE i.Status <> ''''R''''
)
, FilteredBilling AS (
    SELECT *
    FROM RankedBilling
    WHERE rn = 1
  )

select 
[NO] = ROW_NUMBER() OVER (ORDER BY ibd.nppno),
[PT] = IIF(c.companyid = ''''3'''',''''MCF'''',''''MAF''''),
[R2/R4] = IIF(c.ItemID = ''''002'''', ''''MOBIL'''', ''''MOTOR''''),
[KETERANGAN NEW, USED, MS] = case when c.tipeaplikasiID = ''''00009'''' then ''''MS''''
							 else case when cast(c.IsItemNew as char) = ''''1'''' then ''''BARU'''' else ''''BEKAS'''' end end,
[NPP] = ibd.NPPNO,
[NAMA KONSUMEN] = l.lesseename,
[COVER ASURANSI] =  CONVERT(VARCHAR(10),ich.DtmCrt,103),
[TGL APPROVE NPP] = CONVERT(VARCHAR(10),n.approvedate,103),
[NAMA ASURANSI] = UPPER(m.insname),
[NILAI ASURANSI CM] = coalesce(ck.KreditFee,c.InsuranceFee,0),
[NILAI ASURANSI CAS] = coalesce(cs.lossfee,cas.insurancefee,0),
[PREMI GROSS] = iif(isnull(ibd.PremiGross,0) = 0,iif(c.itemid = ''''001'''',id.InsPremi,id.InsPremi/0.75),isnull(ibd.PremiGross,0)),
[PREMI NETT]  = iif(isnull(ibd.PremiGross,0) = 0,iif(c.itemid = ''''001'''',id.InsPremi,id.InsPremi*0.75),isnull((ibd.PremiGross-ibd.PremiDisc)-ibd.PremiPPN+ibd.PremiPPh,0)),
[DIFF] = iif(isnull(ibd.PremiGross,0) = 0,coalesce(ck.KreditFee,c.InsuranceFee,0 ) - iif(c.itemid = ''''001'''',id.InsPremi,id.InsPremi/0.75),coalesce(ck.KreditFee,c.InsuranceFee,0) - isnull(ibd.PremiGross,0))
FROM FilteredBilling ibd
INNER JOIN REPL_DB'+@PT+'_EP'+@PT+'.dbo.InsDeferredPremi id on id.nppno = ibd.nppno
INNER JOIN REPL_DBMCF_MACFDB.dbo.CFCM c on ibd.nppno = c.agreementnumber
INNER JOIN REPL_DB'+@PT+'_EP'+@PT+'.dbo.NPP n on c.agreementnumber = n.nppno
INNER JOIN REPL_DB'+@PT+'_EP'+@PT+'.dbo.Lessee l on c.customerno = l.lesseeno
INNER JOIN REPL_DBMCF_MACFDB.dbo.CFcas cas on cas.casid = c.casid
LEFT JOIN  REPL_DB'+@PT+'_EP'+@PT+'.dbo.InsCoverDtl icd on icd.nppno = c.AgreementNumber
LEFT JOIN  REPL_DB'+@PT+'_EP'+@PT+'.dbo.Inscoverhdr ich on ich.nosuratcover = icd.nosuratcover
LEFT JOIN  REPL_DB'+@PT+'_EP'+@PT+'.dbo.MsPTInsurance m on m.insid = ich.insid
LEFT JOIN REPL_DBMCF_MACFDB.dbo.CFCM_Insurance_Kredit ck on c.cmno = ck.CMNo
LEFT JOIN REPL_DBMCF_MACFDB.dbo.CFCAS_Insurance_Kredit cs on cs.casid = cas.CASId
WHERE CONVERT(VARCHAR(8),ibd.dtmcrt,112) BETWEEN CONVERT(VARCHAR(6),EOMONTH(GETDATE(),-1),112) + ''''01'''' AND CONVERT(VARCHAR(8),GETDATE()-1,112)
order by ibd.nppno
'')'

EXEC(@SQl)
END