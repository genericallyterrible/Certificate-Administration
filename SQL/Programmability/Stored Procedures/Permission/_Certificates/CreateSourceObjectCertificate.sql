USE [Certificate_Administration]
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- ======================================================================
-- Author:          John Merkel
-- Creation date:   October 22, 2021
-- Description:     Creates a certificate for a SourceObject, signs
--                  the SourceObject, drops the certificate's
--                  private key, and appends the certificate's ID
--                  to the SourceObjectCertificate table before returning
--                  the newly created SourceObjectCertificateID.
-- Requires:        SA
-- ======================================================================

CREATE OR ALTER PROCEDURE [Permission].[CreateSourceObjectCertificate]
      @SourceObjectID               INT
    , @SourceObjectCertificateID    INT OUTPUT
    , @debug                        BIT = 1
AS
SET XACT_ABORT, NOCOUNT ON
BEGIN TRY
    BEGIN TRANSACTION

    -- Look for an existing certificate
    SELECT @SourceObjectCertificateID = MIN([SourceObjectCertificateID])
    FROM [Permission].[SourceObjectCertificate]
    WHERE [SourceObjectID] = @SourceObjectID

    -- RAISERROR if a certificate is found to already exist
    IF @SourceObjectCertificateID IS NOT NULL
        RAISERROR('A certificate already exists for SourceObject with ID: "%d"', 16, 1, @SourceObjectID)

    DECLARE
          @db_id        INT
        , @object_id    INT
        , @cert_id      INT
        , @db_name      SYSNAME
        , @schema_name  SYSNAME
        , @object_name  SYSNAME
        , @cert_name    SYSNAME
        , @subject      NVARCHAR(4000)
        , @pwd          CHAR(39)

    -- Retrieve the information we need for creating the source certificate
    SELECT
          @db_id = MIN([sd].[database_id])
        , @object_id = MIN([so].[object_id])
    FROM
        [Permission].[SourceObject] AS [so]
        JOIN [Permission].[SourceDatabase] AS [sd]
            ON [so].[SourceDatabaseID] = [sd].[SourceDatabaseID]
    WHERE
        [so].[SourceObjectID] = @SourceObjectID

    -- Ensure the object actually exists
    IF @db_id IS NULL
        RAISERROR('No SourceObject exists with ID: "%d"', 16, 1, @SourceObjectID)

    -- Retrieve all the names
    EXEC [Validation].[AllNamesFromIDs]
              @db_id
            , @object_id
            , @db_name      OUTPUT
            , @schema_name  OUTPUT
            , @object_name  OUTPUT
            , 1
            , @debug

    -- Use the object's name for the certificate's name and subject
    SELECT
          @cert_name = 'SIGN ' + QUOTENAME(@db_name) + '.' + QUOTENAME(@schema_name) + '.' + QUOTENAME(@object_name)
        , @subject = CONCAT('Grants cross database permissions and roles for SourceObject: '
                , @db_name, '.', @schema_name, '.', @object_name
                ,' (ID: ', @SourceObjectID, ')')

    -- Create certificate
    EXEC [Definition].[CreateCertByPwd]
          @db_name
        , @cert_name
        , @pwd      OUTPUT
        , @subject
        , @cert_id  OUTPUT
        , @debug

    -- Sign source object
    EXEC [Definition].[SignObjByCertWithPwd]
          @db_name
        , @schema_name
        , @object_name
        , @cert_name
        , @pwd
        , @debug

    -- Remove private key to prevent further signatures
    EXEC [Definition].[RemoveCertPrivateKeyByName]
          @db_name
        , @cert_name
        , @debug

    -- Log the certificate
    INSERT INTO [Permission].[SourceObjectCertificate] (
          [SourceObjectID]
        , [certificate_id]
    )
    VALUES (
          @SourceObjectID
        , @cert_id
    )

    -- Return the newly inserted SourceObjectCertificate's ID
    SELECT @SourceObjectCertificateID = [sgc].[SourceObjectCertificateID]
    FROM [Permission].[SourceObjectCertificate] AS [sgc]
    WHERE [sgc].[SourceObjectID] = @SourceObjectID

    COMMIT TRANSACTION
END TRY
BEGIN CATCH
    IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION

    PRINT CONCAT('-- Error creating source object certificate for source object with ID: ', @SourceObjectID)

    ; THROW
END CATCH
GO
