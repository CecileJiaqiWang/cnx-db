CREATE OR REPLACE FUNCTION public.subcol_uuids(uuid uuid, version text) RETURNS VOID
 LANGUAGE sql
AS $function$
WITH RECURSIVE t(node, title, path, documentid, parent, depth, corder, is_collated) AS (
    SELECT nodeid, title, ARRAY[nodeid], documentid, NULL::integer, 1, ARRAY[childorder],
           is_collated
    FROM trees tr, modules m
    WHERE m.uuid = $1 AND
          module_version( m.major_version, m.minor_version) = $2 AND
      tr.documentid = m.module_ident AND
      tr.parent_id IS NULL AND
      tr.is_collated = False
UNION ALL
    SELECT c1.nodeid, c1.title, t.path || ARRAY[c1.nodeid], c1.documentid, t.documentid, t.depth+1, t.corder || ARRAY[c1.childorder], c1.is_collated /* Recursion */
    FROM trees c1 JOIN t ON (c1.parent_id = t.node)
    WHERE not nodeid = any (t.path) AND t.is_collated = c1.is_collated
)
INSERT INTO document_controls (uuid)

SELECT
    uuid5(m.uuid::uuid, t.title)
    FROM t JOIN modules m on m.module_ident = t.parent WHERE t.documentid IS NULL and not exists (select 1 from document_controls where
        uuid = uuid5(m.uuid::uuid, t.title));

WITH RECURSIVE t(node, title, path, documentid, parent, depth, corder, is_collated) AS (
    SELECT nodeid, title, ARRAY[nodeid], documentid, NULL::integer, 1, ARRAY[childorder],
           is_collated
    FROM trees tr, modules m
    WHERE m.uuid = $1 AND
          module_version( m.major_version, m.minor_version) = $2 AND
      tr.documentid = m.module_ident AND
      tr.parent_id IS NULL AND
      tr.is_collated = False
UNION ALL
    SELECT c1.nodeid, c1.title, t.path || ARRAY[c1.nodeid], c1.documentid, t.documentid, t.depth+1, t.corder || ARRAY[c1.childorder], c1.is_collated /* Recursion */
    FROM trees c1 JOIN t ON (c1.parent_id = t.node)
    WHERE not nodeid = any (t.path) AND t.is_collated = c1.is_collated
)
INSERT INTO modules (
    doctype,
    portal_type,
    moduleid,
    uuid,
    version,
    name,
    created,
    revised,
    licenseid,
    submitter,
    submitlog,
    stateid,
    parent,
    language,
    authors,
    maintainers,
    licensors,
    parentauthors,
    google_analytics,
    buylink,
    major_version,
    minor_version,
    print_style)

SELECT
    t.node,
    'SubCollection',
    'col' || nextval('collectionid_seq'),
    uuid5(m.uuid::uuid, t.title),
    m.version,
    t.title,
    m.created,
    m.revised,
    m.licenseid,
    m.submitter,
    m.submitlog,
    m.stateid,
    m.parent,
    m.language,
    m.authors,
    m.maintainers,
    m.licensors,
    m.parentauthors,
    m.google_analytics,
    m.buylink,
    m.major_version,
    m.minor_version,
    m.print_style

FROM t join modules m on m.module_ident = t.parent WHERE t.documentid IS NULL
    and not exists (select 1 from modules where uuid = uuid5(m.uuid::uuid, t.title) and module_version(major_version, minor_version) = $2);

WITH RECURSIVE t(node, title, path, documentid, parent, depth, corder, is_collated) AS (
    SELECT nodeid, title, ARRAY[nodeid], documentid, NULL::integer, 1, ARRAY[childorder],
           is_collated
    FROM trees tr, modules m
    WHERE m.uuid = $1 AND
          module_version( m.major_version, m.minor_version) = $2 AND
      tr.documentid = m.module_ident AND
      tr.parent_id IS NULL AND
      tr.is_collated = False
UNION ALL
    SELECT c1.nodeid, c1.title, t.path || ARRAY[c1.nodeid], c1.documentid, t.documentid, t.depth+1, t.corder || ARRAY[c1.childorder], c1.is_collated /* Recursion */
    FROM trees c1 JOIN t ON (c1.parent_id = t.node)
    WHERE not nodeid = any (t.path) AND t.is_collated = c1.is_collated
)
UPDATE trees
    set documentid = module_ident 
    FROM t, modules m WHERE nodeid = t.node AND t.documentid IS NULL and nodeid::text = m.doctype;

$function$

