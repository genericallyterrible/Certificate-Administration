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

CREATE OR ALTER PROCEDURE [Permission].[GetOrCreateTargetRoleIDFromID]
      @db_id        INT
    , @role_id      INT
    , @TargetRoleID INT OUTPUT
AS
SET XACT_ABORT, NOCOUNT ON
BEGIN TRY
    BEGIN TRANSACTION

    DECLARE @TargetDatabaseID INT

    EXEC [Permission].[GetOrCreateTargetDBIDFromID] @db_id, @TargetDatabaseID OUTPUT

    EXEC [Permission].[TargetRoleIdFromID] @db_id, @role_id, @TargetRoleID OUTPUT, 0
    IF @TargetRoleID IS NULL
    BEGIN

        EXEC [Validation].[ValidateRoleID] @db_id, @role_id, 1

        INSERT INTO [Permission].[TargetRole] (
              [TargetDatabaseID]
            , [role_principal_id]
        ) VALUES (
              @TargetDatabaseID
            , @role_id
        )

        EXEC [Permission].[TargetRoleIdFromID] @db_id, @role_id, @TargetRoleID OUTPUT, 1
    END

    COMMIT TRANSACTION
END TRY
BEGIN CATCH
    IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION
    ; THROW
END CATCH
GO
