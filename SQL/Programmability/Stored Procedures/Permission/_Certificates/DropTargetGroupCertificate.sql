USE [Certificate_Administration]
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- ======================================================================
-- Author:          John Merkel
-- Creation date:   October 20, 2021
-- Description:     
-- Requires:        SA
-- ======================================================================

CREATE OR ALTER PROCEDURE [Permission].[DropTargetGroupCertificateByID]
      @SourceGroupCertificateID INT
    , @TargetDatabaseID         INT
    , @debug                    BIT = 1
AS
SET XACT_ABORT, NOCOUNT ON
BEGIN TRY
    BEGIN TRANSACTION

    DECLARE
          @tar_db_id        INT
        , @tar_cert_id      INT
        , @tar_db_name      SYSNAME
        , @tar_cert_name    SYSNAME

    SELECT
          @tar_db_id    = [td].[database_id]
        , @tar_cert_id  = [tgc].[certificate_id]
    FROM
        [Permission].[TargetGroupCertificate] AS [tgc]
        JOIN [Permission].[TargetDatabase] AS [td]
            ON [tgc].[TargetDatabaseID] = [td].[TargetDatabaseID]
    WHERE
        [tgc].[SourceGroupCertificateID] = @SourceGroupCertificateID
        AND [tgc].[TargetDatabaseID] = @TargetDatabaseID

    EXEC [Validation].[DBNameFromID] @tar_db_id, @tar_db_name OUTPUT, 1
    EXEC [Validation].[CertificateNameFromID]
          @tar_db_id
        , @tar_cert_id
        , @tar_cert_name OUTPUT
        , 1
        , @debug

    EXEC [Definition].[DropCertAndDependenciesByName]
          @tar_db_name
        , @tar_cert_name
        , 1
        , 1
        , @debug

    DELETE [tgc]
    FROM [Permission].[TargetGroupCertificate] AS [tgc]
    WHERE
        [tgc].[SourceGroupCertificateID] = @SourceGroupCertificateID
        AND [tgc].[TargetDatabaseID] = @TargetDatabaseID

    COMMIT TRANSACTION
END TRY
BEGIN CATCH
    IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION
    ; THROW
END CATCH
GO
