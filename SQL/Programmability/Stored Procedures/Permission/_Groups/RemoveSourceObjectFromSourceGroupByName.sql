USE [Certificate_Administration]
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- ======================================================================
-- Author:          John Merkel
-- Creation date:   October 25, 2021
-- Description:     
-- Return:          
-- Requires:        SA
-- ======================================================================

CREATE OR ALTER PROCEDURE [Permission].[RemoveSourceObjectFromSourceGroupByName]
      @db_name          SYSNAME
    , @schema_name      SYSNAME
    , @object_name      SYSNAME
    , @group_name       SYSNAME
    , @debug            BIT = 1
AS
SET XACT_ABORT, NOCOUNT ON
BEGIN TRY
    BEGIN TRANSACTION

    DECLARE
          @db_id            INT
        , @object_id        INT
        , @cert_id          INT
        , @SourceObjectID   INT

    EXEC [Permission].[SourceObjectIDFromName]
          @db_name
        , @schema_name
        , @object_name
        , @SourceObjectID OUTPUT
        , 1

    SELECT
          @db_id        = MIN([sd].[database_id])
        , @object_id    = MIN([so].[object_id])
    FROM [Permission].[SourceObject] AS [so]
        JOIN [Permission].[SourceDatabase] AS [sd]
            ON [so].[SourceDatabaseID] = [sd].[SourceDatabaseID]
    WHERE [so].[SourceObjectID] = @SourceObjectID

    DECLARE [group_cert_cur] CURSOR STATIC LOCAL FOR
        SELECT DISTINCT [sgc].[certificate_id]
        FROM [Permission].[SourceGroupObject] AS [sgo]
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

    -- Remove source object from relation table
    DELETE [sgo]
    FROM [Permission].[SourceGroupObject] AS [sgo]
        WHERE [sgo].[SourceObjectID] = @SourceObjectID

    COMMIT TRANSACTION
END TRY
BEGIN CATCH
    IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION
    ; THROW
END CATCH
GO
