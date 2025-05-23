module atlant.cache.gem;

import atlant.filesystem.tree;
import atlant.utils.string;

// Gem stores mime type and content
struct Gem
{
    static Gem* of(TreeNode* node, TreeNode* link)
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

        getMime(&gem.mime, link.uriPath.data);
        gem.mime.seal();
        int status = readFile(&link.uriPath, &gem.data, &gem.length);

        if (status == 0)
        {
            return gem;
        }

        gem.drop();
        return null;
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
