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
  except CatchableError as e:
    raise newException(BooruError, "Failed fetching from the API: " & e.msg)

proc prepareEndpoint*(client: BooruClient): string =
  if client.customApi.isSome:
    result &= client.customApi.get()
  else:
    result &= $client.site.get()
  
  var b = client.site.get()
  case b:
    of Gelbooru, Safebooru:  
      result &= "index.php?page=dapi&q=index&json=1"
      if client.apiKey.isSome:
        result &= "&api_key=" & client.apiKey.get()
      if client.userdId.isSome:
        result &= "&user_id=" & client.userdId.get()
    else:
      return

proc formatTags(tags: Option[seq[string]], exclude_tags: Option[seq[string]]): seq[string] =
  if tags.isSome:
    for tag in tags.get():
      result &= tag.strip().toLower().replace(" ", "_")
  if exclude_tags.isSome:
    for tag in exclude_tags.get():
      result &= "-" & tag.strip().strip(chars = {'-'}).toLower().replace(" ", "_")

proc prepareGetPost*(client: BooruClient, id: string, url: string): string =
  result &= url

  var b = client.site.get()
  case b:
    of Gelbooru, Safebooru:
      result &= "&s=post"
      result &= "&id=" & id
    of Danbooru:
      result &= "posts/" & id & ".json"
    of Yandare, Konachan:
      result &= "post/show/" & id

proc processPost*(client: BooruClient, cont: string): JsonNode =
  if cont.len == 0:
    raise newException(BooruNotFoundError, "Post not found")

  var b = client.site.get()
  case b:
    of Gelbooru:
      var resp = parseJson(cont)
      var count = resp["@attributes"]["count"].getInt()
      if count == 0:
        raise newException(BooruNotFoundError, "Post not found")
      result = resp["post"].getElems()[0]
    of Safebooru:
      var resp = parseJson(cont)
      var elems = resp.getElems()
      if elems.len == 0:
        raise newException(BooruNotFoundError, "Post not found")
      result = elems[0]
    of Danbooru:
      var resp = parseJson(cont)
      if resp.hasKey("success"):
        if not resp["success"].getBool():
          raise newException(BooruNotFoundError, "Post not found")
      result = resp
    of Yandare, Konachan:
      # why isn't there an API endpoint?
      var start_pos = cont.find("Post.register_resp")
      if start_pos == -1:
        raise newException(BooruNotFoundError, "Post not found")
      var end_pos = cont.find("</script>", start_pos)
      var resp = cont[start_pos + 19 ..< end_pos - 3].parseJson()
      result = resp["posts"].getElems()[0]

proc prepareSearchPosts*(client: BooruClient, limit: int, page: int, tags: Option[seq[string]], exclude_tags: Option[seq[string]], url: string): string =
  let formatted_tags = formatTags(tags, exclude_tags)
  result &= url

  var b = client.site.get()
  case b:
    of Gelbooru, Safebooru:
      result &= "&s=post"
      result &= "&limit=" & $limit
      result &= "&pid=" & $page
      if formatted_tags.len > 0:
        result &= "&tags=" & formatted_tags.join(" ")
    of Danbooru:
      result &= "posts.json"
      result &= "?limit=" & $limit
      result &= "?page=" & $page
      if formatted_tags.len > 0:
        result &= "?tags=" & formatted_tags.join(" ")
    of Yandare, Konachan:
      result &= "post.json"
      result &= "?limit=" & $limit
      result &= "?page=" & $page
      if formatted_tags.len > 0:
        result &= "?tags=" & formatted_tags.join(" ")

proc processSearchPosts*(client: BooruClient, cont: string): seq[BooruImage] =
  var resp = parseJson(cont)

  var b = client.site.get()
  case b:
    of Gelbooru:
      var count = resp["@attributes"]["count"].getInt()
      if count == 0:
        raise newException(BooruNotFoundError, "No posts not found")
      for p in resp["post"].getElems():
        result &= initBooruImage(client, p)
    of Safebooru, Danbooru, Yandare, Konachan:
      var elems = resp.getElems()
      if elems.len == 0:
        # Danbooru, Yandare, Konachan
        if resp.hasKey("success"):
          if not resp["success"].getBool():
            raise newException(BooruError, "Search limit hit or post not found")
        # Safebooru
        raise newException(BooruNotFoundError, "Post not found")
      for p in elems:
        result &= initBooruImage(client, p)
