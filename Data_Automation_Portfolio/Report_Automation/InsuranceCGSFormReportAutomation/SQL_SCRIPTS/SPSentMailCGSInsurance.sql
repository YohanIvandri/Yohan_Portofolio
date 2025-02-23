BEGIN
set nocount on;
execute as login = 'sa'

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
				where MailID='337'


DECLARE @FilePath VARCHAR(1000),
        @FileNameMPP VARCHAR(1000),
		@FileNameMP VARCHAR(1000),
	    @CompressedFile VARCHAR(MAX),
        @SQL NVARCHAR(MAX)

--EXEC sp_GenMPPAsuransiAll -generate data MPP
--EXEC sp_GenMPAsuransiAll  -Generate Data MP

SET @FilePath  = '\\macf-file\Reporting-HO\Attachment\InsuranceCGS\'
SET @FileNameMPP  = 'InsuranceCGSMPP.csv'
SET @FileNameMP  = 'InsuranceCGSMP.csv'
SET @CompressedFile  = 'ReportCGSInsurance.zip'

SET @SQL = '
exec master..xp_cmdshell ''sqlcmd -S "macf-dbrep" -d "RawDataHO" -U "MACF.DTSAdmin" -P "M@cfDts@dm1n" -Q "EXEC sp_GenMPPAsuransiAll" -o "' + @FilePath + @FileNameMPP + '" -W -s";"''
exec master..xp_cmdshell ''sqlcmd -S "macf-dbrep" -d "RawDataHO" -U "MACF.DTSAdmin" -P "M@cfDts@dm1n" -Q "EXEC sp_GenMPAsuransiAll" -o "' + @FilePath + @FileNameMP + '" -W -s";"''
exec master..xp_cmdshell ''""C:\Program Files\WinRAR\rar.exe" a "'+ @FilePath + @CompressedFile +'" "' + @FilePath + @FileNameMPP + '""''
exec master..xp_cmdshell ''""C:\Program Files\WinRAR\rar.exe" a "'+ @FilePath + @CompressedFile +'" "' + @FilePath + @FileNameMP + '""''
exec master..xp_cmdshell ''Del ' + @FilePath + @FileNameMPP + '''
exec master..xp_cmdshell ''Del ' + @FilePath + @FileNameMP + '''
'
EXEC (@SQL)

	set @Attachments =  @FilePath + @CompressedFile
	--set @MailRecipients='yohan.yuana@mcf.co.id'
	--set @MailCopyRecipients=''
	--set @MailBlindCopyRecipients=''



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

