DECLARE @awalBulan VARCHAR(8), @akhirBulan VARCHAR(8), @sql VARCHAR(MAX)


SET @awalBulan = CONVERT(VARCHAR(8), DATEADD(DAY, 1 - DAY(DATEADD(MONTH, -1, GETDATE())), DATEADD(MONTH, -1, GETDATE())), 112)
SET @akhirBulan = CONVERT(VARCHAR(8), EOMONTH(DATEADD(MONTH, -1, GETDATE())), 112)


IF OBJECT_ID('tempdb..#tempRegional') IS NOT NULL DROP TABLE #tempRegional
IF OBJECT_ID('tempdb..#ODBranch') IS NOT NULL DROP TABLE #ODBranch
IF OBJECT_ID('tempdb..#ODBranchtemp') IS NOT NULL DROP TABLE #ODBranchtemp
IF OBJECT_ID('tempdb..#ODParentBranchtemp') IS NOT NULL DROP TABLE #ODParentBranchtemp

CREATE TABLE #ODBranch (
    BranchID VARCHAR(10),
    BranchName VARCHAR(100),
    AwalBulanNPPaktif INT,
    AwalBulanNPPod INT,
    AkhirBulanNPPaktif INT,
    AkhirBulanNPPod INT,
)


SELECT b.branchid, b.branchName, a.areaid, a.areaname, r.regionalid, r.wilayahid, r.wilayahname
INTO #tempRegional
FROM [MACF-DBSTG].[REPL_DBMCF_MACFDB].dbo.SysGFCompanyBranch b
INNER JOIN [MACF-DBSTG].[REPL_DBMCF_MACFDB].dbo.SysGFCompanyArea a ON b.areaid = a.areaid AND b.CompanyID = a.CompanyID
INNER JOIN [MACF-DBSTG].[REPL_DBMCF_MACFDB].dbo.SysGFCompanyRegional r ON a.regionalid = r.regionalid AND r.CompanyID = a.CompanyID
INNER JOIN [MACF-DBSTG].DUMP_MACF.dbo.SYSGFCompanyBranchR2_Oct22 br ON br.BranchId = b.BranchId 
WHERE a.IsActive = '1' AND b.IsActive = '1'
AND r.WilayahID IN ('1','2','6')
AND r.RegionalID NOT IN ('1','18','27','7','28')

SET @sql = '
INSERT INTO #ODBranch(BranchID, BranchName, AwalBulanNPPaktif, AwalBulanNPPod)
SELECT r.BranchID, r.BranchName,
       COUNT(od.NppNo) AS NPPAktif,
       SUM(CASE WHEN od.od > 0 THEN 1 ELSE 0 END) AS NPPOD
FROM ODHistoryDetail_' + LEFT(@awalBulan,6) + ' od WITH(NOLOCK) 
INNER JOIN #tempRegional r WITH(NOLOCK) ON od.branchid = r.branchid
WHERE od.oddate = CONVERT(VARCHAR(8), ' + @awalBulan + ', 112) AND od.OpenClose = ''0''
GROUP BY r.BranchID, r.BranchName

INSERT INTO #ODBranch(BranchID, BranchName, AkhirBulanNPPaktif, AkhirBulanNPPod)
SELECT r.BranchID, r.BranchName,
       COUNT(od.NppNo) AS NPPAktif,
       SUM(CASE WHEN od.od > 0 THEN 1 ELSE 0 END) AS NPPOD
FROM ODHistoryDetail_' + LEFT(@akhirBulan,6) + ' od WITH(NOLOCK) 
INNER JOIN #tempRegional r WITH(NOLOCK) ON od.branchid = r.branchid
WHERE od.oddate = CONVERT(VARCHAR(8), ' + @akhirBulan + ', 112) AND od.OpenClose = ''0''
GROUP BY r.BranchID, r.BranchName
'

EXEC (@sql)
--print( @sql)

SELECT 
    BranchID = a.BranchID, 
    BranchName = CASE 
        WHEN mb.BranchName2W LIKE '%Bandar Lampung%' OR mb.BranchName2W LIKE '%Batam%' 
        THEN UPPER(ISNULL(mb.BranchName2W, a.BranchName))
        ELSE UPPER(ISNULL(REPLACE(REPLACE(mb.BranchName2W, 'MCF', ''), 'MAF', ''), REPLACE(REPLACE(a.BranchName, 'MCF', ''), 'MAF', '')))
    END,
    AwalBulanNPPaktif = SUM(AwalBulanNPPaktif), 
    AwalBulanNPPod = SUM(AwalBulanNPPod), 
    AkhirBulanNPPaktif = SUM(AkhirBulanNPPaktif), 
    AkhirBulanNPPod = SUM(AkhirBulanNPPod)
INTO #ODBranchtemp
FROM #ODBranch a
LEFT JOIN [MACF-DBSTG].[REPL_DBMCF_MACFDB].dbo.MsBranch mb WITH (NOLOCK) ON mb.Branchid = a.Branchid 
GROUP BY a.BranchID, mb.BranchName2W, a.BranchName
ORDER BY CAST(a.BranchID AS INT)

-- Generate Data OD
SELECT 
    c.BranchID,
    ParentBranchName = CASE 
        WHEN c.branchname LIKE '%Bandar Lampung%' OR c.branchname LIKE '%Batam%' 
        THEN UPPER(c.branchname)
        ELSE UPPER(REPLACE(REPLACE(c.branchname, 'MCF',''), 'MAF', ''))
    END,
    BranchName = CASE 
        WHEN mb.BranchName2W LIKE '%Bandar Lampung%' OR mb.BranchName2W LIKE '%Batam%' 
        THEN UPPER(ISNULL(mb.BranchName2W, c.branchname))
        ELSE UPPER(ISNULL(REPLACE(REPLACE(mb.BranchName2W, 'MCF',''), 'MAF', ''), REPLACE(REPLACE(c.branchname, 'MCF',''), 'MAF', '')))
    END,
    AwalBulanNPPaktif = ISNULL(SUM(AwalBulanNPPaktif), 0),
    AwalBulanNPPod = ISNULL(SUM(AwalBulanNPPod), 0),
    AkhirBulanNPPaktif = ISNULL(SUM(AkhirBulanNPPaktif), 0),
    AkhirBulanNPPod = ISNULL(SUM(AkhirBulanNPPod), 0)
INTO #ODParentBranchtemp
FROM #ODBranchtemp a
INNER JOIN [MACF-DBSTG].[REPL_DBMCF_MACFDB].dbo.sysgfcompanybranch b WITH (NOLOCK) ON b.BranchID = a.BranchID 
INNER JOIN #tempregional c WITH (NOLOCK) ON c.BranchID = b.KonsolBranchID
LEFT JOIN [MACF-DBSTG].[REPL_DBMCF_MACFDB].dbo.MsBranch mb WITH (NOLOCK) ON mb.Branchid = b.Branchid
GROUP BY c.BranchID, c.BranchName, mb.BranchName2W
ORDER BY c.branchname


--FInal Cleansing Group by Parentbranch
select 'OD'
SELECT 
    BranchID,
    ParentBranchName ,
    BranchName ,
    AwalBulanNPPaktif = ISNULL(SUM(AwalBulanNPPaktif), 0),
    AwalBulanNPPod = ISNULL(SUM(AwalBulanNPPod), 0),
    AkhirBulanNPPaktif = ISNULL(SUM(AkhirBulanNPPaktif), 0),
    AkhirBulanNPPod = ISNULL(SUM(AkhirBulanNPPod), 0)

FROM #ODParentBranchtemp 
GROUP BY BranchID, ParentBranchName, BranchName
ORDER BY branchname


--Buat Master Parentbranch 
select 'Master Branch'
SELECT distinct 
    c.BranchID,
    ParentBranchName = CASE 
        WHEN c.branchname LIKE '%Bandar Lampung%' OR c.branchname LIKE '%Batam%' 
        THEN UPPER(c.branchname)
        ELSE UPPER(REPLACE(REPLACE(c.branchname, 'MCF',''), 'MAF', ''))
    END

FROM #ODBranchtemp a
INNER JOIN [MACF-DBSTG].[REPL_DBMCF_MACFDB].dbo.sysgfcompanybranch b WITH (NOLOCK) ON b.BranchID = a.BranchID 
INNER JOIN #tempregional c WITH (NOLOCK) ON c.BranchID = b.KonsolBranchID
LEFT JOIN [MACF-DBSTG].[REPL_DBMCF_MACFDB].dbo.MsBranch mb WITH (NOLOCK) ON mb.Branchid = b.Branchid
