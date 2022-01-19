USE [Certificate_Administration]
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- ======================================================================
-- Author:          John Merkel
-- Creation date:   October 20, 2021
-- Description:     Drops a certificate from a provided DB.
-- Requires:        SA
-- ======================================================================

CREATE OR ALTER PROCEDURE [Validation].[CertThumbprintFromID]
      @db_id        INT
    , @cert_id      INT
    , @thumbprint   VARBINARY(32) OUTPUT
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
        , @db_name      SYSNAME

    EXEC [Validation].[DBNameFromID] @db_id, @db_name OUTPUT, 1

    -- Validate db and initialize dynamic variables
    EXEC [InitDynamicSQL]
          @db_name      OUTPUT
        , @executesql   OUTPUT
        , @sql_start    OUTPUT
        , @sql_end      OUTPUT

    SELECT
        @sql =
            @sql_start
            + 'SELECT @thumbprint = [c].[thumbprint]
            FROM [sys].[certificates] AS [c]
            WHERE [c].[certificate_id] = @cert_id'
            + @sql_end
        , @params =
            '@thumbprint VARBINARY(32) OUTPUT
            , @cert_id INT'
    IF @debug = 1 PRINT CONCAT('-- Getting thumbprint of certificate with id: "', @cert_id, '" in database: "', @db_name, '"')
    IF @debug = 1 PRINT @sql
    EXEC @executesql @sql, @params
        , @thumbprint OUTPUT
        , @cert_id

    IF @raiserror = 1 AND @thumbprint IS NULL
        RAISERROR('No thumbprint found for certificate: "%d" in database: "%s"', 16, 1, @cert_id, @db_name)

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
