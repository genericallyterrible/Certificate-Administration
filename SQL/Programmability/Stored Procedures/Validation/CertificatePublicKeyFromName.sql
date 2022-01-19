USE [Certificate_Administration]
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- ======================================================================
-- Author:          John Merkel
-- Creation date:   October 19, 2021
-- Description:     Retrieve the public key for a certificate.
-- Requires:        SA
-- ======================================================================

CREATE OR ALTER PROCEDURE [Validation].[CertPublicKeyFromName]
      @db_name      SYSNAME
    , @cert_name    SYSNAME
    , @public_key   VARBINARY(MAX) OUTPUT
    , @raiserror    BIT = 1
    , @debug        BIT = 1
AS
SET XACT_ABORT, NOCOUNT ON
BEGIN TRY
    BEGIN TRANSACTION

    DECLARE
          @executesql   NVARCHAR(350)
        , @sql_start    NVARCHAR(200)
        , @sql_end      NVARCHAR(200)
        , @sql          NVARCHAR(MAX)
        , @params       NVARCHAR(MAX)

    -- Validate db and initialize dynamic variables
    EXEC [InitDynamicSQL]
          @db_name      OUTPUT
        , @executesql   OUTPUT
        , @sql_start    OUTPUT
        , @sql_end      OUTPUT


    -- Validate source certificate
    EXEC [Validation].[ValidateCertName] @db_name, @cert_name OUTPUT, 1, @debug

    -- Get source certificate's public key
    SELECT
        @sql =
            @sql_start
            + 'SELECT @public_key = CERTENCODED(CERT_ID(QUOTENAME(@cert_name)))'
            + @sql_end
        , @params =
            '@public_key VARBINARY(MAX) OUTPUT
            , @cert_name SYSNAME'
    IF @debug = 1 PRINT '-- Retrieving public key for certificate: "' + @cert_name + '"'
    IF @debug = 1 PRINT @sql
    EXEC @executesql @sql, @params
            , @public_key OUTPUT
            , @cert_name

    IF @raiserror = 1 AND @public_key IS NULL
        RAISERROR('Could not retrieve public_key for certificate %s.', 16, 1, @cert_name)

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
