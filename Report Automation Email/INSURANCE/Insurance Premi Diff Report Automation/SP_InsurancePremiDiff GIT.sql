ALTER PROCEDURE sp_GenInsPremiDiff (@CompanyCode VARCHAR(100))
AS
DECLARE @SQL VARCHAR(MAX)
BEGIN
    SET @SQL = '
    SELECT * FROM OPENQUERY([DB-MIRROR],''
    WITH RankedBilling AS (
        SELECT ibd.*, ROW_NUMBER() OVER (PARTITION BY ibd.ContractNo ORDER BY 
            CASE 
                WHEN CAST(Status AS VARCHAR) = ''''A'''' THEN 1
                WHEN CAST(Status AS VARCHAR) = ''''0'''' THEN 2
                ELSE 3
            END) AS rn
        FROM DB_' + @CompanyCode + '_EP.dbo.InsuranceBillingHeader i
        INNER JOIN DB_' + @CompanyCode + '_EP.dbo.InsuranceBillingDetail ibd ON ibd.BillingNo = i.BillingNo
        WHERE i.Status <> ''''R''''
    ),
    FilteredBilling AS (
        SELECT * FROM RankedBilling WHERE rn = 1
    )
    
    SELECT 
        ROW_NUMBER() OVER (ORDER BY ibd.ContractNo) AS RowNum,
        IIF(c.CompanyID = ''''3'''', ''''CompanyA'''', ''''CompanyB'''') AS Company,
        IIF(c.ItemType = ''''002'''', ''''Car'''', ''''Motorcycle'''') AS VehicleType,
        CASE 
            WHEN c.ApplicationType = ''''00009'''' THEN ''''Special''''
            ELSE CASE WHEN CAST(c.IsNewItem AS CHAR) = ''''1'''' THEN ''''New'''' ELSE ''''Used'''' END
        END AS Description,
        ibd.ContractNo AS ContractNumber,
        l.CustomerName,
        CONVERT(VARCHAR(10), ich.CreatedDate, 103) AS InsuranceCoverageDate,
        CONVERT(VARCHAR(10), n.ApprovalDate, 103) AS ApprovalDate,
        UPPER(m.InsuranceName) AS InsuranceProvider,
        COALESCE(ck.CreditFee, c.InsuranceFee, 0) AS InsuranceValue,
        IIF(ISNULL(ibd.PremiumGross, 0) = 0, IIF(c.ItemType = ''''001'''', id.Premium, id.Premium / 0.75), ISNULL(ibd.PremiumGross, 0)) AS PremiumGross,
        IIF(ISNULL(ibd.PremiumGross, 0) = 0, IIF(c.ItemType = ''''001'''', id.Premium, id.Premium * 0.75), ISNULL((ibd.PremiumGross - ibd.PremiumDiscount - ibd.PremiumTax + ibd.PremiumDeductions), 0)) AS PremiumNett,
        IIF(ISNULL(ibd.PremiumGross, 0) = 0, COALESCE(ck.CreditFee, c.InsuranceFee, 0) - IIF(c.ItemType = ''''001'''', id.Premium, id.Premium / 0.75), COALESCE(ck.CreditFee, c.InsuranceFee, 0) - ISNULL(ibd.PremiumGross, 0)) AS Difference
    FROM FilteredBilling ibd
    INNER JOIN DB_' + @CompanyCode + '_EP.dbo.DeferredPremium id ON id.ContractNo = ibd.ContractNo
    INNER JOIN DB_GLOBAL.dbo.ContractData c ON ibd.ContractNo = c.AgreementNo
    INNER JOIN DB_' + @CompanyCode + '_EP.dbo.Contract n ON c.AgreementNo = n.ContractNo
    INNER JOIN DB_' + @CompanyCode + '_EP.dbo.Customer l ON c.CustomerNo = l.CustomerNo
    LEFT JOIN DB_' + @CompanyCode + '_EP.dbo.InsuranceCoverageDetail icd ON icd.ContractNo = c.AgreementNo
    LEFT JOIN DB_' + @CompanyCode + '_EP.dbo.InsuranceCoverageHeader ich ON ich.CoverageNo = icd.CoverageNo
    LEFT JOIN DB_' + @CompanyCode + '_EP.dbo.InsuranceProvider m ON m.InsuranceID = ich.InsuranceID
    LEFT JOIN DB_GLOBAL.dbo.CreditInsurance ck ON c.ContractNo = ck.ContractNo
    WHERE CONVERT(VARCHAR(8), ibd.CreatedDate, 112) BETWEEN CONVERT(VARCHAR(6), EOMONTH(GETDATE(), -1), 112) + ''''01'''' AND CONVERT(VARCHAR(8), GETDATE() - 1, 112)
    ORDER BY ibd.ContractNo
    '')'

    EXEC(@SQL)
END
