USE [Certificate_Administration]
GO

CREATE OR ALTER VIEW [Permission].[Certificates]
AS
SELECT
      'GROUP'                       AS [SourceType]
    , [sd].[SourceDatabaseID]       AS [SourceDatabaseID]
    , [sd].[database_id]            AS [src_db_id]
    , DB_NAME([sd].[database_id])   AS [src_db_name]
    , [sg].[SourceGroupID]          AS [SourceGroupID]
    , [sg].[Name]                   AS [SourceGroupName]
    , NULL                          AS [SourceObjectID]
    , NULL                          AS [src_object_id]
    , NULL                          AS [src_object_name]
    , [sgc].[certificate_id]        AS [src_certificate_id]
    , [td].[TargetDatabaseID]       AS [TargetDatabaseID]
    , [td].[database_id]            AS [tar_db_id]
    , DB_NAME([td].[database_id])   AS [tar_db_name]
    , [tgc].[certificate_id]        AS [tar_certificate_id]
FROM
    (
        [Permission].[SourceGroupCertificate]   AS [sgc]
        JOIN [Permission].[SourceGroup]         AS [sg]
            ON [sgc].[SourceGroupID] = [sg].[SourceGroupID]
        JOIN [Permission].[SourceDatabase]      AS [sd]
            ON [sg].[SourceDatabaseID] = [sd].[SourceDatabaseID]
    ) LEFT JOIN (
        [Permission].[TargetGroupCertificate]   AS [tgc]
        JOIN [Permission].[TargetDatabase]      AS [td]
            ON [tgc].[TargetDatabaseID] = [td].[TargetDatabaseID]
    ) ON [sgc].[SourceGroupCertificateID] = [tgc].[SourceGroupCertificateID]
UNION
SELECT
      'OBJECT'                                          AS [SourceType]
    , [sd].[SourceDatabaseID]                           AS [SourceDatabaseID]
    , [sd].[database_id]                                AS [src_db_id]
    , DB_NAME([sd].[database_id])                       AS [src_db_name]
    , NULL                                              AS [SourceGroupID]
    , NULL                                              AS [SourceGroupName]
    , [so].[SourceObjectID]                             AS [SourceObjectID]
    , [so].[object_id]                                  AS [src_object_id]
    , OBJECT_NAME([so].[object_id], [sd].[database_id]) AS [src_object_name]
    , [soc].[certificate_id]                            AS [src_certificate_id]
    , [td].[TargetDatabaseID]                           AS [TargetDatabaseID]
    , [td].[database_id]                                AS [tar_db_id]
    , DB_NAME([td].[database_id])                       AS [tar_db_name]
    , [toc].[certificate_id]                            AS [tar_certificate_id]
FROM
    (
        [Permission].[SourceObjectCertificate]  AS [soc]
        JOIN [Permission].[SourceObject]        AS [so]
            ON [soc].[SourceObjectID] = [so].[SourceObjectID]
        JOIN [Permission].[SourceDatabase]      AS [sd]
            ON [so].[SourceDatabaseID] = [sd].[SourceDatabaseID]
    ) LEFT JOIN (
        [Permission].[TargetObjectCertificate]  AS [toc]
        JOIN [Permission].[TargetDatabase]      AS [td]
            ON [toc].[TargetDatabaseID] = [td].[TargetDatabaseID]
    ) ON [soc].[SourceObjectCertificateID] = [toc].[SourceObjectCertificateID]
GO
