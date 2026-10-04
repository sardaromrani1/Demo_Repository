/* ================================================================
   INDUSTRIAL DATA ANALYTICS PLATFORM
   PHASE 10.7-B
   INDEX CREATION PREFLIGHT

   Database:
       ComprehensiveInstrumentationDB_New

   PURPOSE:
       Read-only preflight audit before creating approved
       FK-supporting and performance indexes.

   IMPORTANT:
       This script DOES NOT:
           CREATE INDEX
           DROP INDEX
           ALTER TABLE
           ALTER INDEX
           MODIFY DATA

   STATUS:
       READ-ONLY
================================================================ */

USE ComprehensiveInstrumentationDB_New;
GO

SET NOCOUNT ON;
GO


/* ================================================================
   PART 0 — ENVIRONMENT
================================================================ */

SELECT
    DB_NAME() AS DatabaseName,
    @@SERVERNAME AS ServerName,
    GETDATE() AS AuditDateTime,
    'READ-ONLY PREFLIGHT' AS AuditMode;
GO


/* ================================================================
   PART 1 — CANDIDATE INDEX DEFINITIONS
================================================================ */

IF OBJECT_ID('tempdb..#CandidateIndexes') IS NOT NULL
    DROP TABLE #CandidateIndexes;
GO

CREATE TABLE #CandidateIndexes
(
    CandidateId INT IDENTITY(1,1) NOT NULL,
    SchemaName SYSNAME NOT NULL,
    TableName SYSNAME NOT NULL,
    ProposedIndexName SYSNAME NOT NULL,
    KeyColumns NVARCHAR(1000) NOT NULL,
    IncludeColumns NVARCHAR(1000) NULL,
    FilterDefinition NVARCHAR(1000) NULL,
    PriorityCode VARCHAR(20) NOT NULL,
    SourceCode VARCHAR(50) NOT NULL,
    Reason NVARCHAR(1000) NOT NULL
);
GO


/* ---------------------------------------------------------------
   HIGH PRIORITY PERFORMANCE CANDIDATES
---------------------------------------------------------------- */

INSERT INTO #CandidateIndexes
(
    SchemaName,
    TableName,
    ProposedIndexName,
    KeyColumns,
    IncludeColumns,
    FilterDefinition,
    PriorityCode,
    SourceCode,
    Reason
)
VALUES

(
    'event',
    'MaintenanceRecords',
    'IX_MaintenanceRecords_InstrumentId_MaintenanceDate',
    'InstrumentId,MaintenanceDate',
    NULL,
    NULL,
    'HIGH',
    '10.7-A',
    'Instrument maintenance history lookup by InstrumentId ordered by MaintenanceDate'
),

(
    'event',
    'FailureRecords',
    'IX_FailureRecords_InstrumentId_FailureDate',
    'InstrumentId,FailureDate',
    NULL,
    NULL,
    'HIGH',
    '10.7-A',
    'Instrument failure history lookup by InstrumentId ordered by FailureDate'
),

(
    'event',
    'CalibrationRecords',
    'IX_CalibrationRecords_InstrumentId_CalibrationDate',
    'InstrumentId,CalibrationDate',
    NULL,
    NULL,
    'HIGH',
    '10.7-A',
    'Instrument calibration history lookup by InstrumentId ordered by CalibrationDate'
),

(
    'event',
    'InstrumentLifecycle',
    'IX_InstrumentLifecycle_InstrumentId_EffectiveFrom',
    'InstrumentId,EffectiveFrom',
    NULL,
    NULL,
    'HIGH',
    '10.7-A',
    'Instrument lifecycle history lookup by InstrumentId ordered by EffectiveFrom'
),

(
    'event',
    'InstrumentOperationalStatusHistory',
    'IX_InstrumentOperationalStatusHistory_InstrumentId_EffectiveFrom',
    'InstrumentId,EffectiveFrom',
    NULL,
    NULL,
    'HIGH',
    '10.7-A',
    'Operational status history lookup by InstrumentId ordered by EffectiveFrom'
),

(
    'event',
    'InstrumentBypassHistory',
    'IX_InstrumentBypassHistory_InstrumentId_BypassStartDateTime',
    'InstrumentId,BypassStartDateTime',
    NULL,
    NULL,
    'HIGH',
    '10.7-A',
    'Bypass history lookup by InstrumentId ordered by BypassStartDateTime'
);


/* ---------------------------------------------------------------
   MEDIUM PRIORITY PERFORMANCE CANDIDATES
---------------------------------------------------------------- */

INSERT INTO #CandidateIndexes
(
    SchemaName,
    TableName,
    ProposedIndexName,
    KeyColumns,
    IncludeColumns,
    FilterDefinition,
    PriorityCode,
    SourceCode,
    Reason
)
VALUES

(
    'event',
    'SparePartUsage',
    'IX_SparePartUsage_InstrumentId_UsageDateTime',
    'InstrumentId,UsageDateTime',
    NULL,
    NULL,
    'MEDIUM',
    '10.7-A',
    'Spare part usage history lookup by InstrumentId ordered by UsageDateTime'
),

(
    'event',
    'SparePartUsage',
    'IX_SparePartUsage_SparePartId_UsageDateTime',
    'SparePartId,UsageDateTime',
    NULL,
    NULL,
    'MEDIUM',
    '10.7-A',
    'Spare part usage history lookup by SparePartId ordered by UsageDateTime'
),

(
    'inv',
    'InventoryTransactions',
    'IX_InventoryTransactions_SparePartId_TransactionDateTime',
    'SparePartId,TransactionDateTime',
    NULL,
    NULL,
    'MEDIUM',
    '10.7-A',
    'Inventory transaction history lookup by SparePartId ordered by TransactionDateTime'
),

(
    'inv',
    'InventoryTransactions',
    'IX_InventoryTransactions_InventoryLocationId_TransactionDateTime',
    'InventoryLocationId,TransactionDateTime',
    NULL,
    NULL,
    'MEDIUM',
    '10.7-A',
    'Inventory transaction history lookup by InventoryLocationId ordered by TransactionDateTime'
),

(
    'rel',
    'TripInstruments',
    'IX_TripInstruments_InstrumentId_TripId',
    'InstrumentId,TripId',
    NULL,
    NULL,
    'MEDIUM',
    '10.7-A',
    'Trip lookup by InstrumentId with TripId access'
),

(
    'rel',
    'SparePartInstruments',
    'IX_SparePartInstruments_InstrumentId_SparePartId',
    'InstrumentId,SparePartId',
    NULL,
    NULL,
    'MEDIUM',
    '10.7-A',
    'Spare part compatibility lookup by InstrumentId'
),

(
    'rel',
    'SparePartInstrumentTypes',
    'IX_SparePartInstrumentTypes_InstrumentTypeId_SparePartId',
    'InstrumentTypeId,SparePartId',
    NULL,
    NULL,
    'MEDIUM',
    '10.7-A',
    'Spare part compatibility lookup by InstrumentTypeId'
);
GO


/* ================================================================
   PART 2 — CANDIDATE INVENTORY
================================================================ */

SELECT
    CandidateId,
    SchemaName,
    TableName,
    ProposedIndexName,
    KeyColumns,
    IncludeColumns,
    FilterDefinition,
    PriorityCode,
    SourceCode,
    Reason
FROM #CandidateIndexes
ORDER BY
    CASE PriorityCode
        WHEN 'HIGH' THEN 1
        WHEN 'MEDIUM' THEN 2
        ELSE 3
    END,
    CandidateId;
GO


/* ================================================================
   PART 3 — RESOLVE TABLE OBJECTS
================================================================ */

IF OBJECT_ID('tempdb..#ResolvedCandidates') IS NOT NULL
    DROP TABLE #ResolvedCandidates;
GO

CREATE TABLE #ResolvedCandidates
(
    CandidateId INT NOT NULL,
    SchemaName SYSNAME NOT NULL,
    TableName SYSNAME NOT NULL,
    ProposedIndexName SYSNAME NOT NULL,
    ObjectId INT NULL,
    TableExists BIT NOT NULL,
    KeyColumns NVARCHAR(1000) NOT NULL,
    PriorityCode VARCHAR(20) NOT NULL
);
GO

INSERT INTO #ResolvedCandidates
(
    CandidateId,
    SchemaName,
    TableName,
    ProposedIndexName,
    ObjectId,
    TableExists,
    KeyColumns,
    PriorityCode
)
SELECT
    c.CandidateId,
    c.SchemaName,
    c.TableName,
    c.ProposedIndexName,
    o.object_id,
    CASE
        WHEN o.object_id IS NULL THEN 0
        ELSE 1
    END AS TableExists,
    c.KeyColumns,
    c.PriorityCode
FROM #CandidateIndexes c
LEFT JOIN sys.objects o
    ON o.schema_id = SCHEMA_ID(c.SchemaName)
    AND o.name = c.TableName
    AND o.type = 'U';
GO


/* ================================================================
   PART 4 — TABLE EXISTENCE CHECK
================================================================ */

SELECT
    CandidateId,
    SchemaName,
    TableName,
    ProposedIndexName,
    TableExists,
    CASE
        WHEN TableExists = 1
            THEN 'TABLE_EXISTS'
        ELSE 'ERROR_TABLE_NOT_FOUND'
    END AS Status
FROM #ResolvedCandidates
ORDER BY CandidateId;
GO


/* ================================================================
   PART 5 — EXISTING INDEX INVENTORY FOR CANDIDATE TABLES
================================================================ */

IF OBJECT_ID('tempdb..#ExistingIndexes') IS NOT NULL
    DROP TABLE #ExistingIndexes;
GO

CREATE TABLE #ExistingIndexes
(
    ObjectId INT NOT NULL,
    IndexId INT NOT NULL,
    IndexName SYSNAME NOT NULL,
    IsUnique BIT NOT NULL,
    IsPrimaryKey BIT NOT NULL,
    IsUniqueConstraint BIT NOT NULL,
    IsDisabled BIT NOT NULL,
    TypeDescription NVARCHAR(60) NOT NULL,
    KeyColumns NVARCHAR(4000) NULL,
    IncludedColumns NVARCHAR(4000) NULL,
    FilterDefinition NVARCHAR(4000) NULL
);
GO


INSERT INTO #ExistingIndexes
(
    ObjectId,
    IndexId,
    IndexName,
    IsUnique,
    IsPrimaryKey,
    IsUniqueConstraint,
    IsDisabled,
    TypeDescription,
    KeyColumns,
    IncludedColumns,
    FilterDefinition
)
SELECT
    i.object_id,
    i.index_id,
    i.name,
    i.is_unique,
    i.is_primary_key,
    i.is_unique_constraint,
    i.is_disabled,
    i.type_desc,

    STUFF
    (
        (
            SELECT
                ','
                + QUOTENAME(c.name)
            FROM sys.index_columns ic
            INNER JOIN sys.columns c
                ON c.object_id = ic.object_id
                AND c.column_id = ic.column_id
            WHERE ic.object_id = i.object_id
              AND ic.index_id = i.index_id
              AND ic.key_ordinal > 0
            ORDER BY ic.key_ordinal
            FOR XML PATH(''), TYPE
        ).value('.', 'NVARCHAR(4000)'),
        1,
        1,
        ''
    ) AS KeyColumns,

    STUFF
    (
        (
            SELECT
                ','
                + QUOTENAME(c.name)
            FROM sys.index_columns ic
            INNER JOIN sys.columns c
                ON c.object_id = ic.object_id
                AND c.column_id = ic.column_id
            WHERE ic.object_id = i.object_id
              AND ic.index_id = i.index_id
              AND ic.is_included_column = 1
            ORDER BY c.column_id
            FOR XML PATH(''), TYPE
        ).value('.', 'NVARCHAR(4000)'),
        1,
        1,
        ''
    ) AS IncludedColumns,

    i.filter_definition

FROM sys.indexes i
WHERE i.object_id IN
(
    SELECT ObjectId
    FROM #ResolvedCandidates
    WHERE TableExists = 1
);
GO


/* ================================================================
   PART 6 — EXISTING INDEXES ON CANDIDATE TABLES
================================================================ */

SELECT
    r.CandidateId,
    r.SchemaName,
    r.TableName,
    r.ProposedIndexName,
    e.IndexName AS ExistingIndexName,
    e.TypeDescription,
    e.IsUnique,
    e.IsPrimaryKey,
    e.IsUniqueConstraint,
    e.IsDisabled,
    e.KeyColumns,
    e.IncludedColumns,
    e.FilterDefinition
FROM #ResolvedCandidates r
LEFT JOIN #ExistingIndexes e
    ON e.ObjectId = r.ObjectId
WHERE r.TableExists = 1
ORDER BY
    r.CandidateId,
    e.IndexId;
GO


/* ================================================================
   PART 7 — EXACT INDEX NAME CHECK
================================================================ */

SELECT
    r.CandidateId,
    r.SchemaName,
    r.TableName,
    r.ProposedIndexName,

    CASE
        WHEN EXISTS
        (
            SELECT 1
            FROM sys.indexes i
            WHERE i.object_id = r.ObjectId
              AND i.name = r.ProposedIndexName
        )
        THEN 1
        ELSE 0
    END AS ExactIndexNameExists,

    CASE
        WHEN EXISTS
        (
            SELECT 1
            FROM sys.indexes i
            WHERE i.object_id = r.ObjectId
              AND i.name = r.ProposedIndexName
        )
        THEN 'REVIEW_EXISTING_NAME'
        ELSE 'NO_NAME_CONFLICT'
    END AS Decision
FROM #ResolvedCandidates r
WHERE r.TableExists = 1
ORDER BY r.CandidateId;
GO


/* ================================================================
   PART 8 — NORMALIZE PROPOSED KEY COLUMNS
================================================================ */

IF OBJECT_ID('tempdb..#CandidateKeyColumns') IS NOT NULL
    DROP TABLE #CandidateKeyColumns;
GO

CREATE TABLE #CandidateKeyColumns
(
    CandidateId INT NOT NULL,
    KeyOrdinal INT NOT NULL,
    ColumnName SYSNAME NOT NULL
);
GO


INSERT INTO #CandidateKeyColumns
(
    CandidateId,
    KeyOrdinal,
    ColumnName
)
SELECT
    c.CandidateId,
    CONVERT(INT, s.[key]),
    LTRIM(RTRIM(s.value))
FROM #CandidateIndexes c
CROSS APPLY STRING_SPLIT
(
    c.KeyColumns,
    ',',
    1
) s;
GO


/* ================================================================
   PART 9 — EXISTING INDEX KEY COLUMNS
================================================================ */

IF OBJECT_ID('tempdb..#ExistingKeyColumns') IS NOT NULL
    DROP TABLE #ExistingKeyColumns;
GO

CREATE TABLE #ExistingKeyColumns
(
    ObjectId INT NOT NULL,
    IndexId INT NOT NULL,
    KeyOrdinal INT NOT NULL,
    ColumnName SYSNAME NOT NULL
);
GO


INSERT INTO #ExistingKeyColumns
(
    ObjectId,
    IndexId,
    KeyOrdinal,
    ColumnName
)
SELECT
    ic.object_id,
    ic.index_id,
    ic.key_ordinal,
    c.name
FROM sys.index_columns ic
INNER JOIN sys.columns c
    ON c.object_id = ic.object_id
    AND c.column_id = ic.column_id
WHERE ic.key_ordinal > 0
  AND ic.object_id IN
  (
      SELECT ObjectId
      FROM #ResolvedCandidates
      WHERE TableExists = 1
  );
GO


/* ================================================================
   PART 10 — EXACT KEY DEFINITION MATCH
================================================================ */

IF OBJECT_ID('tempdb..#IndexComparison') IS NOT NULL
    DROP TABLE #IndexComparison;
GO

CREATE TABLE #IndexComparison
(
    CandidateId INT NOT NULL,
    ExistingIndexId INT NULL,
    ExistingIndexName SYSNAME NULL,
    ExactKeyMatch BIT NOT NULL,
    ExistingKeyCount INT NULL,
    CandidateKeyCount INT NOT NULL,
    ExistingKeyColumns NVARCHAR(4000) NULL,
    CandidateKeyColumns NVARCHAR(4000) NOT NULL
);
GO


INSERT INTO #IndexComparison
(
    CandidateId,
    ExistingIndexId,
    ExistingIndexName,
    ExactKeyMatch,
    ExistingKeyCount,
    CandidateKeyCount,
    ExistingKeyColumns,
    CandidateKeyColumns
)
SELECT
    c.CandidateId,
    e.IndexId,
    e.IndexName,

    CASE
        WHEN
            (
                SELECT COUNT(*)
                FROM #CandidateKeyColumns ck
                WHERE ck.CandidateId = c.CandidateId
            )
            =
            (
                SELECT COUNT(*)
                FROM #ExistingKeyColumns ek
                WHERE ek.ObjectId = r.ObjectId
                  AND ek.IndexId = e.IndexId
            )
        AND NOT EXISTS
        (
            SELECT 1
            FROM #CandidateKeyColumns ck
            WHERE ck.CandidateId = c.CandidateId
              AND NOT EXISTS
              (
                  SELECT 1
                  FROM #ExistingKeyColumns ek
                  WHERE ek.ObjectId = r.ObjectId
                    AND ek.IndexId = e.IndexId
                    AND ek.KeyOrdinal = ck.KeyOrdinal
                    AND ek.ColumnName = ck.ColumnName
              )
        )
        THEN 1
        ELSE 0
    END AS ExactKeyMatch,

    (
        SELECT COUNT(*)
        FROM #ExistingKeyColumns ek
        WHERE ek.ObjectId = r.ObjectId
          AND ek.IndexId = e.IndexId
    ),

    (
        SELECT COUNT(*)
        FROM #CandidateKeyColumns ck
        WHERE ck.CandidateId = c.CandidateId
    ),

    e.KeyColumns,
    c.KeyColumns

FROM #CandidateIndexes c
INNER JOIN #ResolvedCandidates r
    ON r.CandidateId = c.CandidateId
INNER JOIN #ExistingIndexes e
    ON e.ObjectId = r.ObjectId
WHERE r.TableExists = 1;
GO


/* ================================================================
   PART 11 — LEFT-PREFIX ANALYSIS
================================================================ */

IF OBJECT_ID('tempdb..#PrefixAnalysis') IS NOT NULL
    DROP TABLE #PrefixAnalysis;
GO

CREATE TABLE #PrefixAnalysis
(
    CandidateId INT NOT NULL,
    ExistingIndexId INT NOT NULL,
    ExistingIndexName SYSNAME NOT NULL,
    CandidateKeyCount INT NOT NULL,
    ExistingKeyCount INT NOT NULL,
    PrefixColumnCount INT NOT NULL,
    PrefixStatus VARCHAR(40) NOT NULL
);
GO


INSERT INTO #PrefixAnalysis
(
    CandidateId,
    ExistingIndexId,
    ExistingIndexName,
    CandidateKeyCount,
    ExistingKeyCount,
    PrefixColumnCount,
    PrefixStatus
)
SELECT
    c.CandidateId,
    e.IndexId,
    e.IndexName,

    (
        SELECT COUNT(*)
        FROM #CandidateKeyColumns ck
        WHERE ck.CandidateId = c.CandidateId
    ) AS CandidateKeyCount,

    (
        SELECT COUNT(*)
        FROM #ExistingKeyColumns ek
        WHERE ek.ObjectId = r.ObjectId
          AND ek.IndexId = e.IndexId
    ) AS ExistingKeyCount,

    ISNULL
    (
        (
            SELECT COUNT(*)
            FROM #CandidateKeyColumns ck
            WHERE ck.CandidateId = c.CandidateId
              AND EXISTS
              (
                  SELECT 1
                  FROM #ExistingKeyColumns ek
                  WHERE ek.ObjectId = r.ObjectId
                    AND ek.IndexId = e.IndexId
                    AND ek.KeyOrdinal = ck.KeyOrdinal
                    AND ek.ColumnName = ck.ColumnName
              )
        ),
        0
    ) AS PrefixColumnCount,

    CASE
        WHEN
        (
            SELECT COUNT(*)
            FROM #CandidateKeyColumns ck
            WHERE ck.CandidateId = c.CandidateId
              AND EXISTS
              (
                  SELECT 1
                  FROM #ExistingKeyColumns ek
                  WHERE ek.ObjectId = r.ObjectId
                    AND ek.IndexId = e.IndexId
                    AND ek.KeyOrdinal = ck.KeyOrdinal
                    AND ek.ColumnName = ck.ColumnName
              )
        )
        =
        (
            SELECT COUNT(*)
            FROM #CandidateKeyColumns ck
            WHERE ck.CandidateId = c.CandidateId
        )
        THEN 'FULL_COVERAGE'

        WHEN
        (
            SELECT COUNT(*)
            FROM #CandidateKeyColumns ck
            WHERE ck.CandidateId = c.CandidateId
              AND EXISTS
              (
                  SELECT 1
                  FROM #ExistingKeyColumns ek
                  WHERE ek.ObjectId = r.ObjectId
                    AND ek.IndexId = e.IndexId
                    AND ek.KeyOrdinal = ck.KeyOrdinal
                    AND ek.ColumnName = ck.ColumnName
              )
        ) > 0
        THEN 'PARTIAL_PREFIX'

        ELSE 'NO_PREFIX'
    END AS PrefixStatus

FROM #CandidateIndexes c
INNER JOIN #ResolvedCandidates r
    ON r.CandidateId = c.CandidateId
INNER JOIN #ExistingIndexes e
    ON e.ObjectId = r.ObjectId
WHERE r.TableExists = 1;
GO


/* ================================================================
   PART 12 — BEST EXISTING COVERAGE PER CANDIDATE
================================================================ */

IF OBJECT_ID('tempdb..#BestCoverage') IS NOT NULL
    DROP TABLE #BestCoverage;
GO

CREATE TABLE #BestCoverage
(
    CandidateId INT NOT NULL,
    BestExistingIndexName SYSNAME NULL,
    BestExistingIndexId INT NULL,
    BestPrefixColumnCount INT NOT NULL,
    BestPrefixStatus VARCHAR(40) NOT NULL
);
GO


INSERT INTO #BestCoverage
(
    CandidateId,
    BestExistingIndexName,
    BestExistingIndexId,
    BestPrefixColumnCount,
    BestPrefixStatus
)
SELECT
    p.CandidateId,
    p.ExistingIndexName,
    p.ExistingIndexId,
    p.PrefixColumnCount,
    p.PrefixStatus
FROM #PrefixAnalysis p
WHERE p.PrefixColumnCount =
(
    SELECT MAX(p2.PrefixColumnCount)
    FROM #PrefixAnalysis p2
    WHERE p2.CandidateId = p.CandidateId
);
GO


/* ================================================================
   PART 13 — FINAL PREFLIGHT DECISION
================================================================ */

SELECT
    c.CandidateId,
    c.SchemaName,
    c.TableName,
    c.ProposedIndexName,
    c.KeyColumns,
    c.PriorityCode,

    CASE
        WHEN r.TableExists = 0
            THEN 'ERROR_TABLE_NOT_FOUND'

        WHEN EXISTS
        (
            SELECT 1
            FROM sys.indexes i
            WHERE i.object_id = r.ObjectId
              AND i.name = c.ProposedIndexName
        )
            THEN 'REVIEW_EXISTING_NAME'

        WHEN EXISTS
        (
            SELECT 1
            FROM #IndexComparison x
            WHERE x.CandidateId = c.CandidateId
              AND x.ExactKeyMatch = 1
        )
            THEN 'DO_NOT_CREATE_EXACT_KEY_MATCH'

        WHEN b.BestPrefixStatus = 'FULL_COVERAGE'
            THEN 'REVIEW_FULL_COVERAGE'

        WHEN b.BestPrefixStatus = 'PARTIAL_PREFIX'
            THEN 'CREATE_CANDIDATE_PARTIAL_SUPPORT'

        WHEN b.BestPrefixStatus = 'NO_PREFIX'
            THEN 'CREATE_CANDIDATE_NO_EXISTING_PREFIX'

        ELSE
            'CREATE_CANDIDATE'
    END AS PreflightDecision,

    ISNULL(b.BestExistingIndexName, '') AS BestExistingIndexName,
    ISNULL(b.BestPrefixStatus, 'NO_EXISTING_INDEX') AS ExistingCoverage,

    c.Reason

FROM #CandidateIndexes c
INNER JOIN #ResolvedCandidates r
    ON r.CandidateId = c.CandidateId

LEFT JOIN #BestCoverage b
    ON b.CandidateId = c.CandidateId

ORDER BY
    CASE c.PriorityCode
        WHEN 'HIGH' THEN 1
        WHEN 'MEDIUM' THEN 2
        ELSE 3
    END,
    c.CandidateId;
GO


/* ================================================================
   PART 14 — SUMMARY
================================================================ */

SELECT
    COUNT(*) AS TotalCandidates,

    SUM
    (
        CASE
            WHEN r.TableExists = 1 THEN 1
            ELSE 0
        END
    ) AS TablesFound,

    SUM
    (
        CASE
            WHEN r.TableExists = 0 THEN 1
            ELSE 0
        END
    ) AS TablesMissing,

    SUM
    (
        CASE
            WHEN EXISTS
            (
                SELECT 1
                FROM sys.indexes i
                WHERE i.object_id = r.ObjectId
                  AND i.name = c.ProposedIndexName
            )
            THEN 1
            ELSE 0
        END
    ) AS ExistingIndexNameConflicts,

    SUM
    (
        CASE
            WHEN EXISTS
            (
                SELECT 1
                FROM #IndexComparison x
                WHERE x.CandidateId = c.CandidateId
                  AND x.ExactKeyMatch = 1
            )
            THEN 1
            ELSE 0
        END
    ) AS ExactKeyMatches,

    SUM
    (
        CASE
            WHEN EXISTS
            (
                SELECT 1
                FROM #PrefixAnalysis p
                WHERE p.CandidateId = c.CandidateId
                  AND p.PrefixStatus = 'PARTIAL_PREFIX'
            )
            THEN 1
            ELSE 0
        END
    ) AS PartialPrefixCandidates

FROM #CandidateIndexes c
INNER JOIN #ResolvedCandidates r
    ON r.CandidateId = c.CandidateId;
GO


/* ================================================================
   PART 15 — HIGH PRIORITY SUMMARY
================================================================ */

SELECT
    c.CandidateId,
    c.SchemaName,
    c.TableName,
    c.ProposedIndexName,
    c.KeyColumns,
    c.PriorityCode,

    CASE
        WHEN EXISTS
        (
            SELECT 1
            FROM #IndexComparison x
            WHERE x.CandidateId = c.CandidateId
              AND x.ExactKeyMatch = 1
        )
        THEN 'EXACT_MATCH'

        WHEN b.BestPrefixStatus = 'FULL_COVERAGE'
        THEN 'FULL_COVERAGE'

        WHEN b.BestPrefixStatus = 'PARTIAL_PREFIX'
        THEN 'PARTIAL_SUPPORT'

        ELSE 'NOT_CURRENTLY_SUPPORTED'
    END AS CoverageStatus,

    b.BestExistingIndexName

FROM #CandidateIndexes c
LEFT JOIN #BestCoverage b
    ON b.CandidateId = c.CandidateId

WHERE c.PriorityCode = 'HIGH'

ORDER BY c.CandidateId;
GO


/* ================================================================
   PART 16 — MEDIUM PRIORITY SUMMARY
================================================================ */

SELECT
    c.CandidateId,
    c.SchemaName,
    c.TableName,
    c.ProposedIndexName,
    c.KeyColumns,
    c.PriorityCode,

    CASE
        WHEN EXISTS
        (
            SELECT 1
            FROM #IndexComparison x
            WHERE x.CandidateId = c.CandidateId
              AND x.ExactKeyMatch = 1
        )
        THEN 'EXACT_MATCH'

        WHEN b.BestPrefixStatus = 'FULL_COVERAGE'
        THEN 'FULL_COVERAGE'

        WHEN b.BestPrefixStatus = 'PARTIAL_PREFIX'
        THEN 'PARTIAL_SUPPORT'

        ELSE 'NOT_CURRENTLY_SUPPORTED'
    END AS CoverageStatus,

    b.BestExistingIndexName

FROM #CandidateIndexes c
LEFT JOIN #BestCoverage b
    ON b.CandidateId = c.CandidateId

WHERE c.PriorityCode = 'MEDIUM'

ORDER BY c.CandidateId;
GO


/* ================================================================
   PART 17 — FK / INTEGRITY WARNING

   This section identifies candidate indexes that should NOT
   automatically replace existing FK or integrity indexes.
================================================================ */

SELECT
    c.CandidateId,
    c.SchemaName,
    c.TableName,
    c.ProposedIndexName,
    c.KeyColumns,

    CASE
        WHEN EXISTS
        (
            SELECT 1
            FROM #ExistingIndexes e
            WHERE e.ObjectId = r.ObjectId
              AND e.IsPrimaryKey = 1
        )
        THEN 'PRIMARY_KEY_EXISTS'

        WHEN EXISTS
        (
            SELECT 1
            FROM #ExistingIndexes e
            WHERE e.ObjectId = r.ObjectId
              AND e.IsUniqueConstraint = 1
        )
        THEN 'UNIQUE_CONSTRAINT_EXISTS'

        ELSE 'NO_DIRECT_INTEGRITY_CONFLICT'
    END AS IntegrityStatus

FROM #CandidateIndexes c
INNER JOIN #ResolvedCandidates r
    ON r.CandidateId = c.CandidateId

WHERE r.TableExists = 1

ORDER BY c.CandidateId;
GO


/* ================================================================
   PART 18 — COMPLETION
================================================================ */

SELECT
    'PHASE 10.7-B' AS Phase,
    'INDEX CREATION PREFLIGHT' AS StepName,
    'COMPLETED — READ-ONLY PREFLIGHT ONLY' AS Status,
    'NO DATABASE CHANGES WERE MADE' AS SafetyStatus,
    GETDATE() AS CompletedAt;
GO