module atlant.filesystem.tree;

import atlant.utils.string;

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
        String.cStringDup(&node.filename, filename);
        node.directChildsNumber = 0;
        node.childsNumber = -1;

        if (parent is null)
        {
            String.cStringAlloc(&node.uriPath, 0);
            node.uriPath.data[0] = '\0';
        }
        else
        {
            int slash = 0;
            if (parent.uriPath.length > 0)
            {
                slash = 1;
            }

            String.cStringAlloc(&node.uriPath, parent.uriPath.length + slash + node.filename.length);

            if (slash > 0)
            {
                memcpy(node.uriPath.data, parent.uriPath.data, parent.uriPath.length);
                node.uriPath.data[parent.uriPath.length] ='/';
            }

            memcpy(&node.uriPath.data[parent.uriPath.length + slash], node.filename.data, node.filename.length);
            node.uriPath.data[node.uriPath.length] = '\0';
        }

        return node;
    }

    Type type;
    String filename;
    String uriPath;

    TreeNode* firstChild;
    TreeNode* nextSibling;

    int directChildsNumber;
    int childsNumber;

    void drop()
    {
        import core.stdc.stdlib;
        if (type == Type.directory)
        {
            if (firstChild !is null)
            {
                firstChild.drop();
            }
        }

        if (nextSibling !is null)
        {
            nextSibling.drop();
        }
        filename.drop();
        uriPath.drop();
        free(&this);
    }
}
