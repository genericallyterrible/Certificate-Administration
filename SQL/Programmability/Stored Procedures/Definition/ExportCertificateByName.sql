USE [Certificate_Administration]
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- ======================================================================
-- Author:          John Merkel
-- Creation date:   October 4, 2021
-- Description:     Exports a certificate from one database to another.
-- Requires:        SA
-- ======================================================================

CREATE OR ALTER PROCEDURE [Definition].[ExportCertificateByName]
      @src_db_name      SYSNAME
    , @src_cert_name    SYSNAME
    , @tar_db_name      SYSNAME
    , @tar_cert_name    SYSNAME
    , @tar_cert_id      INT OUTPUT
    , @debug            BIT = 1
AS
SET XACT_ABORT, NOCOUNT ON
BEGIN TRY
    BEGIN TRANSACTION

    DECLARE
          @executesql   NVARCHAR(350)
        , @sql_start    NVARCHAR(200)
        , @sql_end      NVARCHAR(200)
        , @sql          NVARCHAR(MAX)
        , @public_key   VARBINARY(MAX)

    -- Validate target db and initialize dynamic variables
    EXEC [InitDynamicSQL]
          @tar_db_name  OUTPUT
        , @executesql   OUTPUT
        , @sql_start    OUTPUT
        , @sql_end      OUTPUT

    -- Get source's public key
    EXEC [Validation].[CertPublicKeyFromName] @src_db_name, @src_cert_name, @public_key OUTPUT, 1, @debug

    -- Create target certificate from source's public key
    SELECT
        @sql =
            @sql_start
            + 'CREATE CERTIFICATE ' + QUOTENAME(@tar_cert_name, '"') + '
            FROM BINARY = ' + CONVERT(VARCHAR(MAX), @public_key, 1)
            + @sql_end
    IF @debug = 1
    BEGIN
        PRINT '-- Creating certificate: "' + @tar_cert_name + '"'
        PRINT '-- from public key of: "' + @src_cert_name + '"'
        PRINT @sql
    END
    EXEC @executesql @sql

    EXEC [Validation].[CertificateIDFromName] @tar_db_name, @tar_cert_name, @tar_cert_id OUTPUT, 1, @debug

    COMMIT TRANSACTION
END TRY
BEGIN CATCH
    IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION
    -- In cases there is an error while we are impersonating dbo, we need
    -- to revert back, which must be done in the user database.
    IF EXISTS (
        SELECT * FROM [sys].[login_token] WHERE [usage] = 'DENY ONLY'
    )
    BEGIN
        IF @debug = 1 PRINT '-- Error while impersonating dbo, reverting'
        EXEC @executesql N'REVERT'
    END
    ; THROW
END CATCH
GO
