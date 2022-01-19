USE [Certificate_Administration]
GO

-- Source Objects with no direct requests and not grouped
CREATE OR ALTER VIEW [Permission].[OrphanedSourceObjects]
AS
    SELECT
        [so].*
    FROM
        [Permission].[SourceObject] AS [so]
        LEFT JOIN [Permission].[ObjectPermissionRequest] AS [opr]
            ON [so].[SourceObjectID] = [opr].[SourceObjectID]
        LEFT JOIN [Permission].[ObjectRoleRequest] AS [orr]
            ON [so].[SourceObjectID] = [orr].[SourceObjectID]
        LEFT JOIN [Permission].[SourceGroupObject] AS [sgo]
            ON [so].[SourceObjectID] = [sgo].[SourceObjectID]
    WHERE
        [opr].[SourceObjectID] IS NULL
        AND [orr].[SourceObjectID] IS NULL
        AND [sgo].[SourceGroupID] IS NULL
GO
