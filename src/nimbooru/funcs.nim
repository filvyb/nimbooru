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

proc syncGetUrl*(client: BooruClient, url: string): string =
  ## Fetches content from a URL synchronously.
  var wclient = newHttpClient(timeout = client.timeout)
  defer: wclient.close()
  wclient.headers = newHttpHeaders({"User-Agent": client.userAgent})
  case client.site.get():
    of Sankaku:
      wclient.headers["Accept"] = "application/vnd.sankaku.api+json;v=2"
      wclient.headers["Origin"] = "https://sankaku.app"
    of IdolComplex:
      wclient.headers["Accept"] = "application/vnd.sankaku.api+json;v=2"
      wclient.headers["Origin"] = "https://www.idolcomplex.com"
    of Rule34Paheal:
      wclient.headers["Cookie"] = "ui-tnc-agreed=true"
    of Zerochan, Gelbooru, Safebooru, Danbooru, Yandere, Konachan, E621:
      discard
  try:
    result = wclient.getContent(url)
  except CatchableError as e:
    raise newException(BooruError, "Failed fetching from the API: " & e.msg)

proc asyncGetUrl*(client: BooruClient, url: string): Future[string] {.async.} =
  ## Fetches content from a URL asynchronously.
  var wclient = newAsyncHttpClient()
  defer: wclient.close()
  wclient.headers = newHttpHeaders({"User-Agent": client.userAgent})
  case client.site.get():
    of Sankaku:
      wclient.headers["Accept"] = "application/vnd.sankaku.api+json;v=2"
      wclient.headers["Origin"] = "https://sankaku.app"
    of IdolComplex:
      wclient.headers["Accept"] = "application/vnd.sankaku.api+json;v=2"
      wclient.headers["Origin"] = "https://www.idolcomplex.com"
    of Rule34Paheal:
      wclient.headers["Cookie"] = "ui-tnc-agreed=true"
    of Zerochan, Gelbooru, Safebooru, Danbooru, Yandere, Konachan, E621:
      discard
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
    of Yandere, Konachan, Sankaku, IdolComplex, Zerochan, Rule34Paheal:
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
    of Sankaku, IdolComplex:
      let prefix = if id.len == 32: "md5:" else: "id_range:"
      result &= "v2/posts?lang=en&page=1&limit=1&tags=" & prefix & id
    of Zerochan:
      result &= id & "?json"
    of Rule34Paheal:
      result &= "post/view/" & id

proc processPost*(client: BooruClient, cont: string): JsonNode =
  ## Parses a single post response from the API.
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
    of Sankaku, IdolComplex:
      var resp = parseJson(cont)
      var elems = resp.getElems()
      if elems.len == 0:
        raise newException(BooruNotFoundError, "Post not found")
      result = elems[0]
    of Zerochan:
      var resp = parseJson(cont)
      if not resp.hasKey("id"):
        raise newException(BooruNotFoundError, "Post not found")
      result = resp
    of Rule34Paheal:
      if "id='main_image'" notin cont and "<source src='" notin cont:
        raise newException(BooruNotFoundError, "Post not found")
      # Extract file URL
      var fileUrl = extractBetween(cont, "id='main_image' src='", "'")
      if fileUrl == "":
        fileUrl = extractBetween(cont, "<source src='", "'")
      # Extract md5 from file URL or thumbnail
      var md5 = ""
      let thumbMd5 = extractBetween(cont, "/_thumbs/", "/")
      if thumbMd5 != "":
        md5 = thumbMd5
      # Extract dimensions from Info section
      let info = extractBetween(cont, "Info</th><td>", "</td>")
      let infoParts = info.split(" // ")
      var width = 0
      var height = 0
      var ext = ""
      if infoParts.len >= 3:
        let dimensions = infoParts[0]
        ext = infoParts[2]
        let dimParts = dimensions.split("x")
        if dimParts.len >= 2:
          try:
            width = parseInt(dimParts[0])
            height = parseInt(dimParts[1].split(",")[0])
          except:
            discard
      # Extract tags from tag links
      var tags: seq[string]
      var tagPos = cont.find("data-row='Tags'")
      if tagPos != -1:
        let tagSection = cont[tagPos ..< min(tagPos + 2000, cont.len)]
        var pos = 0
        while true:
          let tagStart = tagSection.find("class='tag' title='View all posts tagged ", pos)
          if tagStart == -1:
            break
          let tagEnd = tagSection.find("'", tagStart + 41)
          if tagEnd == -1:
            break
          tags.add(tagSection[tagStart + 41 ..< tagEnd])
          pos = tagEnd
      # Extract locked status
      let lockedText = extractBetween(cont, "Locked</th><td>", "</td>")
      let locked = lockedText.startsWith("Yes")
      # Check for comments (actual comments have id="c" followed by digits)
      let hasComments = cont.find("<div class=\"comment \" id=\"c") != -1
      result = %* {
        "id": extractBetween(cont, "name='image_id' value='", "'"),
        "md5": md5,
        "file_url": fileUrl,
        "width": width,
        "height": height,
        "tags": tags.join(" "),
        "extension": ext,
        "locked": locked,
        "has_comments": hasComments
      }

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
    of Sankaku, IdolComplex:
      result &= "v2/posts"
      result &= "?lang=en"
      result &= "&limit=" & $limit
      result &= "&page=" & $page
      if formatted_tags.len > 0:
        result &= "&tags=" & formatted_tags.join(" ")
    of Zerochan:
      if tags.isSome and tags.get().len > 0:
        var zerochanTags: seq[string]
        for tag in tags.get():
          zerochanTags &= tag.strip().replace(" ", "+")
        result &= zerochanTags.join(",").replace("_", "+")
      result &= "?json"
      result &= "&l=" & $limit
      result &= "&p=" & $page
    of Rule34Paheal:
      result &= "post/list"
      if formatted_tags.len > 0:
        result &= "/" & formatted_tags.join("%20")
      result &= "/" & $(page + 1)

proc parseRule34PostIds*(cont: string): seq[string] =
  ## Extracts post IDs from Rule34 HTML search results.
  let listPos = cont.find("id='image-list'")
  if listPos == -1:
    raise newException(BooruNotFoundError, "No posts found")

  var pos = listPos
  while true:
    let thumbStart = cont.find("<img id='thumb_", pos)
    if thumbStart == -1:
      break
    let thumbEnd = cont.find("'", thumbStart + 15)
    if thumbEnd == -1:
      break

    let pid = cont[thumbStart + 15 ..< thumbEnd]
    # Skip random post widget (has "rand_" prefix)
    if pid != "" and not pid.startsWith("rand_"):
      result.add(pid)
    pos = thumbEnd

proc processSearchPosts*(client: BooruClient, cont: string): seq[BooruImage] =
  ## Parses search results and returns a sequence of BooruImage objects.
  var b = client.site.get()
  var resp = parseJson(cont)
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
    of Sankaku, IdolComplex:
      var elems = resp.getElems()
      if elems.len == 0:
        raise newException(BooruNotFoundError, "Post not found")
      for p in elems:
        result &= initBooruImage(client, p)
    of Zerochan:
      if not resp.hasKey("items"):
        raise newException(BooruNotFoundError, "Post not found")
      var elems = resp["items"].getElems()
      if elems.len == 0:
        raise newException(BooruNotFoundError, "Post not found")
      for p in elems:
        result &= initBooruImage(client, p)
    of Rule34Paheal:
      discard  # Handled in main.nim via parseRule34PostIds
