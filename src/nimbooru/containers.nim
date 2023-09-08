import std/times
import std/options
import std/json
import std/strutils

import utils


type
  BooruClient* = object
    apiKey*: Option[string]
    userdId*: Option[string]
    site*: Option[Boorus]
    customApi*: Option[string]
  BooruImage* = object
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
        result.has_comments = img["has_comments"].getBool()
        result.has_notes = img["has_notes"].getBool()
        result.has_children = img["has_children"].getBool()
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
