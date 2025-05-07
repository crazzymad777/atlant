module atlant.filesystem.scanner;

struct Scanner
{
    import core.sys.posix.dirent;
    this(char* directory)
    {
        this.directory = directory;
    }
    char* directory;

    void scan()
    {
        import core.stdc.stdio;
        DIR* dirptr = opendir(directory);

        if (!dirptr)
        {
            perror(directory);
            return;
        }

        traverse(dirptr);
        closedir(dirptr);
    }

    void traverse(DIR* dirptr)
    {
        import core.stdc.string;
        import core.stdc.stdio;
        dirent* entry;
        while ((entry = readdir(dirptr)) !is null)
        {
            if (strcmp("..", &entry.d_name[0]) == 0)
            {
                continue;
            }

            if (strcmp(".", &entry.d_name[0]) == 0)
            {
                continue;
            }

            if (entry.d_type == DT_UNKNOWN)
            {
                // WE should determine file type
            }

            if (entry.d_type == DT_REG)
            {
                printf("f %s\n", &entry.d_name[0]);
            }

            if (entry.d_type == DT_DIR)
            {
                printf("d %s\n", &entry.d_name[0]);
            }

            if (entry.d_type == DT_LNK)
            {
                printf("l %s\n", &entry.d_name[0]);
            }
        }
    }
}
