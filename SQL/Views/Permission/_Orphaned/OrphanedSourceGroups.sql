USE [Certificate_Administration]
GO

-- Source Groups with no requests
CREATE OR ALTER VIEW [Permission].[OrphanedSourceGroups]
AS
    SELECT
        [sg].*
    FROM
        [Permission].[SourceGroup] AS [sg]
        LEFT JOIN [Permission].[GroupPermissionRequest] AS [gpr]
            ON [sg].[SourceGroupID] = [gpr].[SourceGroupID]
        LEFT JOIN [Permission].[GroupRoleRequest] AS [grr]
            ON [sg].SourceGroupID = [grr].[SourceGroupID]
    WHERE
        [gpr].[SourceGroupID] IS NULL
        AND [grr].[SourceGroupID] IS NULL
GO
