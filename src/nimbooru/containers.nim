import std/times
import std/options
import std/json
import std/strutils

import utils


type
  BooruClient* = object
    ## Client configuration for connecting to a booru API.
    ## Use initBooruClient() to create instances.
    apiKey*: Option[string]      ## API key for authenticated requests
    userId*: Option[string]      ## User ID for authenticated requests
    site*: Option[Boorus]        ## The booru site to query
    customApi*: Option[string]   ## Custom API endpoint URL (overrides default)

  BooruImage* = object
    ## Represents a single image post from a booru.
    id*: string
    creator_id*: Option[string]
    parent_id*: string
    created_at*: Option[DateTime]
    file_url*: string
    preview_url*: string
    directory*: string
    filename*: string
    source*: Option[string]
    hash*: string
    height*: int
    width*: int
    rating*: string
    #has_sample*: bool
    has_comments*: bool
    has_notes*: bool
    has_children*: bool
    tags*: seq[string]
    change*: Time
    status*: string
    locked*: bool
    score*: int
    #raw*: JsonNode

proc initBooruImage*(client: BooruClient, img: JsonNode): BooruImage =
  ## Constructs a BooruImage from raw JSON response data.
  ## Handles site-specific JSON formats for each supported booru.
  if client.customApi.isNone:
    var b = client.site.get()
    case b:
      of Gelbooru:
        result.id = $img["id"].getInt()
        if img.hasKey("creator_id"):
          result.creator_id = some $img["creator_id"].getInt()
        result.parent_id = $img["parent_id"].getInt()
        if img.hasKey("created_at"):
          result.created_at = some parse(img["created_at"].getStr(), "ddd MMM dd HH:mm:ss ZZZ YYYY")
        result.file_url = img["file_url"].getStr()
        result.preview_url = img["preview_url"].getStr()
        result.directory = img["directory"].getStr()
        result.filename = img["image"].getStr()
        if img.hasKey("source"):
          result.source = some img["source"].getStr()
        result.hash = img["md5"].getStr()
        result.height = img["height"].getInt()
        result.width = img["width"].getInt()
        result.rating = img["rating"].getStr()
        result.has_comments = img["has_comments"].getBool(false)
        result.has_notes = img["has_notes"].getBool(false)
        result.has_children = img["has_children"].getBool(false)
        result.tags = img["tags"].getStr().split(" ")
        result.change = img["change"].getInt().fromUnix()
        result.status = img["status"].getStr()
        result.locked = img["post_locked"].getBool()
        result.score = img["score"].getInt()
      of Safebooru:
        result.id = $img["id"].getInt()
        if img.hasKey("owner"):
          result.creator_id = some $img["owner"].getStr()
        result.parent_id = $img["parent_id"].getInt()
        if img.hasKey("source"):
          result.source = some img["source"].getStr()
        result.height = img["height"].getInt()
        result.width = img["width"].getInt()
        result.hash = img["hash"].getStr()
        result.directory = img["directory"].getStr()
        result.filename = img["image"].getStr()
        result.file_url = $b & "images/" & result.directory & "/" & result.filename
        result.preview_url = $b & "thumbnails/" & result.directory & "/thumbnail_" & result.filename.split('.')[0] & ".jpg"
        result.rating = img["rating"].getStr()
        result.tags = img["tags"].getStr().split(" ")
        result.score = img["score"].getInt()
        result.change = img["change"].getInt().fromUnix()
      of Danbooru:
        result.id = $img["id"].getInt()
        if img.hasKey("uploader_id"):
          result.creator_id = some $img["uploader_id"].getInt()
        result.parent_id = $img["parent_id"].getInt(0)
        if img.hasKey("created_at"):
          result.created_at = some parse(img["created_at"].getStr(), "YYYY-MM-dd'T'HH:mm:ss'.'fffzzz")
        if img.hasKey("file_url"):
          result.file_url = img["file_url"].getStr()
          result.filename = result.file_url.rsplit({'/'}, maxsplit=1)[1]
        if img.hasKey("preview_file_url"):
          result.preview_url = img["preview_file_url"].getStr()
        if img.hasKey("source"):
          result.source = some img["source"].getStr()
        if img.hasKey("md5"):          
          result.hash = img["md5"].getStr()
        result.height = img["image_height"].getInt()
        result.width = img["image_width"].getInt()
        result.rating = img["rating"].getStr()
        if img["last_commented_at"].getStr("") != "":
          result.has_comments = true
        else:
          result.has_comments = false
        if img["last_noted_at"].getStr("") != "":
          result.has_notes = true
        else:
          result.has_notes = false
        result.has_children = img["has_children"].getBool(false)
        result.tags = img["tag_string"].getStr().split(" ")
        result.change = parseTime(img["updated_at"].getStr(), "YYYY-MM-dd'T'HH:mm:ss'.'fffzzz", utc())
        result.status = img["media_asset"]["status"].getStr()
        result.locked = img["is_banned"].getBool()
        result.score = img["score"].getInt()
      of Yandere, Konachan:
        result.id = $img["id"].getInt()
        if img.hasKey("creator_id"):
          result.creator_id = some $img["creator_id"].getInt()
        result.parent_id = $img["parent_id"].getInt(0)
        result.created_at = some parse($img["created_at"].getInt().fromUnix(), "yyyy-MM-dd'T'HH:mm:sszzz")
        if img.hasKey("updated_at"):
          result.change = img["updated_at"].getInt().fromUnix()
        if img.hasKey("source"):
          result.source = some img["source"].getStr()
        result.score = img["score"].getInt()
        result.hash = img["md5"].getStr()
        result.file_url = img["file_url"].getStr()
        result.preview_url = img["preview_url"].getStr()
        result.filename = result.file_url.rsplit({'/'}, maxsplit=1)[1]
        result.height = img["height"].getInt()
        result.width = img["width"].getInt()
        result.rating = img["rating"].getStr()
        result.has_children = img["has_children"].getBool(false)
        result.tags = img["tags"].getStr().split(" ")
        result.status = img["status"].getStr()
        result.locked = img["is_held"].getBool()
      of E621:
        result.id = $img["id"].getInt()
        if img.hasKey("uploader_id"):
          result.creator_id = some $img["uploader_id"].getInt()
        result.parent_id = $img["relationships"]["parent_id"].getInt(0)
        result.created_at = some parse(img["created_at"].getStr(), "yyyy-MM-dd'T'HH:mm:ss'.'fffzzz")
        result.file_url = img["file"]["url"].getStr()
        result.preview_url = img["preview"]["url"].getStr()
        if result.file_url != "":
          result.filename = result.file_url.rsplit({'/'}, maxsplit=1)[1]
        if img.hasKey("sources"):
          var s = img["sources"].getElems()
          if s.len > 0:
            result.source = some img["sources"].getElems()[0].getStr()
        result.hash = img["file"]["md5"].getStr()
        result.height = img["file"]["height"].getInt()
        result.width = img["file"]["width"].getInt()
        result.rating = img["rating"].getStr()
        result.has_comments = img["comment_count"].getInt() > 0
        result.has_notes = img["has_notes"].getBool()
        result.has_children = img["relationships"]["has_children"].getBool()
        var tags = img["tags"]
        for t in tags["general"].getElems():
          result.tags &= t.getStr()
        if tags.hasKey("artist"):
          for t in tags["artist"].getElems():
            result.tags &= t.getStr()
        if tags.hasKey("copyright"):
          for t in tags["copyright"].getElems():
            result.tags &= t.getStr()
        if tags.hasKey("character"):
          for t in tags["character"].getElems():
            result.tags &= t.getStr()
        if tags.hasKey("species"):
          for t in tags["species"].getElems():
            result.tags &= t.getStr()
        if tags.hasKey("meta"):
          for t in tags["meta"].getElems():
            result.tags &= t.getStr()
        result.change = parseTime(img["updated_at"].getStr(), "yyyy-MM-dd'T'HH:mm:ss'.'fffzzz", utc())
        result.locked = img["flags"]["status_locked"].getBool()
        result.score = img["score"]["total"].getInt()
      of Sankaku:
        result.id = img["id"].getStr()
        if img.hasKey("author") and img["author"].kind == JObject:
          if img["author"].hasKey("id"):
            result.creator_id = some img["author"]["id"].getStr()
        if img.hasKey("parent_id") and img["parent_id"].kind != JNull:
          result.parent_id = img["parent_id"].getStr()
        if img.hasKey("created_at") and img["created_at"].kind == JObject:
          let ts = img["created_at"]["s"].getInt()
          result.created_at = some parse($ts.fromUnix(), "yyyy-MM-dd'T'HH:mm:sszzz")
          result.change = ts.fromUnix()
        if img.hasKey("file_url") and img["file_url"].kind != JNull:
          result.file_url = img["file_url"].getStr()
          if result.file_url != "":
            var path = result.file_url.rsplit({'/'}, maxsplit=1)[1]
            if path.contains("?"):
              path = path.split("?")[0]
            result.filename = path
        if img.hasKey("preview_url") and img["preview_url"].kind != JNull:
          result.preview_url = img["preview_url"].getStr()
        if img.hasKey("source") and img["source"].kind != JNull:
          let src = img["source"].getStr()
          if src != "" and src != "removed":
            result.source = some src
        if img.hasKey("md5") and img["md5"].kind != JNull:
          result.hash = img["md5"].getStr()
        result.height = img["height"].getInt()
        result.width = img["width"].getInt()
        if img.hasKey("rating"):
          result.rating = img["rating"].getStr()
        result.has_comments = img["has_comments"].getBool(false)
        result.has_notes = img["has_notes"].getBool(false)
        result.has_children = img["has_children"].getBool(false)
        if img.hasKey("tag_names"):
          for t in img["tag_names"].getElems():
            let tag = t.getStr()
            if tag != "":
              result.tags &= tag
        if result.tags.len == 0 and img.hasKey("tags"):
          for t in img["tags"].getElems():
            if t.kind == JString:
              let tag = t.getStr()
              if tag != "":
                result.tags &= tag
            elif t.kind == JObject and t.hasKey("name"):
              let tag = t["name"].getStr()
              if tag != "":
                result.tags &= tag
        result.status = img["status"].getStr("active")
        result.score = img["total_score"].getInt(0)
