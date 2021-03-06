#lang scribble/doc
@(require "mz.ss")

@title[#:style 'toc]{Macros}

See @secref["syntax-model"] for general information on how programs
are parsed. In particular, the subsection @secref["expand-steps"]
describes how parsing triggers macros, and
@secref["transformer-model"] describes how macro transformers are
called.

@local-table-of-contents[]

@include-section["stx-patterns.scrbl"]
@include-section["stx-ops.scrbl"]
@include-section["stx-comp.scrbl"]
@include-section["stx-trans.scrbl"]
@include-section["stx-param.scrbl"]
@include-section["splicing.scrbl"]
@include-section["stx-props.scrbl"]
@include-section["stx-certs.scrbl"]
@include-section["stx-expand.scrbl"]
@include-section["include.scrbl"]
