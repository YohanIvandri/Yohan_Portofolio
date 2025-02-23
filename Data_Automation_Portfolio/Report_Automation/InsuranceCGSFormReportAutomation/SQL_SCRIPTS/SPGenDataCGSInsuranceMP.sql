BEGIN
set nocount on;
SELECT DISTINCT
ROW_NUMBER() OVER (ORDER BY cgs.broadcastdate DESC) AS NO,
[Tanggal Generate] = convert(varchar(10),getdate(),103),
[TGL Pengajuan MP] = convert(varchar(10),cgs.broadcastdate,103),
[Nama Memo]  = REPLACE(REPLACE(REPLACE(isnull(cgs.namamemo,'-'),char(13),''),char(10),''),char(9),''),
[Keterangan Complete] = isnull(st.alasanapprove,''),
[TGL Complete] =  isnull(convert(varchar(10),st.approvedate,103),''),
[NO CGS] = cgs.cgscabangno,
[Status CGS] = mst.cgsstatusname

FROM [MACF-DBSTG].REPL_DBKONSOL_EPKONSOLCGS.DBO.[CGS.CGSCabangHdr] cgs 
LEFT JOIN  [MACF-DBSTG].REPL_DBKONSOL_EPKONSOLCGS.DBO.[CGS.MsStatus] mst on mst.cgsstatusid = cgs.status
LEFT JOIN  HFEPRO.EPKONSOLCGS.DBO.[CGS.Status] st on st.cgscabangno = cgs.cgscabangno AND st.isapprove = 1 AND  st.status = 'M' 
WHERE cgs.Status not in('C','R') 
and emaildepartmentid = '00044'  
and cgs.formid = '00286'
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
END


