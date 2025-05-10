module atlant.cache.gem;

import atlant.utils.string;

// Gem stores mime type and content
struct Gem
{
    String mime;
    String path;
    int hash;
    bool uniqueHash;
}
