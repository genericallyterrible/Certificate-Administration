USE [Certificate_Administration]
GO

-- Target Databases with no associated Roles / Objects / Certificates
CREATE OR ALTER VIEW [Permission].[OrphanedTargetDatabases]
AS
    SELECT
        [td].*
    FROM
        [Permission].[TargetDatabase] AS [td]
        LEFT JOIN [Permission].[TargetRole] AS [tr]
            ON [td].[TargetDatabaseID] = [tr].[TargetDatabaseID]
        LEFT JOIN [Permission].[TargetObject] AS [to]
            ON [td].[TargetDatabaseID] = [to].[TargetDatabaseID]
        LEFT JOIN [Permission].[TargetGroupCertificate] AS [tgc]
            ON [td].[TargetDatabaseID] = [tgc].[TargetDatabaseID]
        LEFT JOIN [Permission].[TargetObjectCertificate] AS [toc]
            ON [td].[TargetDatabaseID] = [toc].[TargetDatabaseID]
    WHERE
        [tr].[TargetDatabaseID] IS NULL
        AND [to].[TargetDatabaseID] IS NULL
        AND [tgc].[TargetDatabaseID] IS NULL
        AND [toc].[TargetDatabaseID] IS NULL
GO
