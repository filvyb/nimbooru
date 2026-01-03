import std/httpclient
import std/options
import std/asyncdispatch
import std/json
import std/strutils

import containers
import utils

proc extractBetween(text: string, tbegin: string, tend: string, pos = 0): string =
  ## Extracts text between two delimiters.
  ## Returns empty string if delimiters are not found.
  try:
    var start_pos = text.find(tbegin, pos) + tbegin.len
    var end_pos = text.find(tend, start_pos)
    result = text[start_pos ..< end_pos]
  except:
    result = ""

const DefaultTimeout* = 30000 ## Default HTTP timeout in milliseconds (30 seconds)

proc syncGetUrl*(client: BooruClient, url: string, timeout = DefaultTimeout): string =
  ## Fetches content from a URL synchronously.
  ## Raises BooruError if the request fails or times out.
  var wclient = newHttpClient(timeout = timeout)
  defer: wclient.close()
  try:
    result = wclient.getContent(url)
  except CatchableError as e:
    raise newException(BooruError, "Failed fetching from the API: " & e.msg)

proc asyncGetUrl*(client: BooruClient, url: string, timeout = DefaultTimeout): Future[string] {.async.} =
  ## Fetches content from a URL asynchronously.
  ## Raises BooruError if the request fails or times out.
  var wclient = newAsyncHttpClient()
  defer: wclient.close()
  try:
    result = await wclient.getContent(url)
  except CatchableError as e:
    raise newException(BooruError, "Failed fetching from the API: " & e.msg)

proc prepareEndpoint*(client: BooruClient): string =
  ## Constructs the base API endpoint URL for the given client.
  ## Uses customApi if provided, otherwise uses the default endpoint for the site.
  if client.site.isNone:
    raise newException(BooruError, "BooruClient must have a site set")

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
      if client.userId.isSome:
        result &= "&user_id=" & client.userId.get()
    of Danbooru, E621:
      if client.userId.isSome:
        result &= "?login=" & client.userId.get()
      if client.apiKey.isSome:
        result &= "&api_key=" & client.apiKey.get()
    else:
      return

proc formatTags(tags: Option[seq[string]], exclude_tags: Option[seq[string]]): seq[string] =
  ## Normalizes tags for API queries: lowercases, replaces spaces with underscores,
  ## and prefixes excluded tags with '-'.
  if tags.isSome:
    for tag in tags.get():
      result &= tag.strip().toLower().replace(" ", "_")
  if exclude_tags.isSome:
    for tag in exclude_tags.get():
      result &= "-" & tag.strip().strip(chars = {'-'}).toLower().replace(" ", "_")

proc prepareGetPost*(client: BooruClient, id: string, url: string): string =
  ## Builds the URL for fetching a single post by ID.
  result &= url

  var b = client.site.get()
  case b:
    of Gelbooru, Safebooru:
      result &= "&s=post"
      result &= "&id=" & id
    of Danbooru, E621:
      result &= "posts/" & id & ".json"
    of Yandere, Konachan:
      result &= "post/show/" & id

proc processPost*(client: BooruClient, cont: string): JsonNode =
  ## Parses a single post response from the API.
  ## Raises BooruNotFoundError if the post doesn't exist.
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
    of Yandere, Konachan:
      # why isn't there an API endpoint?
      var raw = cont.extractBetween("Post.register_resp(", "); </script>")
      if raw == "":
        raise newException(BooruNotFoundError, "Post not found")
      result = parseJson(raw)["posts"].getElems()[0]
    of E621:
      var resp = parseJson(cont)
      if resp.hasKey("success"):
        if not resp["success"].getBool():
          raise newException(BooruNotFoundError, "Post not found")
      result = resp["post"]

proc prepareSearchPosts*(client: BooruClient, limit: int, page: int, tags: Option[seq[string]], exclude_tags: Option[seq[string]], url: string): string =
  ## Builds the URL for searching posts with pagination and tag filters.
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
    of Danbooru, E621:
      result &= "posts.json"
      result &= "?limit=" & $limit
      result &= "&page=" & $page
      if formatted_tags.len > 0:
        result &= "&tags=" & formatted_tags.join(" ")
    of Yandere, Konachan:
      result &= "post.json"
      result &= "?limit=" & $limit
      result &= "&page=" & $page
      if formatted_tags.len > 0:
        result &= "&tags=" & formatted_tags.join(" ")

proc processSearchPosts*(client: BooruClient, cont: string): seq[BooruImage] =
  ## Parses search results and returns a sequence of BooruImage objects.
  ## Raises BooruNotFoundError if no posts match the search.
  var resp = parseJson(cont)

  var b = client.site.get()
  case b:
    of Gelbooru:
      var count = resp["@attributes"]["count"].getInt()
      if count == 0:
        raise newException(BooruNotFoundError, "No posts found")
      for p in resp["post"].getElems():
        result &= initBooruImage(client, p)
    of Safebooru, Danbooru, Yandere, Konachan:
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
    of E621:
      var elems = resp["posts"].getElems()
      if elems.len == 0:
        raise newException(BooruNotFoundError, "Post not found")
      for p in elems:
        result &= initBooruImage(client, p)
