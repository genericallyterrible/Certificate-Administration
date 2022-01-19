USE [Certificate_Administration]
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- ======================================================================
-- Author:          John Merkel
-- Creation date:   October 22, 2021
-- Description:     Creates a certificate from a SourceGroupCertificate,
--                  creates a user from the new certificate,
--                  and appends the certificate's ID to the 
--                  TargetGroupCertificate table.
-- Requires:        SA
-- ======================================================================

CREATE OR ALTER PROCEDURE [Permission].[CreateTargetGroupCertificateAndUser]
      @SourceGroupCertificateID INT
    , @TargetDatabaseID         INT
    , @debug                    BIT = 1
AS
SET XACT_ABORT, NOCOUNT ON
BEGIN TRY
    BEGIN TRANSACTION

    DECLARE
          @src_db_id        INT
        , @src_db_name      SYSNAME
        , @src_cert_id      INT
        , @src_cert_name    SYSNAME
        , @tar_db_id        INT
        , @tar_db_name      SYSNAME
        , @tar_cert_id      INT

    -- Get ID of existing certificate and its database
    SELECT
          @src_db_id = MIN([sd].[database_id])
        , @src_cert_id = MIN([sgc].[certificate_id])
    FROM
        [Permission].[SourceGroupCertificate] AS [sgc]
        JOIN [Permission].[SourceGroup] AS [sg]
            ON [sgc].[SourceGroupID] = [sg].[SourceGroupID]
        JOIN [Permission].[SourceDatabase] AS [sd]
            ON [sg].[SourceDatabaseID] = [sd].[SourceDatabaseID]
    WHERE [sgc].[SourceGroupCertificateID] = @SourceGroupCertificateID

    -- RAISERROR if a certificate is not found
    IF @src_cert_id IS NULL
        RAISERROR('No SourceGroupCertificate exists with ID: "%d"', 16, 1, @SourceGroupCertificateID)

    -- Get target database_id
    SELECT @tar_db_id = [database_id]
    FROM [Permission].[TargetDatabase]
    WHERE [TargetDatabaseID] = @TargetDatabaseID

    -- RAISERROR if database is not found
    IF @tar_db_id iS NULL
        RAISERROR('No TargetDatabase exists with ID: "%d"', 16, 1, @TargetDatabaseID)

    -- Retrieve the information we need for creating the target certificate
    EXEC [Validation].[DBNameFromID] @src_db_id, @src_db_name OUTPUT, 1
    EXEC [Validation].[DBNameFromID] @tar_db_id, @tar_db_name OUTPUT, 1
    EXEC [Validation].[CertificateNameFromID]
          @src_db_id
        , @src_cert_id
        , @src_cert_name OUTPUT
        , 1
        , @debug

    -- Export the certificate
    EXEC [Definition].[ExportCertificateByName]
          @src_db_name
        , @src_cert_name
        , @tar_db_name
        , @src_cert_name
        , @tar_cert_id OUTPUT
        , @debug

    -- Create the user
    EXEC [Definition].[CreateUserFromCertByName] @tar_db_name, @src_cert_name, @debug

    -- Log the certificate
    INSERT INTO [TargetGroupCertificate] (
          [SourceGroupCertificateID]
        , [TargetDatabaseID]
        , [certificate_id]
    )
    VALUES (
          @SourceGroupCertificateID
        , @TargetDatabaseID
        , @tar_cert_id
    )

    COMMIT TRANSACTION
END TRY
BEGIN CATCH
    IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION
    ; THROW
END CATCH
GO
