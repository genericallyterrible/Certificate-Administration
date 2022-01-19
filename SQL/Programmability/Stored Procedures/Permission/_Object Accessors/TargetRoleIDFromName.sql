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

CREATE OR ALTER PROCEDURE [Permission].[TargetRoleIDFromName]
      @db_name          SYSNAME
    , @role_name        SYSNAME
    , @TargetRoleID     INT OUTPUT
    , @raiserror        BIT = 1
AS
SET XACT_ABORT, NOCOUNT ON
BEGIN TRY
    BEGIN TRANSACTION

    DECLARE @DatabaseID INT, @role_id INT

    EXEC [Permission].[TargetDBIDFromName] @db_name, @DatabaseID OUTPUT, @raiserror

    EXEC [Validation].[RoleIDFromName] @db_name, @role_name, @role_id OUTPUT, @raiserror, 0

    SELECT
        @TargetRoleID = MIN([TargetRoleID])
    FROM
        [Permission].[TargetRole] AS [tr]
    WHERE
        [tr].[TargetDatabaseID] = @DatabaseID
        AND [tr].[role_principal_id] = @role_id

    IF @raiserror = 1 AND @TargetRoleID IS NULL
        RAISERROR('Role "%s" has not been added as a target role for database "%s".', 16, 1, @role_name, @db_name)

    COMMIT TRANSACTION
END TRY
BEGIN CATCH
    IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION
    ; THROW
END CATCH
GO
