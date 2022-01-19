USE [Certificate_Administration]
GO

DROP TABLE IF EXISTS [Permission].[SourceObject]
GO

CREATE TABLE [Permission].[SourceObject] (
      [SourceObjectID]      INT NOT NULL    IDENTITY (1,1)
    , [SourceDatabaseID]    INT NOT NULL
    , [object_id]           INT NOT NULL
    , CONSTRAINT [PK_SourceObject]
        PRIMARY KEY CLUSTERED (SourceObjectID)
    , CONSTRAINT [UQ_SourceObject_DatabaseObject]
        UNIQUE ([SourceDatabaseID], [object_id])
    , CONSTRAINT [FK_SourceDatabase_SourceObject]
        FOREIGN KEY ([SourceDatabaseID])
        REFERENCES [Permission].[SourceDatabase] ([SourceDatabaseID])
        ON DELETE NO ACTION
        ON UPDATE NO ACTION
)
GO

CREATE OR ALTER TRIGGER [Permission].[DELETE_SourceObject]
    ON [Permission].[SourceObject]
    INSTEAD OF DELETE
AS
BEGIN
    SET NOCOUNT ON;
    DELETE FROM [Permission].[SourceGroupObject] WHERE [SourceObjectID] IN (SELECT [SourceObjectID] FROM DELETED)
    DELETE FROM [Permission].[SourceObject]      WHERE [SourceObjectID] IN (SELECT [SourceObjectID] FROM DELETED)
END
GO
