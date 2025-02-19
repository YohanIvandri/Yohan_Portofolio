--ALTER PROCEDURE sp_MonitoringNominalPremiDebitur

--AS

BEGIN
set nocount on;
DECLARE @ProfileName varchar(20), 
		@BodyFormat varchar(20), 
		@MailBody varchar(max),
		@Subject varchar(50),
		@mailRecipients varchar(max),
		@mailCopyRecipients varchar(max),
		@mailBlindCopyRecipients varchar(max),
		@Attachments varchar(max)

select @ProfileName=ProfileName, @BodyFormat=BodyFormat, @Subject=Subject, 
		   @MailRecipients=MailRecipients, @MailCopyRecipients=MailCopyRecipients, 
		   @MailBlindCopyRecipients=BlindCopyRecipients 
		   from MailInfo.dbo.SysMail 
				where MailID='336'


DECLARE @FilePath VARCHAR(1000),
        @FileNameMAF VARCHAR(1000),
		@FileNameMCF VARCHAR(1000),
	    @CompressedFile VARCHAR(MAX),
        @SQL NVARCHAR(MAX)

--EXEC sp_GenInsPremiDiff 'MCF' /**SP UNTUK GENERATE DATA**/
--EXEC sp_GenInsPremiDiff 'MAF'

SET @FilePath  = '\\macf-file\Reporting-HO\Attachment\InsurancePremiDiff\'
SET @FileNameMAF  = 'InsurancePremiDiff_MAF.csv'
SET @FileNameMCF  = 'InsurancePremiDiff_MCF.csv'
SET @CompressedFile  = 'InsurancePremiDiff.zip'

SET @SQL = '
exec master..xp_cmdshell ''sqlcmd -S "macf-dbrep" -d "RawDataHO" -U "MACF.DTSAdmin" -P "M@cfDts@dm1n" -Q "EXEC sp_GenInsPremiDiff ''''MAF''''" -o "' + @FilePath + @FileNameMAF + '" -W -s";"''
exec master..xp_cmdshell ''sqlcmd -S "macf-dbrep" -d "RawDataHO" -U "MACF.DTSAdmin" -P "M@cfDts@dm1n" -Q "EXEC sp_GenInsPremiDiff ''''MCF''''" -o "' + @FilePath + @FileNameMCF + '" -W -s";"''
exec master..xp_cmdshell ''""C:\Program Files\WinRAR\rar.exe" a "'+ @FilePath + @CompressedFile +'" "' + @FilePath + @FileNameMAF + '""''
exec master..xp_cmdshell ''""C:\Program Files\WinRAR\rar.exe" a "'+ @FilePath + @CompressedFile +'" "' + @FilePath + @FileNameMCF + '""''
exec master..xp_cmdshell ''Del ' + @FilePath + @FileNameMAF + '''
exec master..xp_cmdshell ''Del ' + @FilePath + @FileNameMCF + '''
'
EXEC (@SQL)

	set @Attachments =  @FilePath + @CompressedFile 


	if(@mailRecipients <> '')
		begin
			EXEC msdb.dbo.sp_send_dbmail
			@profile_name=@ProfileName,  ---- 'DBMail' == >UAT
			@recipients=@MailRecipients,
			@copy_recipients=@MailCopyRecipients, 
			@blind_copy_recipients=@MailBlindCopyRecipients,
			@subject=@Subject,
			@body=@MailBody,
			@body_format = @BodyFormat,
			@file_attachments = @Attachments
		END

END