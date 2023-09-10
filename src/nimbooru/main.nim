import std/options
import std/asyncdispatch
import std/json

import utils
import funcs
import containers

## Initialize BooruClient to use one of the supported boorus
proc initBooruClient*(site: Boorus, apiKey = none string, userId = none string): BooruClient =
  result.apiKey = apiKey
  result.userdId = userId
  result.site = some site

## Initialize BooruClient to use a custom endpoint, use site argument to pick an API version
proc initBooruClient*(site_url: string, site: Boorus, apiKey = none string, userId = none string): BooruClient =
  result.apiKey = apiKey
  result.userdId = userId
  result.site = some site
  result.customApi = some site_url

## Get a single post from a post id
proc asyncGetPost*(client: BooruClient, id: string): Future[BooruImage] {.async.} = 
  var base_url = prepareEndpoint(client)
  base_url = prepareGetPost(client, id, base_url)
  var cont = await client.asyncGetUrl(base_url)
  result = initBooruImage(client, client.processPost(cont))

## Get a sequence of posts optionally filtered by tags
proc asyncSearchPosts*(client: BooruClient, limit = 100, page = 0, tags = none seq[string], exclude_tags = none seq[string]): Future[seq[BooruImage]] {.async.} =
  var base_url = prepareEndpoint(client)
  base_url = prepareSearchPosts(client, limit, page, tags, exclude_tags, base_url)
  var cont = await client.asyncGetUrl(base_url)
  result = client.processSearchPosts(cont)
