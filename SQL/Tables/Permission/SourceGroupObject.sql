USE [Certificate_Administration]
GO

DROP TABLE IF EXISTS [Permission].[SourceGroupObject]
GO

CREATE TABLE [Permission].[SourceGroupObject] (
      [SourceGroupID]   INT NOT NULL
    , [SourceObjectID]  INT NOT NULL
    , CONSTRAINT [PK_SourceGroupObject]
        PRIMARY KEY CLUSTERED ([SourceGroupID], [SourceObjectID])
    , CONSTRAINT [FK_SourceGroup_SourceGroupObject]
        FOREIGN KEY ([SourceGroupID])
        REFERENCES [Permission].[SourceGroup] ([SourceGroupID])
        ON DELETE NO ACTION
        ON UPDATE NO ACTION
    , CONSTRAINT [FK_SourceObject_SourceGroupObject]
        FOREIGN KEY ([SourceObjectID])
        REFERENCES [Permission].[SourceObject] ([SourceObjectID])
        ON DELETE NO ACTION
        ON UPDATE NO ACTION
)
GO

CREATE TRIGGER [Permission].[INSERT_SourceGroupObject]
    ON [Permission].[SourceGroupObject]
    INSTEAD OF INSERT
AS
BEGIN
    INSERT INTO [Permission].[SourceGroupObject]
    SELECT [i].*
    FROM
        [INSERTED] AS [i]
        JOIN [Permission].[SourceGroup] AS [sg]
            ON [i].[SourceGroupID] = [sg].[SourceGroupID]
        JOIN [Permission].[SourceObject] AS [so]
            ON [i].[SourceObjectID] = [so].[SourceObjectID]
    WHERE
        [sg].[SourceDatabaseID] = [so].[SourceDatabaseID]
END
GO
