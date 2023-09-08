import std/httpclient
import std/options
import std/asyncdispatch
import std/json
import std/strutils

import containers
import utils

proc asyncGetUrl*(client: BooruClient, url: string): Future[string] {.async.} =
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

proc formatTags(tags: Option[seq[string]], exclude_tags: Option[seq[string]]): seq[string] =
  if tags.isSome:
    for tag in tags.get():
      result &= tag.strip().toLower().replace(" ", "_")
  if exclude_tags.isSome:
    for tag in exclude_tags.get():
      result &= "-" & tag.strip().strip(chars = {'-'}).toLower().replace(" ", "_")

proc prepareGetPost*(client: BooruClient, id: string, url: string): string =
  if client.customApi.isNone:
    var b = client.site.get()
    case b:
      of Gelbooru, Safebooru:
        result &= url
        result &= "&s=post"
        result &= "&id=" & id

proc processPost*(client: BooruClient, cont: string): JsonNode =
  if cont.len == 0:
    raise newException(BooruNotFoundError, "Post not found")

  var resp = parseJson(cont)

  if client.customApi.isNone:
    var b = client.site.get()
    case b:
      of Gelbooru:
        var count = resp["@attributes"]["count"].getInt()
        if count == 0:
          raise newException(BooruNotFoundError, "Post not found")
        result = resp["post"].getElems()[0]
      of Safebooru:
        var elems = resp.getElems()
        if elems.len == 0:
          raise newException(BooruNotFoundError, "Post not found")
        result = elems[0]

proc prepareSearchPosts*(client: BooruClient, limit: int, page: int, tags: Option[seq[string]], exclude_tags: Option[seq[string]], url: string): string =
  let formatted_tags = formatTags(tags, exclude_tags)
  result &= url

  if client.customApi.isNone:
    var b = client.site.get()
    case b:
      of Gelbooru, Safebooru:
        result &= "&s=post"
        result &= "&limit=" & $limit
        result &= "&pid=" & $page
        if formatted_tags.len > 0:
          result &= "&tags=" & formatted_tags.join(" ")

proc processSearchPosts*(client: BooruClient, cont: string): seq[BooruImage] =
  var resp = parseJson(cont)

  if client.customApi.isNone:
    var b = client.site.get()
    case b:
      of Gelbooru:
        var count = resp["@attributes"]["count"].getInt()
        if count == 0:
          raise newException(BooruNotFoundError, "No posts not found")
        for p in resp["post"].getElems():
          result &= initBooruImage(client, p)
      of Safebooru:
        var elems = resp.getElems()
        if elems.len == 0:
          raise newException(BooruNotFoundError, "Post not found")
        for p in elems:
          result &= initBooruImage(client, p)
