USE [Certificate_Administration]
GO

-- Source Databases with no associated objects / groups
CREATE OR ALTER VIEW [Permission].[OrphanedSourceDatabases]
AS
    SELECT
        [sd].*
    FROM
        [Permission].[SourceDatabase] AS [sd]
        LEFT JOIN [Permission].[SourceGroup] AS [sg]
            ON [sd].[SourceDatabaseID] =  [sg].[SourceDatabaseID]
        LEFT JOIN [Permission].[SourceObject] AS [so]
            ON [sd].[SourceDatabaseID] =  [so].[SourceDatabaseID]
    WHERE
        [sg].[SourceDatabaseID] IS NULL
        AND [so].[SourceDatabaseID] IS NULL
GO
