import std/options

type
  Booru = object
    apiKey: Option[string]
    userdId: Option[string]
