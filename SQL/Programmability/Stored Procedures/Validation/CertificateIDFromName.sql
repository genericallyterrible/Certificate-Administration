USE [Certificate_Administration]
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- ======================================================================
-- Author:          John Merkel
-- Creation date:   October 8, 2021
-- Description:     
-- Requires:        SA
-- ======================================================================

CREATE OR ALTER PROCEDURE [Validation].[CertificateIDFromName]
      @db_name          SYSNAME
    , @certificate_name SYSNAME
    , @certificate_id   INT OUTPUT
    , @raiserror        BIT = 1
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
        , @params       NVARCHAR(MAX)

    -- Validate db_name and initialize dynamic variables
    EXEC [dbo].[InitDynamicSQL]
          @db_name      OUTPUT
        , @executesql   OUTPUT
        , @sql_start    OUTPUT
        , @sql_end      OUTPUT

    SELECT
        @sql =
            @sql_start
            + 'SELECT
                @certificate_id = MIN([certificate_id])
            FROM
                [sys].[certificates]
            WHERE
                [name] = @certificate_name'
            + @sql_end
        , @params =
            '@certificate_id INT OUTPUT
            , @certificate_name SYSNAME'
    IF @debug = 1 PRINT '-- Getting certificate name'
    IF @debug = 1 PRINT @sql
    EXEC @executesql @sql, @params
            , @certificate_id OUTPUT
            , @certificate_name

    IF @raiserror = 1 AND @certificate_id IS NULL
        RAISERROR('Could not find certificate %s', 16, 1, @certificate_name)

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
