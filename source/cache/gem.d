module atlant.cache.gem;

import atlant.filesystem.tree;
import atlant.utils.string;

// Gem stores mime type and content
struct Gem
{
    TreeNode* node;
    String mime;
    int hash;
    bool uniqueHash; // unique hash in the Bucket
}
