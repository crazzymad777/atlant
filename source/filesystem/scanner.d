module atlant.filesystem.scanner;

import atlant.utils.configuration;
import atlant.filesystem.tree;

import core.sys.posix.dirent;
extern(C) int dirfd(DIR *dirp);

struct Scanner
{
    private Configuration* conf;
    this(Configuration* conf, char* directory)
    {
        this.conf = conf;
        this.directory = directory;
        this.root = TreeNode.of(TreeNode.Type.directory, cast(char*) "".ptr, null);
    }

    ~this()
    {
        if (!detached)
        {
            root.drop();
        }
    }

    void detach()
    {
        detached = true;
    }

    bool detached = false;
    char* directory;
    TreeNode* root;

    int scan(char* name = null, TreeNode* current = null)
    {
        import core.stdc.string;
        import core.stdc.stdio;

        if (name is null)
        {
            import core.sys.posix.unistd;
            name = this.directory;
            current = root;
            chdir(name);
        }

        DIR* dirptr = opendir(".".ptr);

        if (!dirptr)
        {
            perror(directory);
            return -1;
        }

        traverse(dirptr, current);
        closedir(dirptr);
        return 0;
    }

    int countChilds(TreeNode* parent)
    {
        import core.stdc.stdio;
        TreeNode* sibling = parent.firstChild;
        int number = parent.directChildsNumber;
        while (sibling !is null)
        {
            if (sibling.type == TreeNode.Type.directory)
            {
                if (sibling.childsNumber == -1)
                {
                    number += countChilds(sibling);
                }
                else
                {
                    number += sibling.childsNumber;
                }
            }
            sibling = sibling.nextSibling;
        }
        parent.childsNumber = number;
        return number;
    }

    void showNode(TreeNode* parent)
    {
        import core.stdc.stdio;
        TreeNode* sibling = parent.firstChild;
        while (sibling !is null)
        {
            if (sibling.type == TreeNode.Type.file)
            {
                printf("f %s\n", sibling.uriPath.data);
            }
            if (sibling.type == TreeNode.Type.directory)
            {
                printf("d %s\n", sibling.uriPath.data);
                showNode(sibling);
            }
            if (sibling.type == TreeNode.Type.link)
            {
                printf("l %s\n", sibling.uriPath.data);
            }
            sibling = sibling.nextSibling;
        }
    }

    void show()
    {
        import core.stdc.stdio;
        showNode(root);
        printf("total=%d\n", root.childsNumber);
    }

    void traverse(DIR* dirptr, TreeNode* node)
    {
        import core.sys.posix.unistd;
        import core.stdc.string;
        import core.stdc.stdio;
        dirent* entry;

        TreeNode* prev = null;
        while ((entry = readdir(dirptr)) !is null)
        {
            TreeNode* current = null;
            bool index = false;

            if (strcmp("..", &entry.d_name[0]) == 0)
            {
                continue;
            }

            if (strcmp(".", &entry.d_name[0]) == 0)
            {
                continue;
            }

            auto x = conf.listOfIndices.front();
            int indexWeight = 1;
            while (x !is null)
            {
                if (strcmp(x.value, &entry.d_name[0]) == 0)
                {
                    index = true;
                    break;
                }
                x = x.next;
                indexWeight++;
            }

            if (entry.d_type == DT_UNKNOWN)
            {
                import atlant.utils.stat;
                // WE should determine file type
                stat_t s;
                if (lstat(&entry.d_name[0], &s) == 0)
                {
                    if (S_ISDIR(s.st_mode))
                    {
                        entry.d_type = DT_DIR;
                    }
                    else if (S_ISREG(s.st_mode))
                    {
                        entry.d_type = DT_REG;
                    }
                    else if (S_ISLNK(s.st_mode))
                    {
                        entry.d_type = DT_LNK;
                    }
                }
            }

            if (entry.d_type == DT_LNK)
            {
                import atlant.utils.stat;
                //printf("l %s\n", &entry.d_name[0]);
                stat_t s;
                if (stat(&entry.d_name[0], &s) == 0)
                {
                    if (S_ISDIR(s.st_mode))
                    {
                        // printf("ld %s\n", &entry.d_name[0]);

                        // How to solve recursion?
                        // entry.d_type = DT_DIR;
                        current = TreeNode.of(TreeNode.Type.link, &entry.d_name[0], node);
                    }
                    else
                    {
                        // printf("l_ %s\n", &entry.d_name[0]);
                        current = TreeNode.of(TreeNode.Type.link, &entry.d_name[0], node);
                    }
                }
            }

            if (entry.d_type == DT_REG)
            {
                // printf("f %s\n", &entry.d_name[0]);
                current = TreeNode.of(TreeNode.Type.file, &entry.d_name[0], node);
                if (index)
                {
                    if (node.indexWeight == 0 || indexWeight < node.indexWeight)
                    {
                        node.index = current;
                        node.indexWeight = indexWeight;
                    }
                }
            }

            if (entry.d_type == DT_DIR)
            {
                // printf("d %s\n", &entry.d_name[0]);
                current = TreeNode.of(TreeNode.Type.directory, &entry.d_name[0], node);
                int fd = dirfd(dirptr);
                chdir(&entry.d_name[0]);
                scan(cast(char*) ".".ptr, current);
                fchdir(fd);
            }

            if (current !is null)
            {
                node.directChildsNumber++;
                if (prev is null)
                {
                    node.firstChild = current;
                }
                else
                {
                    prev.nextSibling = current;
                }
                prev = current;
            }
        }

        countChilds(node);
    }
}
