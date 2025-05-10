module atlant.cache.gem;

import atlant.filesystem.tree;
import atlant.utils.string;

// Gem stores mime type and content
struct Gem
{
    static Gem* of(TreeNode* node)
    {
        import atlant.filesystem.utils;
        import core.stdc.stdlib;
        Gem* gem = cast(Gem*) malloc(Gem.sizeof);
        assert(gem !is null);
        gem.node = node;
        gem.uniqueHash = true;
        gem.hash = node.uriPath.hashOf();

        gem.mime = String();
        gem.mime.type = String.Type.cannonic;

        getMime(&gem.mime, node.uriPath.data);
        gem.mime.seal();
        readFile(&gem.node.uriPath, &gem.data, &gem.length);
        return gem;
    }

    TreeNode* node;
    String mime;
    int hash;
    bool uniqueHash; // unique hash in the Bucket
    char* data;
    size_t length;

    void drop()
    {
        import core.stdc.stdlib;
        mime.drop();
        free(&this);
    }

    void show()
    {
        import core.stdc.stdio;
        printf("%s : ", node.uriPath.data);
        mime.reset();
        while (mime.hasNext())
        {
            putchar(mime.take());
            mime.next();
        }
        printf("\n");
    }
}
