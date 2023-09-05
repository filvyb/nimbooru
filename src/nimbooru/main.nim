import std/options
import std/asyncdispatch
import std/json

import utils
import funcs
import containers

proc initBooruClient*(site: Boorus, apiKey = none string, userId = none string): BooruClient =
  result.apiKey = apiKey
  result.userdId = userId
  result.site = some site

proc initBooruClient*(site_url: string, apiKey = none string, userId = none string): BooruClient =
  result.apiKey = apiKey
  result.userdId = userId
  result.customApi = some site_url

proc asyncGetPost*(client: BooruClient, id: string): Future[BooruImage] {.async.} = 
  var base_url = prepareEndpoint(client)
  base_url = prepareGetPost(client, id, base_url)
  var cont = await asyncGetUrl(base_url)
  result = initBooruImage(client, client.processPost(cont))
