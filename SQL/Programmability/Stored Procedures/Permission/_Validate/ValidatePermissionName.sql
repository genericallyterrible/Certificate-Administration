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

CREATE OR ALTER PROCEDURE [Permission].[ValidatePermissionName]
    @permission_name SYSNAME OUTPUT
AS
SET XACT_ABORT, NOCOUNT ON
BEGIN TRY
    BEGIN TRANSACTION

    SELECT
        @permission_name = MIN([gp].[Permission])
    FROM
        [Permission].[GrantablePermission] AS [gp]
    WHERE
        [gp].[GrantablePermissionID] = @permission_name

    IF @permission_name IS NULL
        RAISERROR('%s is not a grantable permisison.', 16, 1, @permission_name)

    COMMIT TRANSACTION
END TRY
BEGIN CATCH
    IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION
    ; THROW
END CATCH
GO
