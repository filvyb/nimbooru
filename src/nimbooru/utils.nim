type
  BooruError* = object of CatchableError
  BooruNotFoundError* = object of BooruError

type
  Boorus* {.pure.} = enum
    Gelbooru = "https://gelbooru.com/"
    Safebooru = "https://safebooru.org/"
    Danbooru = "https://danbooru.donmai.us/"
    Yandare = "https://yande.re/"
    Konachan = "https://konachan.com/"
    E621 = "https://e621.net/"
