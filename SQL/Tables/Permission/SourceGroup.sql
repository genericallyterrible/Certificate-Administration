USE [Certificate_Administration]
GO

DROP TABLE IF EXISTS [Permission].[SourceGroup]
GO

CREATE TABLE [Permission].[SourceGroup] (
      [SourceGroupID]       INT             NOT NULL    IDENTITY (1,1)
    , [SourceDatabaseID]    INT             NOT NULL
    , [Name]                SYSNAME
    , CONSTRAINT [PK_SourceGroup]
        PRIMARY KEY CLUSTERED (SourceGroupID)
    , CONSTRAINT [UQ_SourceGroup_DatabaseGroup]
        UNIQUE ([SourceDatabaseID], [Name])
    , CONSTRAINT [FK_SourceDatabase_SourceGroup]
        FOREIGN KEY ([SourceDatabaseID])
        REFERENCES [Permission].[SourceDatabase] ([SourceDatabaseID])
        ON DELETE NO ACTION
        ON UPDATE NO ACTION
)
GO

CREATE OR ALTER TRIGGER [Permission].[DELETE_SourceGroup]
    ON [Permission].[SourceGroup]
    INSTEAD OF DELETE
AS
BEGIN
    SET NOCOUNT ON;
    DELETE FROM [Permission].[SourceGroupObject] WHERE [SourceGroupID] IN (SELECT [SourceGroupID] FROM DELETED)
    DELETE FROM [Permission].[SourceGroup]       WHERE [SourceGroupID] IN (SELECT [SourceGroupID] FROM DELETED)
END
GO
