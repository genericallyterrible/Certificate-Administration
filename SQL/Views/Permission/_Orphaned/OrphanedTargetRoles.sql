USE [Certificate_Administration]
GO

-- Target Roles with no requests
CREATE OR ALTER VIEW [Permission].[OrphanedTargetRoles]
AS
    SELECT
        [tr].*
    FROM
        [Permission].[TargetRole] AS [tr]
        LEFT JOIN [Permission].[ObjectRoleRequest] AS [orr]
            ON [tr].[TargetRoleID] = [orr].[TargetRoleID]
        LEFT JOIN [Permission].[GroupRoleRequest] AS [grr]
            ON [tr].[TargetRoleID] = [grr].[TargetRoleID]
    WHERE
        [orr].[TargetRoleID] IS NULL
        AND [grr].[TargetRoleID] IS NULL
GO
