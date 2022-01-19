USE [Certificate_Administration]
GO

DROP TABLE IF EXISTS [Permission].[SourceObjectCertificate]
GO

CREATE TABLE [Permission].[SourceObjectCertificate] (
      [SourceObjectCertificateID]   INT NOT NULL    IDENTITY (1,1)
    , [SourceObjectID]              INT NOT NULL
    , [certificate_id]              INT NOT NULL
    , CONSTRAINT [PK_SourceObjectCertificate]
        PRIMARY KEY CLUSTERED ([SourceObjectCertificateID])
    , CONSTRAINT [UQ_SourceObjectCertificate_SourceObjectID]
        UNIQUE ([SourceObjectID])
    , CONSTRAINT [FK_SourceObject_SourceObjectCertificate]
        FOREIGN KEY ([SourceObjectID])
        REFERENCES [Permission].[SourceObject] ([SourceObjectID])
        ON DELETE CASCADE
        ON UPDATE CASCADE
)
GO
