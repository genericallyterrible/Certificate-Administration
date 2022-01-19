USE [Certificate_Administration]
GO

DROP TABLE IF EXISTS [Permission].[SourceDatabase]
GO

CREATE TABLE [Permission].[SourceDatabase] (
      [SourceDatabaseID]    INT NOT NULL    IDENTITY (1,1)
    , [database_id]         INT NOT NULL
    , CONSTRAINT [PK_SourceDatabase]
        PRIMARY KEY CLUSTERED (SourceDatabaseID)
    , CONSTRAINT [UQ_SourceDatabase_DatabaseID]
        UNIQUE ([database_id])
)
GO

CREATE OR ALTER TRIGGER [Permission].[DELETE_SourceDatabase]
    ON [Permission].[SourceDatabase]
    INSTEAD OF DELETE
AS
BEGIN
    SET NOCOUNT ON;
    DELETE FROM [Permission].[SourceObject]   WHERE [SourceDatabaseID] IN (SELECT [SourceDatabaseID] FROM DELETED)
    DELETE FROM [Permission].[SourceGroup]    WHERE [SourceDatabaseID] IN (SELECT [SourceDatabaseID] FROM DELETED)
    DELETE FROM [Permission].[SourceDatabase] WHERE [SourceDatabaseID] IN (SELECT [SourceDatabaseID] FROM DELETED)
END
GO
