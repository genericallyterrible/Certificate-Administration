USE [Certificate_Administration]
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- ======================================================================
-- Author:          John Merkel
-- Creation date:   October 18, 2021
-- Description:     
-- Return:          
-- Requires:        SA
-- ======================================================================

CREATE OR ALTER PROCEDURE [Permission].[PermissionIDFromName]
      @permission_name  VARCHAR(50)
    , @PermissionID     INT OUTPUT
AS
SET XACT_ABORT, NOCOUNT ON
BEGIN TRY
    BEGIN TRANSACTION

    SELECT
        @PermissionID = MIN([gp].[GrantablePermissionID])
    FROM
        [Permission].[GrantablePermission] AS [gp]
    WHERE
        [gp].[Permission] = @permission_name

    IF @PermissionID IS NULL
        RAISERROR('%s is not a grantable permisison.', 16, 1, @permission_name)

    COMMIT TRANSACTION
END TRY
BEGIN CATCH
    IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION
    ; THROW
END CATCH
GO
