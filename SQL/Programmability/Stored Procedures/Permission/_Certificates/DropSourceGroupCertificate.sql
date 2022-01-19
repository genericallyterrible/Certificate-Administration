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

CREATE OR ALTER PROCEDURE [Permission].[DropSourceGroupCertificateByID]
      @SourceGroupCertificateID INT
    , @debug                    BIT = 1
AS
SET XACT_ABORT, NOCOUNT ON
BEGIN TRY
    BEGIN TRANSACTION

    DECLARE
          @src_db_id        INT
        , @src_cert_id      INT
        , @src_db_name      SYSNAME
        , @src_cert_name    SYSNAME
        , @toc_count        INT

    SELECT @toc_count = COUNT(*)
    FROM [TargetGroupCertificate]
    WHERE [SourceGroupCertificateID] = @SourceGroupCertificateID

    IF @toc_count > 0
        RAISERROR('Cannot drop Source Group Certificate: "%s". A Target Group Certificate depends on it.', 16, 1, @SourceGroupCertificateID)

    SELECT
          @src_db_id    = [sd].[database_id]
        , @src_cert_id  = [sgc].[certificate_id]
    FROM
        [Permission].[SourceGroupCertificate] AS [sgc]
        JOIN [Permission].[SourceGroup] AS [sg]
            ON [sgc].[SourceGroupID] = [sg].[SourceGroupID]
        JOIN [Permission].[SourceDatabase] AS [sd]
            ON [sg].[SourceDatabaseID] = [sd].[SourceDatabaseID]
    WHERE
        [sgc].[SourceGroupCertificateID] = @SourceGroupCertificateID

    -- No certificate exists
    IF @src_db_id IS NULL
        RETURN

    EXEC [Validation].[DBNameFromID] @src_db_id, @src_db_name OUTPUT, 1
    EXEC [Validation].[CertificateNameFromID]
          @src_db_id
        , @src_cert_id
        , @src_cert_name OUTPUT
        , 1
        , @debug

    EXEC [Definition].[DropCertAndDependenciesByName]
          @src_db_name
        , @src_cert_name
        , 0
        , 1
        , @debug

    DELETE [sgc]
    FROM [Permission].[SourceGroupCertificate] AS [sgc]
    WHERE
        [sgc].[SourceGroupCertificateID] = @SourceGroupCertificateID

    COMMIT TRANSACTION
END TRY
BEGIN CATCH
    IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION
    ; THROW
END CATCH
GO
