module atlant.filesystem.tree;

struct TreeNode
{
    enum Type
    {
        directory,
        file,
        link
    }

    static TreeNode* of(Type type, char* filename)
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
        return node;
    }

    Type type;
    ulong filenameLength;
    char* filename;

    TreeNode* firstChild;
    TreeNode* nextSibling;
}
