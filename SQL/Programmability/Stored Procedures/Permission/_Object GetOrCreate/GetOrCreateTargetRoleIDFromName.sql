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

CREATE OR ALTER PROCEDURE [Permission].[GetOrCreateTargetRoleIDFromName]
      @db_name      SYSNAME
    , @role_name    SYSNAME
    , @TargetRoleID INT OUTPUT
AS
SET XACT_ABORT, NOCOUNT ON
BEGIN TRY
    BEGIN TRANSACTION

    DECLARE @db_id INT, @role_id INT

    EXEC [Validation].[DBIDFromName] @db_name, @db_id OUTPUT, 1
    EXEC [Validation].[RoleIDFromName] @db_name, @role_name, @role_id OUTPUT, 1

    EXEC [Permission].[GetOrCreateTargetRoleIDFromID] @db_id, @role_id, @TargetRoleID OUTPUT

    COMMIT TRANSACTION
END TRY
BEGIN CATCH
    IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION
    ; THROW
END CATCH
GO
