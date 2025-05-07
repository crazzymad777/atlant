module atlant.http.chunk;

import core.sys.posix.sys.types;

struct Chunk
{
    ssize_t length;
    byte[4096] buffer;
}
