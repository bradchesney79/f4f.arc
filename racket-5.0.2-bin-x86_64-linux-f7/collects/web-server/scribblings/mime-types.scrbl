#lang scribble/doc
@(require "web-server.rkt")

@title[#:tag "mime-types"]{MIME Types}
@(require (for-label web-server/private/mime-types))

@defmodule[web-server/private/mime-types]{

This module provides function for dealing with @filepath{mime.types}
files.

@defproc[(read-mime-types [p path-string?])
         (hash-table/c symbol? bytes?)]{
 Reads the @filepath{mime.types} file from @racket[p] and constructs a
 hash table mapping extensions to MIME types.
}

@defproc[(make-path->mime-type [p path-string?])
         (path? . -> . bytes?)]{
 Uses a @racket[read-mime-types] with @racket[p] and constructs a
 function from paths to their MIME type.
}

}
