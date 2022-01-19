USE [Certificate_Administration]
GO

DROP TABLE IF EXISTS [Permission].[SourceGroupCertificate]
GO

CREATE TABLE [Permission].[SourceGroupCertificate] (
      [SourceGroupCertificateID]    INT NOT NULL    IDENTITY (1,1)
    , [SourceGroupID]               INT NOT NULL
    , [certificate_id]              INT NOT NULL
    , CONSTRAINT [PK_SourceGroupCertificate]
        PRIMARY KEY CLUSTERED ([SourceGroupCertificateID])
    , CONSTRAINT [UQ_SourceGroupCertificate_SourceGroupID]
        UNIQUE ([SourceGroupID])
    , CONSTRAINT [FK_SourceGroup_SourceGroupCertificate]
        FOREIGN KEY ([SourceGroupID])
        REFERENCES [Permission].[SourceGroup] ([SourceGroupID])
        ON DELETE CASCADE
        ON UPDATE CASCADE
)
GO
