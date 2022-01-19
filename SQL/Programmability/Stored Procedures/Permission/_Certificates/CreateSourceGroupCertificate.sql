USE [Certificate_Administration]
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- ======================================================================
-- Author:          John Merkel
-- Creation date:   October 22, 2021
-- Description:     Creates a certificate for a SourceGroup, signs
--                  all SourceGroup members, drops the certificate's
--                  private key, and appends the certificate's ID
--                  to the SourceGroupCertificate table before returning
--                  the newly created SourceGroupCertificateID.
-- Requires:        SA
-- ======================================================================

CREATE OR ALTER PROCEDURE [Permission].[CreateSourceGroupCertificate]
      @SourceGroupID            INT
    , @SourceGroupCertificateID INT OUTPUT
    , @debug                    BIT = 1
AS
SET XACT_ABORT, NOCOUNT ON
BEGIN TRY
    BEGIN TRANSACTION

    IF @debug = 1 PRINT CONCAT('-- Creating certificate for source group with ID:', @SourceGroupID)

    -- Look for an existing certificate
    SELECT @SourceGroupCertificateID = MIN([SourceGroupCertificateID])
    FROM [Permission].[SourceGroupCertificate]
    WHERE [SourceGroupID] = @SourceGroupID

    -- RAISERROR if a certificate is found to already exist
    IF @SourceGroupCertificateID IS NOT NULL
        RAISERROR('A certificate already exists for SourceGroup with ID: "%d"', 16, 1, @SourceGroupID)

    DECLARE
          @db_id        INT
        , @object_id    INT
        , @cert_id      INT
        , @db_name      SYSNAME
        , @schema_name  SYSNAME
        , @object_name  SYSNAME
        , @group_name   SYSNAME
        , @cert_name    SYSNAME
        , @subject      NVARCHAR(4000)
        , @pwd          CHAR(39)

    -- Retrieve the information we need for creating the source certificate
    SELECT
          @db_id      = MIN([sd].[database_id])
        , @group_name = MIN([sg].[Name])
    FROM
        [Permission].[SourceGroup] AS [sg]
        JOIN [Permission].[SourceDatabase] AS [sd]
            ON [sg].[SourceDatabaseID] = [sd].[SourceDatabaseID]
    WHERE
        [sg].[SourceGroupID] = @SourceGroupID

    -- Ensure the group actually exists
    IF @group_name IS NULL
        RAISERROR('No SourceGroup exists with ID: "%d"', 16, 1, @SourceGroupID)

    -- Retrieve the database name
    EXEC [Validation].[DBNameFromID]
          @db_id
        , @db_name OUTPUT
        , 1

    -- Use the group's name for the certificate's name and subject
    SELECT
        @cert_name = 'SIGN ' + @group_name
        , @subject = CONCAT('Grants cross database permissions and roles for SourceGroup: ', @group_name, ' (ID: ', @SourceGroupID, ')')

    EXEC [Definition].[CreateCertByPwd]
          @db_name
        , @cert_name
        , @pwd      OUTPUT
        , @subject
        , @cert_id  OUTPUT
        , @debug


    -- Sign all grouped objects
    DECLARE [object_cur] CURSOR STATIC LOCAL FOR
        SELECT DISTINCT
            [object_id]
        FROM
            [Permission].[SourceGroup] AS [sg]
            JOIN [Permission].[SourceGroupObject] AS [sgo]
                ON [sg].[SourceGroupID] = [sgo].[SourceGroupID]
            JOIN [Permission].[SourceObject] AS [so]
                ON [sgo].[SourceObjectID] = [so].SourceObjectID
    OPEN [object_cur]
    WHILE 1 = 1
    BEGIN
        FETCH NEXT FROM [object_cur] INTO @object_id
        IF @@FETCH_STATUS <> 0 BREAK

        EXEC [Validation].[AllNamesFromIDs]
              @db_id
            , @object_id
            , @db_name      OUTPUT
            , @schema_name  OUTPUT
            , @object_name  OUTPUT
            , 1
            , @debug

        EXEC [Definition].[SignObjByCertWithPwd]
              @db_name
            , @schema_name
            , @object_name
            , @cert_name
            , @pwd
            , @debug
    END
    CLOSE [object_cur]
    DEALLOCATE [object_cur]


    -- Remove private key to prevent further signatures
    EXEC [Definition].[RemoveCertPrivateKeyByName]
          @db_name
        , @cert_name
        , @debug

    -- Log the certificate
    INSERT INTO [Permission].[SourceGroupCertificate] (
          [SourceGroupID]
        , [certificate_id]
    )
    VALUES (
          @SourceGroupID
        , @cert_id
    )

    -- Return the newly inserted SourceGroupCertificate's ID
    SELECT @SourceGroupCertificateID = [sgc].[SourceGroupCertificateID]
    FROM [Permission].[SourceGroupCertificate] AS [sgc]
    WHERE [sgc].[SourceGroupID] = @SourceGroupID

    COMMIT TRANSACTION
END TRY
BEGIN CATCH
    IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION

    PRINT CONCAT('-- Error creating source group certificate for source group with ID: ', @SourceGroupID)

    ; THROW
END CATCH
GO
