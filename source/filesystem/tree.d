module atlant.filesystem.tree;

struct TreeNode
{
    enum Type
    {
        directory,
        file,
        link
    }

    static TreeNode* of(Type type, char* filename, TreeNode* parent)
    {
        import core.stdc.stdlib;
        import core.stdc.string;
        TreeNode* node = cast(TreeNode*) malloc(TreeNode.sizeof);
        assert(node !is null);
        node.firstChild = null;
        node.nextSibling = null;
        node.type = type;
        node.filenameLength = strlen(filename);
        node.filename = strdup(filename);

        if (parent is null)
        {
            node.uriPathLength = 0;
            node.uriPath = cast(char*) malloc(char.sizeof * 1);
            node.uriPath[0] = '\0';
        }
        else
        {
            int slash = 0;
            if (parent.uriPathLength > 0)
            {
                slash = 1;
            }

            node.uriPathLength = parent.uriPathLength + slash + node.filenameLength;
            node.uriPath = cast(char*) malloc(char.sizeof * (node.uriPathLength + 1));

            if (slash > 0)
            {
                memcpy(node.uriPath, parent.uriPath, parent.uriPathLength);
                node.uriPath[parent.uriPathLength] ='/';
            }

            memcpy(&node.uriPath[parent.uriPathLength + slash], node.filename, node.filenameLength);
            node.uriPath[node.uriPathLength] = '\0';
        }

        return node;
    }

    Type type;
    ulong filenameLength;
    char* filename;

    ulong uriPathLength;
    char* uriPath;

    TreeNode* firstChild;
    TreeNode* nextSibling;
}
