type
  BooruError* = object of CatchableError
  BooruNotFoundError* = object of BooruError

type
  Boorus* = enum
    Gelbooru = "https://gelbooru.com/"
