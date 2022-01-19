USE [Certificate_Administration]
GO

DROP TABLE IF EXISTS [Permission].[TargetDatabase]
GO

CREATE TABLE [Permission].[TargetDatabase] (
      [TargetDatabaseID]    INT NOT NULL    IDENTITY (1,1)
    , [database_id]         INT NOT NULL
    , CONSTRAINT [PK_TargetDatabase]
        PRIMARY KEY CLUSTERED (TargetDatabaseID)
    , CONSTRAINT [UQ_TargetDatabase_DatabaseID]
        UNIQUE ([database_id])
)
GO
