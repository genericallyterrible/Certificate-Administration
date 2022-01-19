USE [Certificate_Administration]
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- ======================================================================
-- Author:          John Merkel
-- Creation date:   October 19, 2021
-- Description:     
-- Return:          
-- Requires:        SA
-- ======================================================================

CREATE OR ALTER PROCEDURE [Permission].[ValidatePermissionID]
    @PermissionID INT OUTPUT
AS
SET XACT_ABORT, NOCOUNT ON
BEGIN TRY
    BEGIN TRANSACTION

    SELECT
        @PermissionID = MIN([gp].[GrantablePermissionID])
    FROM
        [Permission].[GrantablePermission] AS [gp]
    WHERE
        [gp].[GrantablePermissionID] = @PermissionID

    IF @PermissionID IS NULL
        RAISERROR('%d is not a grantable permisison id.', 16, 1, @PermissionID)

    COMMIT TRANSACTION
END TRY
BEGIN CATCH
    IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION
    ; THROW
END CATCH
GO
