USE [Certificate_Administration]
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- ======================================================================
-- Author:          John Merkel
-- Creation date:   October 4, 2021
-- Description:     Creates a new certificate in the specified database
--                  with a random password and returns the password.
-- Return:          @pwd CHAR(39) with randomly generated password
-- Requires:        SA
-- ======================================================================

CREATE OR ALTER PROCEDURE [Definition].[CreateCertByPwd]
      @db_name      SYSNAME
    , @cert_name    SYSNAME
    , @pwd          CHAR(39) OUTPUT
    , @subject      NVARCHAR(4000)
    , @cert_id      INT OUTPUT
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


    -- Validate db and initialize dynamic variables
    EXEC [InitDynamicSQL]
          @db_name      OUTPUT
        , @executesql   OUTPUT
        , @sql_start    OUTPUT
        , @sql_end      OUTPUT

    SELECT @pwd = CONVERT(CHAR(36), NEWID()) + 'Aa0'
    SELECT
        @sql =
            @sql_start
            + 'CREATE CERTIFICATE ' + QUOTENAME(@cert_name, '"') + '
            ENCRYPTION BY PASSWORD = ' + QUOTENAME(@pwd, '''') + '
            WITH SUBJECT = ' + QUOTENAME(@subject, '''')
            + @sql_end
    IF @debug = 1 PRINT '-- Creating certificate: "' + @cert_name + '"'
    IF @debug = 1 PRINT @sql
    EXEC @executesql @sql

    EXEC [Validation].[CertificateIDFromName] @db_name, @cert_name, @cert_id OUTPUT, 1, @debug

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
