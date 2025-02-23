
BEGIN 
TRUNCATE TABLE TB_MPPAsuransiDetail

exec sp_GenMPPAsuransi_MCF
exec sp_GenMPPAsuransi_MAF

select  ROW_NUMBER() OVER (ORDER BY [TGL Pengajuan MPP] DESC) AS NO,
* from TB_MPPAsuransiDetail
END


--EXEC sp_GenMPPAsuransiAll