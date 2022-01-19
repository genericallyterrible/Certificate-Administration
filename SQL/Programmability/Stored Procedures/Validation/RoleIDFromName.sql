USE [Certificate_Administration]
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- ======================================================================
-- Author:          John Merkel
-- Creation date:   October 6, 2021
-- Description:     
-- Requires:        SA
-- ======================================================================

CREATE OR ALTER PROCEDURE [Validation].[RoleIDFromName]
      @db_name      SYSNAME
    , @role_name    SYSNAME
    , @role_id      INT OUTPUT
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

    -- Initialize dynamic sql
    EXEC [InitDynamicSQL]
          @db_name      OUTPUT
        , @executesql   OUTPUT
        , @sql_start    OUTPUT
        , @sql_end      OUTPUT

    SELECT
        @sql =
            @sql_start
            + 'SELECT
                @role_id = MIN([principal_id])
            FROM
                [sys].[database_principals]
            WHERE
                [type] = ''R''
                AND [name] = @role_name'
            + @sql_end
        , @params =
            '@role_id INT OUTPUT
            , @role_name SYSNAME'
    IF @debug = 1 PRINT @sql
    EXEC @executesql @sql, @params
        , @role_id OUTPUT
        , @role_name

    IF @raiserror = 1 AND @role_id IS NULL
        RAISERROR('Could not find role %s', 16, 1, @role_name)

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
