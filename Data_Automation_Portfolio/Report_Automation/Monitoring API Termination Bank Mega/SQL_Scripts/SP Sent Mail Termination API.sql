
/**Created BY Yohan 10-06-2024**/

BEGIN
DECLARE @html AS TABLE (Nomor int identity, html varchar(max))
DECLARE @sql varchar(max), @CurrRec int, @TotRec int, @MsgBody1 varchar(max), @MsgHdr1 varchar(max), @MsgFtr varchar(max)
, @MsgContent1 varchar(max)='', @MailBody varchar(max), @ProfileName varchar(max), @BodyFormat varchar(max), @Subject varchar(max)
, @MailRecipients varchar(max), @MailCopyRecipients varchar(max), @MailBlindCopyRecipients varchar(max), @Attachments varchar(max)
, @PT varchar(10), @Tanggal varchar(10),@1 varchar(10),@2 varchar(10),@3 varchar(10),@4 varchar(10)
,@5 varchar(10),@6 varchar(10),@7 varchar(10),@8 varchar(10)

set nocount on;
execute as login='sa';

if object_id('Tempdb..#CompareCreated') is not null drop table #CompareCreated
if object_id('Tempdb..#dataCreated') is not null drop table #dataCreated
if object_id('Tempdb..#dataReason') is not null drop table #dataReason
if object_id('Tempdb..#recap') is not null drop table #recap

--CREATED--
select * into #dataCreated from OPENQUERY([192.168.3.96],'
select ts.pt,ts.nppno,ts.batchPeriod,ts.itemID,ts.iscomplete,d.batchID, d.isSentPaid 
from JFMega.dbo.terminationSchedule ts
LEFT join JFMega.dbo.JF_TerminationMega_Detail d on ts.nppno = d.cifIdDebitur and substring(d.batchID,5,8) = ts.batchPeriod
where convert(varchar(6),ts.batchPeriod,112) = convert(varchar(6),getdate(),112)
order by ts.batchPeriod, ts.nppno
')

--COMPARED--
select pt, nppno, itemID, batchPeriod, created=count(distinct BatchId), Sent=sum(iif(isSentPaid = 1,1,0))
	into #compareCreated
	from #dataCreated 
		group by pt,nppno,itemID,batchPeriod

--DATAREASON/FEEDBACK--
select * into #dataReason from OPENQUERY([192.168.3.96],'
with dataCreated as (
	select ts.pt,ts.nppno,ts.batchPeriod,ts.itemID,ts.iscomplete,d.batchID, d.isSentPaid 
	from JFMega.dbo.terminationSchedule ts
	inner join JFMega.dbo.JF_TerminationMega_Detail d on ts.nppno = d.cifIdDebitur and substring(d.batchID,5,8) = ts.batchPeriod
	where convert(varchar(6),ts.batchPeriod,112) = convert(varchar(6),getdate(),112)
), compareCreated as (
	select pt, nppno, itemID, batchPeriod, created=count(distinct BatchId), Sent=sum(iif(isSentPaid = 1,1,0))
	from dataCreated 
	group by pt,nppno,itemID,batchPeriod
)
select rc.PT, rc.nppno, rc.batchPeriod , rc.BatchId, NoResponse = iif(isnull(r.cifiddebitur,'''') = '''',1,0) 
from datacreated rc
inner join (select * from compareCreated 
			where batchPeriod <= convert(varchar(8),getdate(),112)) cc on rc.nppno = cc.nppno and rc.batchPeriod = cc.batchPeriod
left join JFMega.dbo.JF_TerminationMega_Feedback_Detail r on r.cifIdDebitur = rc.nppno and rc.BatchId = r.batchId
	where rc.batchPeriod <= convert(varchar(8),getdate(),112)
')

--FINAL RECAP--
select  No = row_number()over(partition by a.pt order by a.pt,a.batchPeriod),* into #recap from (
select a.pt, a.batchPeriod, a.npp, a.Created, NotCreated = a.npp - a.Created
		, a.Sent, NotSent = a.nppsent - a.Sent, NoResponse=b.NoResponse from (
select pt, batchPeriod, NPP=count(created), Created=sum(created), nppsent = count(sent), Sent = sum(sent)
	from #CompareCreated
	where batchPeriod <= convert(varchar(8),getdate(),112)
		group by pt, batchPeriod
		--order by pt, batchPeriod
		) a
left join (
select pt, batchPeriod, NoResponse = sum(NoResponse) from #dataReason group by pt,batchPeriod
) b on a.pt = b.pt and a.batchPeriod = b.batchPeriod
) a



set @MsgBody1 = ''

set @MsgHdr1=
'<html>
<head>
<style type="text/css">
	.table{
		background-color: #F5F5F5;
		border-collapse: collapse;
		font-size: 12px;
		font-family: "Verdana";}

	.table .title{
		text-align: center;
		background-color: #3399FF;
		color:white;
		font-weight:bold;}

	.table .head{
		text-align: center;
		background-color: #FFCC00;}

	.table td{
		padding: 5px;
		width: 100px;
		border: solid 1px #555;}
                        
	.table .bad{
		text-align: center;
		background-color: #FF69B4;}
						
	.table .warning{
		text-align: center;
		background-color: #FFFF00;}

	.table .good{
		text-align: center;
		background-color: #7FFF00;}
					
	.red {
		padding: 5px;
		border: solid 1px #555;
		text-align: center;
		background-color: #ffbdbd;
		color: #FF3333;
		font-weight: bold;
		}
</style>
</head>

<body>
<br>
<table ID="Mega KV MCF" class="table">
	<tr>
		<td colspan="8" class="title" align=center> <b>Termination API Mega Konven MCF</b> </td>
	</tr>
	<tr>
		<td colspan="1" class="title" align=center> <b>Tanggal</b> </td>
		<td colspan="1" class="title" align=center> <b>NPP</b> </td>
		<td colspan="1" class="title" align=center> <b>Created</b> </td>
		<td colspan="1" class="title" align=center> <b>NotCreated</b> </td>
		<td colspan="1" class="title" align=center> <b>Sent</b> </td>
		<td colspan="1" class="title" align=center> <b>Not Sent</b> </td>
		<td colspan="1" class="title" align=center> <b>No Response</b> </td>
	</tr>
'

--- MailBody1 ---

select @TotRec=count(*) from #recap WHERE PT = 'MCF'
set @CurrRec = 1
while @CurrRec <= @TotRec
	begin
		select 
			@Tanggal=batchPeriod
			,@1=NPP,@2=Created,@3=NotCreated
			,@4=Sent,@5=NotSent
			,@7=NoResponse
		from #recap
		where No = @CurrRec and PT = 'MCF'
    																
		SET @MsgContent1 = @MsgContent1 + 
'<tr>
<td class="head" align=center>'+@tanggal+'</td>
<td class="td" align=center>'    +isnull(@1 ,0)+'</td>
<td class="td" align=center>'    +isnull(@2 ,0)+'</td>
<td class="td red" align=center>'+isnull(@3 ,0)+'</td>
<td class="td" align=center>'    +isnull(@4 ,0)+'</td>
<td class="td red" align=center>'    +isnull(@5 ,0)+'</td>
<td class="td red" align=center>'    +isnull(@7 ,0)+'</td>
</tr>
'
	--INSERT INTO @html select @MsgContent1
	set @CurrRec = @CurrRec+1
end

set @MsgContent1 = @MsgContent1 + '</table>
<br/><br/>
<table ID="Mega KV MAF" class="table">
	<tr>
		<td colspan="10" class="title" align=center> <b>Termination API Mega Konven MAF</b> </td>
	</tr>
	<tr>
		<td colspan="1" class="title" align=center> <b>Tanggal</b> </td>
		<td colspan="1" class="title" align=center> <b>NPP</b> </td>
		<td colspan="1" class="title" align=center> <b>Created</b> </td>
		<td colspan="1" class="title" align=center> <b>NotCreated</b> </td>
		<td colspan="1" class="title" align=center> <b>Sent</b> </td>
		<td colspan="1" class="title" align=center> <b>Not Sent</b> </td>
		<td colspan="1" class="title" align=center> <b>No Response</b> </td>
	</tr>
'

select @TotRec=count(*) from #recap WHERE PT = 'MAF'
set @CurrRec = 1
while @CurrRec <= @TotRec
	begin
		select 
			@Tanggal=batchPeriod
			,@1=NPP,@2=Created,@3=NotCreated
			,@4=Sent,@5=NotSent
			,@7=NoResponse
		from #recap
		where No = @CurrRec AND PT = 'MAF'
    																
		SET @MsgContent1 = @MsgContent1 + 
'<tr>
<td class="head" align=center>'+@tanggal+'</td>
<td class="td" align=center>'    +isnull(@1 ,0)+'</td>
<td class="td" align=center>'    +isnull(@2 ,0)+'</td>
<td class="td red" align=center>'+isnull(@3 ,0)+'</td>
<td class="td" align=center>'    +isnull(@4 ,0)+'</td>
<td class="td red" align=center>'    +isnull(@5 ,0)+'</td>
<td class="td red" align=center>'    +isnull(@7 ,0)+'</td>
</tr>
'
	--INSERT INTO @html select @MsgContent1
	set @CurrRec = @CurrRec+1
end

set @MsgFtr = 
'</table>
<br>
<br>
<!-- TABLE INFO GENERATE -->
<table ID="InfoGenerate" class="table">		
<tr>
<td colspan="7" class="head" style="width: 300px;"> <i> Generated on :   ' + convert(varchar(12),getdate(),106) + space(4) + convert(varchar(12),getdate(),108) + space(10) +' </i></td>
</tr>
</table>
</body>
</html>'


--print (@MsgHdr1)
--print (left(@MsgContent1,8000))
--print (substring(@MsgContent1,8001,8000))
--print (@msgftr)

EXECUTE AS LOGIN = 'sa'

select @ProfileName=ProfileName, @BodyFormat=BodyFormat, @Subject=Subject, 
		   @MailRecipients=MailRecipients, @MailCopyRecipients=MailCopyRecipients, 
		   @MailBlindCopyRecipients=BlindCopyRecipients,  @Attachments = ''
		   from MailInfo.dbo.SysMail 
			    where MailID='323'

--select @MailRecipients            = 'it-mis@mcf.co.id'--MailRecipients
--		, @MailCopyRecipients     = ''--MailCopyRecipients
--		, @MailBlindCopyRecipients= ''--BlindCopyRecipients

set @MailBody = @MsgHdr1+@MsgContent1+@MsgFtr
--print (@mailBody)

if(@mailRecipients <> '')
	begin
		EXEC msdb.dbo.sp_send_dbmail
		@profile_name=@ProfileName,  
		@recipients=@MailRecipients,
		@copy_recipients=@MailCopyRecipients, 
		@blind_copy_recipients=@MailBlindCopyRecipients,
		@subject=@Subject,
		@body=@MailBody,
		@body_format = @BodyFormat,
		@file_attachments = @Attachments
	end


if object_id('Tempdb..#CompareCreated') is not null drop table #CompareCreated
if object_id('Tempdb..#dataCreated') is not null drop table #dataCreated
if object_id('Tempdb..#dataReason') is not null drop table #dataReason
if object_id('Tempdb..#recap') is not null drop table #recap


END