USE [Certificate_Administration]
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- ======================================================================
-- Author:          John Merkel
-- Creation date:   October 4, 2021
-- Description:     Removes the private key portion of a certificate.
--                  Double checks to ensure the key is dropped.
--                  Raises an error and performs a rollback if
--                  the key is not dropped.
-- Requires:        SA
-- ======================================================================

CREATE OR ALTER PROCEDURE [Definition].[RemoveCertPrivateKeyByName]
      @db_name      SYSNAME
    , @cert_name    SYSNAME
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
        , @pvt          CHAR(2)

    -- Validate db and initialize dynamic variables
    EXEC [InitDynamicSQL]
          @db_name      OUTPUT
        , @executesql   OUTPUT
        , @sql_start    OUTPUT
        , @sql_end      OUTPUT

    EXEC [Validation].[ValidateCertName] @db_name, @cert_name OUTPUT, 1, @debug

    -- Remove certificate private key
    SELECT
        @sql =
            @sql_start
            + 'ALTER CERTIFICATE ' + QUOTENAME(@cert_name, '"') + '
            REMOVE PRIVATE KEY'
            + @sql_end
    IF @debug = 1 PRINT '-- Removing private key from certificate: "' + @cert_name + '"'
    IF @debug = 1 PRINT @sql
    EXEC @executesql @sql

    -- Make sure that the private key is really gone
    SELECT
        @sql =
            @sql_start
            + 'SELECT @pvt = [pvt_key_encryption_type]
            FROM [sys].[certificates]
            WHERE [name] = @cert_name'
            + @sql_end
        , @params =
            '@pvt CHAR(2) OUTPUT
            ,@cert_name SYSNAME'
    IF @debug = 1 PRINT '-- Ensuring private key dropped from certificate: "' + @cert_name + '"'
    IF @debug = 1 PRINT @sql
    EXEC @executesql @sql, @params
            , @pvt OUTPUT
            , @cert_name
    IF ISNULL(@pvt, '') <> 'NA'
        RAISERROR('Private key for %s not dropped as expected.', 16, 1, @cert_name)

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
