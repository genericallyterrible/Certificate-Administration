USE [Certificate_Administration]
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- ======================================================================
-- Author:          John Merkel
-- Creation date:   October 1, 2021
-- Description:     Checks to see if schema and object exists.
-- Return:          Schema and object names exactly as they appear in
--                  sys.schemas and sys.objects.
--                  @object is schema_name.object_name, each quoted.
-- Requires:        SA
-- ======================================================================

CREATE OR ALTER PROCEDURE [Validation].[ValidateSchemaObject]
      @db_name      SYSNAME
    , @schema_name  SYSNAME OUTPUT
    , @object_name  SYSNAME OUTPUT
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
        , @object       NVARCHAR(517) =
                QUOTENAME(@schema_name)
                + '.' + QUOTENAME(@object_name)
        -- QUOTENAME() reutrns NVARCHAR(258).
        -- Multiply by 2 and add 1 for the '.' gives 517.

    -- Validate db and initialize dynamic variables
    EXEC [InitDynamicSQL]
          @db_name      OUTPUT
        , @executesql   OUTPUT
        , @sql_start    OUTPUT
        , @sql_end      OUTPUT

    SELECT
        @sql =
            @sql_start + 
            'SELECT
                @schema_name = MIN([s].[name])
                , @object_name = MIN([o].[name])
            FROM
                [sys].[objects] AS [o]
                JOIN [sys].[schemas] AS [s]
                    ON [o].[schema_id] = [s].[schema_id]
            WHERE
                [o].[object_id] = OBJECT_ID(@object)'
            + @sql_end
        , @params =
            '@schema_name SYSNAME OUTPUT
            , @object_name SYSNAME OUTPUT
            , @object NVARCHAR(260)'
    IF @debug = 1 PRINT '-- Validating object: "' + @object + '"'
    IF @debug = 1 PRINT @sql
    EXEC @executesql @sql, @params
        , @schema_name OUTPUT
        , @object_name OUTPUT
        , @object
    IF @raiserror = 1 AND (
        @schema_name IS NULL
        OR @object_name IS NULL
    )   RAISERROR('No object %s in database %s.', 16, 1, @object, @db_name)

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
