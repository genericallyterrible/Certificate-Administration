USE [Certificate_Administration]
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- ======================================================================
-- Author:          John Merkel
-- Creation date:   October 1, 2021
-- Description:     Checks to see if a certificate user exists for
--                  a given certificate and returns the username.
-- Return:          Username exactly as it appears in
--                  sys.database_principals or NULL.
-- Requires:        SA
-- ======================================================================

CREATE OR ALTER PROCEDURE [Validation].[ValidateCertUsername]
      @db_name      SYSNAME
    , @cert_name    SYSNAME
    , @username     SYSNAME OUTPUT
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

    SELECT
        -- Use MIN to get NULL if username does not exist
        @sql =
            @sql_start
            + 'SELECT
                @username = MIN([dp].[name])
            FROM
                [sys].[database_principals] AS [dp]
                JOIN [sys].[certificates] AS [c]
                    ON [dp].[sid] = [c].[sid]
            WHERE
                [c].[name] = @cert_name'
            + @sql_end
        , @params = 
            '@username SYSNAME OUTPUT
            , @cert_name SYSNAME'
    IF @debug = 1 PRINT '-- Validating user for certificate: "' + @cert_name + '"'
    IF @debug = 1 PRINT @sql
    EXEC @executesql @sql, @params
            , @username OUTPUT
            , @cert_name

    IF @username IS NULL
    BEGIN
        IF @raiserror = 1
            RAISERROR('No certificate user found for "%s"', 16, 1, @cert_name)
        IF @debug = 1
            PRINT '-- No certificate user found for ' + QUOTENAME(@cert_name, '"')
                + CHAR(13) + CHAR(10)
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
