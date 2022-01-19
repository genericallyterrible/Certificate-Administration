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

CREATE OR ALTER PROCEDURE [Permission].[AddObjectRoleRequestFromName]
      @src_db_name      SYSNAME
    , @src_schema_name  SYSNAME
    , @src_object_name  SYSNAME
    , @tar_db_name      SYSNAME
    , @role_name        SYSNAME
AS
SET XACT_ABORT, NOCOUNT ON
BEGIN TRY
    BEGIN TRANSACTION

    DECLARE
          @SourceObjectID   INT
        , @TargetRoleID     INT
        , @PermissionID     INT

    EXEC [Permission].[GetOrCreateSourceObjectIDFromName] @src_db_name, @src_schema_name, @src_object_name, @SourceObjectID OUTPUT

    EXEC [Permission].[GetOrCreateTargetRoleIDFromName] @tar_db_name, @role_name, @TargetRoleID OUTPUT

    -- Insert if not exists (avoid erroring on attempted duplicate primary key)
    IF NOT EXISTS (
        SELECT *
        FROM [Permission].[ObjectRoleRequest] AS [orr]
        WHERE [orr].[SourceObjectID] = @SourceObjectID
            AND [orr].[TargetRoleID] = @TargetRoleID
    )
    BEGIN
        INSERT INTO [Permission].[ObjectRoleRequest] (
              [SourceObjectID]
            , [TargetRoleID]
        ) VALUES (
              @SourceObjectID
            , @TargetRoleID
        )
    END

    COMMIT TRANSACTION
END TRY
BEGIN CATCH
    IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION
    ; THROW
END CATCH
GO
