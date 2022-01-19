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

CREATE OR ALTER PROCEDURE [Permission].[PermissionNameFromID]
      @PermissionID     INT
    , @permission_name  VARCHAR(50) OUTPUT
AS
SET XACT_ABORT, NOCOUNT ON
BEGIN TRY
    BEGIN TRANSACTION

    SELECT
        @permission_name = MIN([gp].[Permission])
    FROM
        [Permission].[GrantablePermission] AS [gp]
    WHERE
         [gp].[GrantablePermissionID] = @PermissionID

    IF @permission_name IS NULL
        RAISERROR('%d is not a valid grantable permisison id.', 16, 1, @PermissionID)

    COMMIT TRANSACTION
END TRY
BEGIN CATCH
    IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION
    ; THROW
END CATCH
GO
