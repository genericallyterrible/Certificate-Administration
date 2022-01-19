USE [Certificate_Administration]
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- ======================================================================
-- Author:          John Merkel
-- Creation date:   October 1, 2021
-- Description:     Checks to see if a certificate exists.
-- Return:          Certificate name exactly as it appears in
--                  sys.certificates or NULL.
-- Requires:        SA
-- ======================================================================

CREATE OR ALTER PROCEDURE [Validation].[ValidateCertName]
      @db_name      SYSNAME
    , @cert_name    SYSNAME OUTPUT
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
        , @orig_name    SYSNAME

    -- Validate db and initialize dynamic variables
    EXEC [InitDynamicSQL]
          @db_name      OUTPUT
        , @executesql   OUTPUT
        , @sql_start    OUTPUT
        , @sql_end      OUTPUT

    SELECT
        -- Use MIN to get NULL if certificate name does not exist
        @sql =
            @sql_start
            + 'SELECT
                @cert_name = MIN([c].[name])
            FROM
                [sys].[certificates] AS [c]
            WHERE
                [c].[name] = @cert_name'
            + @sql_end
        , @params = 
            '@cert_name SYSNAME OUTPUT'
        , @orig_name = @cert_name
    IF @debug = 1 PRINT '-- Validating certificate: "' + @cert_name + '"'
    IF @debug = 1 PRINT @sql
    EXEC @executesql @sql, @params
            , @cert_name OUTPUT

    IF @cert_name IS NULL
    BEGIN
        IF @raiserror = 1
            RAISERROR('No certificate found named "%s"', 16, 1 , @orig_name)
        IF @debug = 1
            PRINT '-- No certificate found named ' + QUOTENAME(@orig_name, '"')
                + CHAR(13) + CHAR(10)
        RETURN
    END

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
