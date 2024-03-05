# This is just an example to get you started. You may wish to put all of your
# tests into a single file, or separate them into multiple `test1`, `test2`
# etc. files (better names are recommended, just make sure the name starts with
# the letter 't').
#
# To run these tests, simply execute `nimble test`.

import unittest
import std/asyncdispatch
import std/options

import Nimbooru

test "sync":
  var b = initBooruClient(Gelbooru)
  check b.searchPosts().len == 100
  b.site = some Safebooru
  check b.searchPosts().len == 100
  b.site = some Danbooru
  check b.searchPosts().len == 100
  b.site = some Yandere
  check b.searchPosts().len == 100
  b.site = some Konachan
  check b.searchPosts().len == 100
  b.site = some E621
  check b.searchPosts().len == 100

test "async":
  var b = initBooruClient(Gelbooru)
  check (waitFor b.asyncSearchPosts()).len == 100
  b.site = some Safebooru
  check (waitFor b.asyncSearchPosts()).len == 100
  b.site = some Danbooru
  check (waitFor b.asyncSearchPosts()).len == 100
  b.site = some Yandere
  check (waitFor b.asyncSearchPosts()).len == 100
  b.site = some Konachan
  check (waitFor b.asyncSearchPosts()).len == 100
  b.site = some E621
  check (waitFor b.asyncSearchPosts()).len == 100
