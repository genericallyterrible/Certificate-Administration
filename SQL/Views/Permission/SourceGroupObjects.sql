USE [Certificate_Administration]
GO

CREATE OR ALTER VIEW [Permission].[SourceGroupObjects]
AS
    SELECT
          [sg].[SourceGroupID] AS [SourceGroupID]
        , [sg].[Name] AS [SourceGroupName]
        , [sd].[database_id] AS [DB_ID]
        , DB_NAME([sd].[database_id]) AS [DB_NAME]
        , [so].[object_id] AS [OBJECT_ID]
        , OBJECT_NAME([so].[object_id], [sd].[database_id]) AS [OBJECT_NAME]
    FROM
        [Permission].[SourceGroupObject] AS [sgo]
        JOIN [Permission].[SourceGroup] AS [sg]
            ON [sgo].[SourceGroupID] = [sg].[SourceGroupID]
        JOIN [Permission].[SourceObject] AS [so]
            ON [sgo].[SourceObjectID] = [so].[SourceObjectID]
        JOIN [Permission].[SourceDatabase] AS [sd]
            ON [sg].[SourceDatabaseID] = [sd].[SourceDatabaseID]
    -- ORDER BY [SourceGroupID], [DB_NAME], [OBJECT_NAME]
GO
