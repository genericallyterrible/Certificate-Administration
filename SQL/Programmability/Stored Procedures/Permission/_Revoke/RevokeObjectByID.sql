USE [Certificate_Administration]
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- ======================================================================
-- Author:          John Merkel
-- Creation date:   October 20, 2021
-- Description:     Revokes all permissions/roles for the SourceObject.
-- Requires:        SA
-- ======================================================================

CREATE OR ALTER PROCEDURE [Permission].[RevokeObjectByID]
      @SourceObjectID   INT
    , @DropRequests     BIT
    , @debug            BIT = 1
AS
SET XACT_ABORT, NOCOUNT ON
BEGIN TRY
    BEGIN TRANSACTION

    DECLARE
          @db_id                        INT
        , @object_id                    INT
        , @SourceObjectCertificateID    INT
        , @cert_id                      INT

    SELECT
          @db_id                        = MIN([sd].[database_id])
        , @object_id                    = MIN([so].[object_id])
        , @SourceObjectCertificateID    = MIN([soc].SourceObjectCertificateID)
    FROM [Permission].[SourceObject] AS [so]
        JOIN [Permission].[SourceDatabase] AS [sd]
            ON [so].[SourceDatabaseID] = [sd].[SourceDatabaseID]
        LEFT JOIN [Permission].[SourceObjectCertificate] AS [soc]
                ON [so].[SourceObjectID] = [soc].[SourceObjectID]
    WHERE [so].[SourceObjectID] = @SourceObjectID

    DECLARE [group_cert_cur] CURSOR STATIC LOCAL FOR
        SELECT DISTINCT [sgc].[certificate_id]
        FROM [SourceGroupObject] AS [sgo]
            JOIN [Permission].[SourceGroupCertificate] AS [sgc]
                ON [sgo].[SourceGroupID] = [sgc].[SourceGroupID]
        WHERE [sgo].[SourceObjectID] = @SourceObjectID
    OPEN [group_cert_cur]
    WHILE 1 = 1
    BEGIN
        FETCH NEXT FROM [group_cert_cur] INTO @cert_id
        IF @@FETCH_STATUS <> 0 BREAK
        
        -- Remove all group certificate signatures from object
        EXEC [Definition].[DropSigFromObjByID] @db_id, @object_id, @cert_id, @debug
    END
    CLOSE [group_cert_cur]
    DEALLOCATE [group_cert_cur]

    IF @SourceObjectCertificateID IS NOT NULL
    BEGIN
        -- Drop all object specific certificates
        EXEC [Permission].[DropAllTargetObjectCertsByID] @SourceObjectCertificateID, @debug
        EXEC [Permission].[DropSourceObjectCertificateByID] @SourceObjectCertificateID, @debug
    END

    -- Delete object requests or set granted = 0
    IF @DropRequests = 1
    BEGIN
        DELETE [opr]
        FROM [Permission].[ObjectPermissionRequest] AS [opr]
        WHERE [opr].[SourceObjectID] = @SourceObjectID

        DELETE [orr]
        FROM [Permission].[ObjectRoleRequest] AS [orr]
        WHERE [orr].[SourceObjectID] = @SourceObjectID
    END
    ELSE
    BEGIN
        UPDATE [Permission].[ObjectPermissionRequest]
        SET [Granted] = 0
        WHERE [SourceObjectID] = @SourceObjectID

        UPDATE [Permission].[ObjectRoleRequest]
        SET [Granted] = 0
        WHERE [SourceObjectID] = @SourceObjectID
    END

    COMMIT TRANSACTION
END TRY
BEGIN CATCH
    IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION
    ; THROW
END CATCH
GO
