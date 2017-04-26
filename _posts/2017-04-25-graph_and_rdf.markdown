---
layout: post
title:  "Design Considerations: The Merge of RDF and CDMI Metadata"
date:   2017-04-25 10:13:56 -0400
categories: development update
---
As discussed in my last post, we are implementing Graph-based metadata for DRAS-TIC. We also have a mind to eventually support the Fedora API specifications in addition to CDMI's API. This means that two different standards for user metadata are in play. CDMI's metadata specification is pretty basic. Field values are restricted to UTF-8 strings and the name of a user metadata key cannot start with "cdmi_". In contrast the Fedora user metadata comes in the form of RDF statements. A string would be encoded as a string literal value, which may include a language component. RDF also supports other XSD datatypes and links to other URI resources. The question is how to interpolate between these two different standards and how to store both in our graph database. The implementation should support our platform goals.

## Goals

* Provide at least basic CRUD Fedora API, including LDP state representations, containers, and non-state representations (binaries). [LDP Resources](https://www.w3.org/TR/ldp/#fig-ldpr-class)

* Make all folders, files, and resource objects accessible through both APIs in a useful way.

* Enable straightforward Graph traversals of CDMI and Fedora ingested content that are as lexically simple as possible (but no simpler).

* If content is created via the Fedora API, but then backed up and restored via the CDMI API, then it should remain identical in terms of user metadata representation.

* Fedora implementers are used to providing SPARQL query services via a separate triple-store service. The availability of this Graph may not change that need, as there is currently no query translator that makes a Gremlin language query from arbitrary SPARQL. That eventuality is not a design constraint. The Graph schema may be more DRAS-TIC specific than would allow such approaches.

## Literals
A Fedora API implementation will need to support the full range of RDF literal values, including integers, bytes; about 40 basic data types. These are passed in RDF statements with a special syntax:

    "15"^^xsd:byte
    "15.0"^^xsd:decimal

This metadata can be served up via CDMI as UTF-8 strings by including the same encoding syntax as the RDF snippets above with quotes and datatype annotations. Plain strings can be a special case, as they already are in RDF, such that CDMI users are still free to ignore data types if they choose and input plain strings, with or without quotes. This means that CDMI users can completely ignore the RDF semantics if they so desire.

### Literals in the Graph Database
Let's take the example of an RDF literal decimal value, the dc:extent of a Fedora object. Fedora expresses this metadata this way:

    PREFIX dcterms: <http://purl.org/dc/terms/>
    PREFIX pid: <https://umd-drastic.github.io/drastic-identifiers/>
    <> dcterms:extent "10"^^xsd:decimal

With the Graph we are limited somewhat by the need to type the properties in advance, as a part of the graph schema. Luckily, the Graph also permits properties to have properties. So we can pack data-typed details alongside of simple string values. The Graph might express the metadata as this property:

<!-- language: lang-js -->
    {
      "extent": {
        "value": "10",
        "decimal": 10,
        "rdf_type": "xsd:decimal",
        "rdf_namespace": "http://purl.org/dc/terms/"
        }
      }

This form of graph property should be useful in a lexically simple way in a graph traversal, by addressing the simple "extent" key and either consuming the plain string value or the decimal value as appropriate.

To ensure the round-trip requirement, the CDMI form of this property would have to be more explicit:

<!-- language: lang-js -->
    {
      "<http://purl.org/dc/terms/extent>": "\"10\"^^xsd:decimal"
    }

The problem I have this with last CDMI form is that it doesn't tell the user what the simple key is for use in graph traversal. Indeed it is not clear how DRAS-TIC would separate the namespace part from the local name part upon CDMI ingest, at least without a persistent, central registry of namespaces. I suppose in the case of a CDMI-based recovery, the full key can also be used upon CDMI ingest, with any unanticipated namespaces being teased out in subsequent processing. In RDF terms, the metadata is complete either way.

## Linked Resources
The other form of RDF statement is a predicate that defines a relationship with another resource, referenced by URI. In CDMI there is a notion of a reference link, but it provides more the function of a symbolic link in a filesystem, a shortcut to another file or folder. The RDF form of a link to another resource is as follows:

    PREFIX dcterms: <http://purl.org/dc/terms/>
    <> <dcterms:isReplacedBy> <http://example.com/foo.txt>

The Vertex <pid:xyz> is either in the Graph already or not. If it exists independent from the assertion above, then we want to let it continue to exist if we delete this resource. In other words, for the purpose of persistence, this statement is part of the local graph associated with this resource. I think the way to express these relationships in Graph terms is to use a Vertex and an Edge. However, we'll need some additional annotation to ensure that we can remove or update these parts of the Graph whenever the "host resource" is removed or updated. We might put this statement in the Graph this way:

<!-- language: lang-js -->
    {
      "graph": {
        "mode": "NORMAL",
        "vertices": [
          {
            "_label": "file",
            "name": {
              "value": "file1.pdf",
              "rdf_namespace": "http://drastic.org/terms/"
            },
            "_id": "1",
            "_type": "vertex"
          },
          {
            "_label": "implied_resource",
            "uri": "http://example.com/foo.txt",
            "_id": "2",
            "_type": "vertex"
          }
        ],
        "edges": [
          {
            "_label": "isReplacedBy",
            "rdf_namespace": "http://purl.org/dc/terms/",
            "asserted_by": "1",
            "_id": "3",
            "_type": "edge",
            "_outV": "1",
            "_inV": "2"
          }
        ]
      }
    }

The GraphSON format here becomes more verbose than before, as I am showing JSON context for the vertices and edges. The Graph label of a vertex as "implied_resource" should allow for deletion when the last incoming edges are deleted. These incoming edges would be cleaned up as their "asserted_by" vertex is destroyed. Note that asserted_by in Fedora terms is always the same as the outV and we may not need it. However, we don't want to preclude the existence of other Edges in our graph that might be asserted in other ways, i.e. by later analytics.

In CDMI input and output I think this edge would resemble the RDF, such that it would look like this:

<!-- language: lang-js -->
    {
      "<http://purl.org/dc/terms/isReplacedBy>": "<http://example.com/foo.txt>"
    }

This makes the round trip possible for CDMI-base export and import. It will look the same whether or not the linked resource is another DRAS-TIC file or not.

## Feedback Welcome
I have worked with many people over the years who know more about these subjects than I do. Hopefully I can get some of them to provide feedback on this post. If you see this, please feel free to send tweet at/to @DRASTIC_Repo with your thoughts or email me at jansen at umd dot edu.
