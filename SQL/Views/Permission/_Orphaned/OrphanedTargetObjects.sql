USE [Certificate_Administration]
GO

-- Target Objects with no requests
CREATE OR ALTER VIEW [Permission].[OrphanedTargetObjects]
AS
    SELECT
        [to].*
    FROM
        [Permission].[TargetObject] AS [to]
        LEFT JOIN [Permission].[ObjectPermissionRequest] AS [opr]
            ON [to].[TargetObjectID] = [opr].[TargetObjectID]
        LEFT JOIN [Permission].[GroupPermissionRequest] AS [gpr]
            ON [to].[TargetObjectID] = [gpr].[TargetObjectID]
    WHERE
        [opr].[TargetObjectID] IS NULL
        AND [gpr].[TargetObjectID] IS NULL
GO
