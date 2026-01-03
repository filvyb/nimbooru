type
  BooruError* = object of CatchableError
  BooruNotFoundError* = object of BooruError

type
  Boorus* {.pure.} = enum
    Gelbooru = "https://gelbooru.com/"
    Safebooru = "https://safebooru.org/"
    Danbooru = "https://danbooru.donmai.us/"
    Yandere = "https://yande.re/"
    Konachan = "https://konachan.com/"
    E621 = "https://e621.net/"
    Sankaku = "https://sankakuapi.com/"
    IdolComplex = "https://i.sankakuapi.com/"
    Zerochan = "https://www.zerochan.net/"
