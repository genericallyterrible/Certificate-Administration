USE [Certificate_Administration]
GO

DROP TABLE IF EXISTS [Permission].[TargetObject]
GO

CREATE TABLE [Permission].[TargetObject] (
      [TargetObjectID]      INT NOT NULL    IDENTITY (1,1)
    , [TargetDatabaseID]    INT NOT NULL
    , [object_id]           INT NOT NULL
    , CONSTRAINT [PK_TargetObject]
        PRIMARY KEY CLUSTERED (TargetObjectID)
    , CONSTRAINT [UQ_TargetObject_DatabaseObject]
        UNIQUE ([TargetDatabaseID], [object_id])
    , CONSTRAINT [FK_TargetDatabase_TargetObject]
        FOREIGN KEY ([TargetDatabaseID])
        REFERENCES [Permission].[TargetDatabase] ([TargetDatabaseID])
        ON DELETE CASCADE
        ON UPDATE CASCADE
)
GO
