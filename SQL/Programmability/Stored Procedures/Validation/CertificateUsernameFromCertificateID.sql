USE [Certificate_Administration]
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- ======================================================================
-- Author:          John Merkel
-- Creation date:   October 20, 2021
-- Description:     
-- Requires:        SA
-- ======================================================================

CREATE OR ALTER PROCEDURE [Validation].[CertUsernameFromCertID]
      @db_id            INT
    , @certificate_id   INT
    , @username         SYSNAME OUTPUT
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
        , @db_name      SYSNAME

    -- Convert db_id to db_name
    EXEC [Validation].[DBNameFromID]
          @db_id
        , @db_name OUTPUT
        , @raiserror

    -- Validate db_name and initialize dynamic variables
    EXEC [InitDynamicSQL]
          @db_name      OUTPUT
        , @executesql   OUTPUT
        , @sql_start    OUTPUT
        , @sql_end      OUTPUT

    SELECT
        @sql =
            @sql_start
            + 'SELECT
                @username = MIN([dp].[name])
            FROM
                [sys].[database_principals] AS [dp]
                JOIN [sys].[certificates] AS [c]
                    ON [dp].[sid] = [c].[sid]
            WHERE
                [c].[certificate_id] = @certificate_id'
            + @sql_end
        , @params =
            '@username SYSNAME OUTPUT
            , @certificate_id INT'
    IF @debug = 1 PRINT '-- Getting certificate username'
    IF @debug = 1 PRINT @sql
    EXEC @executesql @sql, @params
            , @username OUTPUT
            , @certificate_id

    IF @raiserror = 1 AND @username IS NULL
        RAISERROR('Could not find user for certificate %d', 16, 1, @certificate_id)

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
