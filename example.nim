import std/asyncdispatch
import src/Nimbooru

var b = initBooruClient(Gelbooru)
echo waitFor b.asyncGetPost("8967426")
