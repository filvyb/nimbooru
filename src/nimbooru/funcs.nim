import std/httpclient
import std/options
import std/asyncdispatch
import std/json

import containers
import utils

proc asyncGetUrl*(url: string): Future[string] {.async.} =
  var client = newAsyncHttpClient()
  try:
    result = await client.getContent(url)
  except CatchableError:
    raise newException(BooruError, "Failed fetching from the API")

proc prepareEndpoint*(client: BooruClient): string =
  if client.customApi.isSome:
    result &= client.customApi.get()
  else:
    result &= $client.site.get()
  
  result &= "index.php?page=dapi&q=index&json=1"
  if client.apiKey.isSome:
    result &= "&api_key=" & client.apiKey.get()
  if client.userdId.isSome:
    result &= "&user_id=" & client.userdId.get()

proc prepareGetPost*(client: BooruClient, id: string, url: string): string =
  result &= url
  result &= "&s=post"
  result &= "&id=" & id

proc processPost*(client: BooruClient, cont: string): JsonNode =
  var resp = parseJson(cont)

  if client.customApi.isNone:
    var b = client.site.get()
    case b:
      of Gelbooru:
        var count = resp["@attributes"]["count"].getInt()
        if count == 0:
          raise newException(BooruNotFoundError, "Post not found")
        return resp["post"].getElems()[0]
